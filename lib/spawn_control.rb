require "pp"
require "set"
require "hash_tree"
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

class SpawnControl

  def self.start(configuration, &block)
    self.new(configuration).start(&block)
  end

  attr_reader :commands, :configuration, :completions

  def initialize(configuration)
    @configuration = configuration
    commands = HashTree[@configuration[:commands]]

    @completions = Set.new

    @commands = {}
    commands.each_path do |path, value|
      key = path.join(".")
      @completions += path
      @completions << key
      @commands[key] = value
    end

    @threads = []
    @pid_tracker = {}
    @command_tracker = {}
  end

  def start(&block)
    @running = []
    @command_width = commands.keys.sort_by {|k| k.size }.last.size
    @commands.each do |name, command|
      spawn(name, command)
    end

    at_exit { stop }

    Thread.new do
      # pid of -1 means to wait for any child process
      pid, status = Process.wait2(-1)
      # when we stop processes intentionally, we must remove the pid
      # from the tracker
      if name = @pid_tracker.delete(pid)
        @command_tracker.delete(name)
        command = @commands[name]
        if status.exitstatus != 0
          puts "Process '#{name}' (pid #{pid}) exited with code #{status}:"
          puts "Shutting down all processes."
          exit(status.exitstatus)
        end
      end
    end

    # Command threads add themselves to the array when they believe
    # their commands are ready.
    until @threads.size == @commands.size
      sleep 0.1
    end

    puts format_line("SpawnControl", "All commands are running. ")
    if block
      yield
      stop
    end

  end

  def spawn(name, command)
    return Thread.new do
      pid, stdin, stdout, stderr = open4(command)
      puts format_line("SpawnControl", "Starting (#{pid}): #{command}")
      @pid_tracker[pid] = name
      @command_tracker[name] = pid

      Thread.new do
        while line = stderr.gets
          $stderr.puts "(#{name}) #{line}"
        end
      end

      # First line written to STDOUT is interpreted as the service
      # signalling that it is ready.
      line = stdout.gets
      STDOUT.puts format_line(name, line)
      @threads << Thread.current

      while line = stdout.gets
        STDOUT.puts format_line(name, line)
      end
    end
  end

  def stop
    if @pid_tracker.size != 0
      command = "kill #{@pid_tracker.keys.join(' ')}"
      system command
      @pid_tracker.clear
      @command_tracker.clear
    end
  end

  def format_line(identifier, line)
    if identifier == @last_identifier
      "%-#{@command_width}s - %s" % [nil, line]
    else
      puts
      @last_identifier = identifier
      "%-#{@command_width}s - %s" % [identifier, line]
    end
  end

  def stop_command(name)
    if command = @commands[name]
      if pid = @command_tracker[name]
        @pid_tracker.delete(pid)
        @command_tracker.delete(name)
        puts "Found a command named #{name} running with pid #{pid}"
        system "kill -s INT #{pid}"
        puts "I just killed it.  Are you not entertained?"
      end
    else
      puts "No such command registered: #{name}"
    end
  end

end

