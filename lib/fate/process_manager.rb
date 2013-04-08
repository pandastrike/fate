require "pp"

class Fate

  # A process management tool, concerned primarily with spawning child
  # processes, tracking them by name, and handling unexpected exits and signals.
  class ProcessManager

    attr_reader :logger, :output_handlers, :service
    def initialize(service, options={})
      @directory = options[:directory]
      @mutex = Mutex.new
      @service = service
      @output_handlers = @service.output_handlers
      @logger = @service.logger["Fate Manager"]

      @threads = {}
      @commands_by_name = {}
      @names_by_pid = {}
      @pids_by_name = {}
      at_exit do
        stop_group(running)
      end
    end

    def run(command_strings=[])
      if command_strings.empty?
        run(@service.commands.keys)
      else
        commands = @service.resolve(command_strings)
        # don't need to start processes that are already running
        noop = commands & running
        to_start = commands - noop
        to_stop = running - commands

        stop_group(to_stop)
        start_group(to_start)
      end
    end

    def start(command_strings=[])
      if command_strings.empty?
        start_group(@service.commands.keys)
      else
        commands = @service.resolve(command_strings)
        start_group(commands)
      end
    end

    def stop(command_strings=[])
      if command_strings.empty?
        stop_group(running)
      else
        names = @service.resolve(command_strings)
        stop_group(names)
      end
    end

    def start_group(names)
      ordered = @service.start_order(names)
      ordered.each do |name|
        command = service.commands[name]
        @commands_by_name[name] = command
        start_command(name, command) unless @down_in_flames
      end
      until names.all? { |name| @threads[name] }
        return false if @down_in_flames
        sleep 0.1
      end
      return true
    end

    def stop_group(names)
      @mutex.synchronize do
        ordered = @service.stop_order(names)
        ordered.each do |name|
          term(name)
        end
      end
    end

    def start_command(name, command)
      if pid = @pids_by_name[name]
        logger.warn "'#{name}' is already running with pid #{pid}"
      else
        spawn(name, command)
      end
    end

    def term(name)
      if pid = @pids_by_name[name]
        @names_by_pid.delete(pid)
        @pids_by_name.delete(name)
        @threads.delete(name)
        system "kill -s TERM #{pid}"
        logger.info "Sent a kill signal to '#{name}' running at #{pid}"
        begin
          # Signal 0 checks for the process, but sends no signal.
          Process.kill(0, pid)
        rescue
          # TODO: limit number of retries, possibly issue kill -9?
          sleep 0.01
          retry
        end
      else
        logger.error "Could not find pid for '#{name}'"
      end
    end

    def spawn(name, command)
      return Thread.new do

        pipe = nil
        pid = nil
        @mutex.synchronize do
          unless @down_in_flames
            if @directory
              Dir.chdir @directory do
                pipe = IO.popen(command, "r", :err => :out)
              end
            else
              pipe = IO.popen(command, "r", :err => :out)
            end
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
      names = []
      @names_by_pid.each do |pid, name|
        begin
          # Signal 0 checks for the process, but sends no signal.
          Process.kill(0, pid)
          names << name
        rescue
        end
      end
      names.sort
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

      stop_group(running)
      exit(1)
    end



  end
end
