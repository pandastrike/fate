require "pp"
# Cross-VM compatibility
# thanks to http://ku1ik.com/2010/09/18/open3-and-the-pid-of-the-spawn.html
# TODO: consider using systemu: https://github.com/ahoward/systemu/
if IO.respond_to?(:popen4)
  def open4(*args)
    IO.popen4(*args)
  end
else
  require 'open4'
end

class Fate
  class Manager
    include Formatter

    def initialize(options)
      @log = options[:log]
      @command_width = options[:command_width]
      @threads = {}
      @commands_by_name = {}
      @names_by_pid = {}
      @pids_by_name = {}
      at_exit { stop }
    end


    def start_group(hash, blocking=:noblock)
      hash.each do |name, command|
        @commands_by_name[name] = command
        start_command(name, command)
      end

      if blocking == :block
        until @threads.size == hash.size
          sleep 0.1
        end
      end
    end

    def start_command(name, command)
      if pid = @pids_by_name[name]
        puts "#{name} is already running with pid #{pid}"
      else
        spawn(name, command)
      end
    end

    def spawn(name, command)
      # TODO: check to see if command is already running
      return Thread.new do
        pid, stdin, stdout, stderr = open4(command)
        puts colorize("yellow", format_line("Fate", "Starting (#{pid}): #{name}"))
        @names_by_pid[pid] = name
        @pids_by_name[name] = pid

        Thread.new do
          while line = stderr.gets
            STDERR.puts "(#{name}) #{line}"
          end
        end

        # First line written to STDOUT is interpreted as the service
        # signalling that it is ready.
        line = stdout.gets
        puts colorize("yellow", format_line("Fate", "#{name} is running."))
        @log.puts format_line(name, line)
        @threads[name] = Thread.current
        #@threads << Thread.current

        while line = stdout.gets
          @log.puts format_line(name, line)
        end
        status = Process.wait(pid)
        handle_child_termination(pid, status)
      end
    end

    def stop_command(name)
      targets = []
      if command = @commands_by_name[name]
        targets << name
      else
        @commands_by_name.each do |cname, _command|
          if cname.split(".").first == name
            targets << cname
          end
        end
      end

      if targets.empty?
        puts "No such command running: #{name}"
      end

      targets.each do |name|
        if pid = @pids_by_name[name]
          @names_by_pid.delete(pid)
          @pids_by_name.delete(name)
          @threads.delete(name)
          system "kill -s INT #{pid}"
          puts colorize "yellow",
            format_line("Fate", "Sent a kill signal to #{name} running at #{pid}")
        end
      end

    end

    def stop
      if @names_by_pid.size != 0
        pids = @names_by_pid.keys.join(" ")
        @names_by_pid.clear
        @pids_by_name.clear
        @threads.clear
        command = "kill #{pids}"
        system command
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
        if (@mode != :production) && status.exitstatus != 0
          down_in_flames(name, pid, status)
        else
          # Probably should notify somebody somehow
        end
      end
    end

    def down_in_flames(name, pid, status)
      puts "Process '#{name}' (pid #{pid}) exited with code #{status}:"
      puts "Shutting down all processes."
      exit(status.exitstatus)
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
