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
      @name_commands = {}
      @pid_names = {}
      @name_pids = {}
      wait
      at_exit { stop }
    end

    def wait
      Thread.new do
        begin
          pid, status = Process.wait2(-1)
          handle_child_termination(pid, status)
        rescue Errno::ECHILD
          sleep 1
          retry
        end
        #message = format_line("Fate", "thread with Process.wait2")
        #puts colorize("red", message)
        loop do
          # pid of -1 means to wait for any child process
          pid, status = Process.wait2(-1)
          pp [pid, status]
          handle_child_termination(pid, status)
        end
      end
    end

    def handle_child_termination(pid, status)
      if name = @pid_names.delete(pid)
        @name_pids.delete(name)
        command = @name_commands[name]
        if (@mode != :production) && status.exitstatus != 0
          down_in_flames(name, pid, status)
        end
      end
    end

    def down_in_flames(name, pid, status)
      puts "Process '#{name}' (pid #{pid}) exited with code #{status}:"
      puts "Shutting down all processes."
      exit(status.exitstatus)
    end

    def spawn_commands(hash)
      hash.each do |name, command|
        @name_commands[name] = command
        start_command(name, command)
      end

      # Command threads add themselves to the array when they believe
      # their commands are ready.
      until @threads.size == hash.size
        sleep 0.1
      end

      message = format_line("Fate", "All commands are running. ")
      puts colorize("green", message)
    end

    def start_command(name, command)
      if pid = @name_pids[name]
        puts "#{name} is already running with pid #{pid}"
      else
        spawn(name, command)
        until @threads[name]
          sleep 0.1
        end
        puts colorize("yellow", format_line("Fate", "#{name} is running."))
      end
    end

    def spawn(name, command)
      # TODO: check to see if command is already running
      return Thread.new do
        pid, stdin, stdout, stderr = open4(command)
        puts colorize("yellow", format_line("Fate", "Starting (#{pid}): #{name}"))
        @pid_names[pid] = name
        @name_pids[name] = pid

        Thread.new do
          while line = stderr.gets
            STDERR.puts "(#{name}) #{line}"
          end
        end

        # First line written to STDOUT is interpreted as the service
        # signalling that it is ready.
        line = stdout.gets
        @log.puts format_line(name, line)
        @threads[name] = Thread.current
        #@threads << Thread.current

        while line = stdout.gets
          @log.puts format_line(name, line)
        end
      end
    end

    def stop
      if @pid_names.size != 0
        pids = @pid_names.keys.join(" ")
        @pid_names.clear
        @name_pids.clear
        @threads.clear
        command = "kill #{pids}"
        system command
      end
    end

    def stop_command(name)
      targets = []
      if command = @name_commands[name]
        targets << name
      else
        @name_commands.each do |cname, _command|
          if cname.split(".").first == name
            targets << cname
          end
        end
      end

      if targets.empty?
        puts "No such command running: #{name}"
      end

      targets.each do |name|
        if pid = @name_pids[name]
          @pid_names.delete(pid)
          @name_pids.delete(name)
          @threads.delete(name)
          system "kill -s INT #{pid}"
          puts colorize("yellow", format_line("Fate", "Sent a kill signal to #{name} running at #{pid}"))
        end
      end

    end

    def restart
      stop
      start
    end

    def restart_command(name)
      command = @name_commands[name]
      stop_command(name)
      start_command(name, command)
    end

    # list currently running commands
    def running
      names = @name_pids.map {|name, command| name }.sort
    end


  end
end
