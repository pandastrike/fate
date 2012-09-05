require "pp"
# Cross-VM compatibility
# thanks to http://ku1ik.com/2010/09/18/open3-and-the-pid-of-the-spawn.html
if IO.respond_to?(:popen4)
  def open4(*args)
    IO.popen4(*args)
  end
else
  require 'open4'
end

class Fate
  class Manager

    attr_reader :logger
    def initialize(service, options={})
      @service = service
      @command_width = @service.longest_name
      @logger = @service.logger("Fate Manager")

      @threads = {}
      @commands_by_name = {}
      @names_by_pid = {}
      @pids_by_name = {}
      at_exit { stop }
    end

    def log(*args, &block)
      @logger.log(*args, &block)
    end

    def stop
      @names_by_pid.each do |pid, name|
        kill(name)
      end
    end

    def start_group(hash)
      hash.each do |name, command|
        @commands_by_name[name] = command
        start_command(name, command)
      end

      until @threads.size == hash.size
        sleep 0.1
      end
    end

    def start_command(name, command)
      if pid = @pids_by_name[name]
        logger.error "'#{name}' is already running with pid #{pid}"
      else
        spawn(name, command)
      end
    end

    def kill(name)
      if pid = @pids_by_name[name]
        @names_by_pid.delete(pid)
        @pids_by_name.delete(name)
        @threads.delete(name)
        system "kill -s INT #{pid}"
        logger.info "Sent a kill signal to '#{name}' running at #{pid}"
      else
        logger.error "Could not find pid for '#{name}'"
      end
    end

    def stop_command(name)
      kill(name)
    end

    def spawn(name, command)
      # TODO: check to see if command is already running
      return Thread.new do
        process_logger = @service.logger(name)

        pid, stdin, stdout, stderr = open4(command)
        logger.info "Starting (#{pid}): #{name}"
        @names_by_pid[pid] = name
        @pids_by_name[name] = pid

        Thread.new do
          while line = stderr.gets
            # TODO: test me
            process_logger.error(line)
          end
        end

        # First line written to STDOUT is interpreted as the service
        # signalling that it is ready.
        line = stdout.gets
        logger.info "#{name} is running."
        process_logger.log(line)
        @threads[name] = Thread.current

        while line = stdout.gets
          process_logger.log(line)
        end
        pid, status = Process.wait2(pid)
        handle_child_termination(pid, status)
      end
    end

    # list currently running commands
    def running
      names = @pids_by_name.map {|name, command| name }.sort
    end

    private

    def handle_child_termination(pid, status)
      if name = @names_by_pid.delete(pid)
        @pids_by_name.delete(name)
        # TODO: CLI and instantiation flags for @mode
        if (@mode != :production) && status != 0
          down_in_flames(name, pid, status)
        else
          # Probably should notify somebody somehow
        end
      end
    end

    def down_in_flames(name, pid, status)
      if status.exitstatus
        logger.error "Process '#{name}' (pid #{pid}) exited with code #{status.exitstatus}."
      else
        logger.info "Process '#{name}' (pid #{pid}) was sent signal #{status.termsig}."
      end
      logger.info "Shutting down all processes."
      exit(1)
    end


    # ad hoc shell out, with rescuing because of some apparent bugs
    # in MRI 1.8.7's ability to cope with unusual exit codes.
    def system(command)
      begin
        Kernel.system command
      rescue => error
        puts "Exception raised when executing '#{command}': #{error.inspect}"
      end
    end



  end
end
