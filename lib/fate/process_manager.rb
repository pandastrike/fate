require "pp"

class Fate

  # A process management tool, concerned primarily with spawning child
  # processes, tracking them by name, and handling unexpected exits and signals.
  class ProcessManager

    attr_reader :logger, :output_handlers
    def initialize(service)
      @mutex = Mutex.new
      @service = service
      @output_handlers = @service.output_handlers
      @logger = @service.logger["Fate Manager"]

      @threads = {}
      @commands_by_name = {}
      @names_by_pid = {}
      @pids_by_name = {}
      at_exit do
        stop
      end
    end

    def stop
      @mutex.synchronize do
        @names_by_pid.each do |pid, name|
          kill(name)
        end
      end
      exit(1)
    end

    def start_group(hash)
      hash.each do |name, command|
        @commands_by_name[name] = command
        start_command(name, command) unless @down_in_flames
      end

      until @threads.size == hash.size
        return false if @down_in_flames
        sleep 0.1
      end
      return true
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
        system "kill -s TERM #{pid}"
        logger.info "Sent a kill signal to '#{name}' running at #{pid}"
      else
        logger.error "Could not find pid for '#{name}'"
      end
    end

    def stop_command(name)
      kill(name)
    end

    def spawn(name, command)
      return Thread.new do

        pipe = nil
        pid = nil
        @mutex.synchronize do
          unless @down_in_flames
            pipe = IO.popen(command, "r", :err => :out)
            pid = pipe.pid
            logger.info "Starting '#{name}' (pid #{pid})"

            @names_by_pid[pid] = name
            @pids_by_name[name] = pid
          end
        end

        unless @down_in_flames
          # Obtain an IO-ish object
          handler = output_handlers[name]
          # First line written to STDOUT is assumed to be the service
          # signalling that it is ready.
          line = pipe.gets
          @mutex.synchronize do
            unless @down_in_flames
              logger.info "#{name} is running."
              handler.write(line)
            end
          end
          @threads[name] = Thread.current

          copy_stream(pipe, handler)
          pid, status = Process.wait2(pid)
          handle_child_termination(pid, status)
        end

      end
    end

    # Replacement for IO.copy_stream, which is a native function.  We've been
    # seeing segfaults when using it for lots of data.
    def copy_stream(src, dest)
      begin
        while s = src.readpartial(1024)
          dest.write(s)
        end
      rescue EOFError
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
        down_in_flames(name, pid, status)
      end
    end

    def down_in_flames(name, pid, status)
      @down_in_flames = true
      if status.exitstatus
        logger.error "Process '#{name}' (pid #{pid}) exited with code #{status.exitstatus}."
      else
        logger.info "Process '#{name}' (pid #{pid}) was sent signal #{status.termsig}."
      end
      logger.info "Shutting down all processes."

      stop
    end


    # ad hoc shell out, with rescuing because of some apparent bugs
    # in MRI 1.8.7's ability to cope with unusual exit codes.
    def system(command)
      #begin
        Kernel.system command
      #rescue => error
        #puts "Exception raised when executing '#{command}': #{error.inspect}"
      #end
    end



  end
end
