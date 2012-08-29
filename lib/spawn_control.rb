require "set"

require "term/ansicolor"

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

  def initialize(configuration, options={})
    @configuration = configuration
    @options = options
    if logfile = options[:service_log]
      @log = File.new(logfile, "a")
    else
      @log = STDOUT
    end
    commands = HashTree[@configuration[:commands]]

    @completions = Set.new

    @commands = {}
    commands.each_path do |path, value|
      key = path.join(".")
      @completions += path
      @completions << key
      @commands[key] = value
    end

    @threads = {}
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

    message = format_line("SpawnControl", "All commands are running. ")
    puts colorize("green", message)

    if block
      yield(self)
      stop
    end

  end

  def spawn(name, command)
    return Thread.new do
      pid, stdin, stdout, stderr = open4(command)
      puts colorize("yellow", format_line("SpawnControl", "Starting (#{pid}): #{command}"))
      @pid_tracker[pid] = name
      @command_tracker[name] = pid

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
    if @pid_tracker.size != 0
      command = "kill #{@pid_tracker.keys.join(' ')}"
      system command
      @pid_tracker.clear
      @command_tracker.clear
      @threads.clear
    end
  end

  def format_line(identifier, line)
    if identifier == @last_identifier
      "%-#{@command_width}s - %s" % [nil, line]
    else
      @last_identifier = identifier
      "%-#{@command_width}s - %s" % [identifier, line]
    end
  end

  def stop_command(name)
    targets = []
    if command = @commands[name]
      targets << name
    else
      @commands.each do |cname, _command|
        if cname.split(".").first == name
          targets << cname
        end
      end
    end

    if targets.empty?
      puts "No such command registered: #{name}"
    end

    targets.each do |name|
      if pid = @command_tracker[name]
        @pid_tracker.delete(pid)
        @command_tracker.delete(name)
        @threads.delete(name)
        system "kill -s INT #{pid}"
        puts colorize("yellow", format_line("SpawnControl", "Sent a kill signal to #{name} running at #{pid}"))
      end
    end

  end

  def start_command(name)
    if command = @commands[name]
      if pid = @command_tracker[name]
        puts "#{name} is already running with pid #{pid}"
      else
        spawn(name, command)
        until @threads[name]
          sleep 0.1
        end
        puts colorize("green", format_line("SpawnControl", "#{command} is running."))
      end
    else
      puts "No such command registered: #{name}"
    end
  end

  def restart
    stop
    start
  end

  def restart_command(name)
    stop_command(name)
    start_command(name)
  end

  # list currently running commands
  def running
    names = @command_tracker.map {|name, command| name }
  end

  # ad hoc shell out, with rescuing because of some apparent bugs
  # in MRI 1.8.7's ability to cope with unusual exit codes.
  def system(command)
    begin
      Kernel.system command
    rescue => error
      puts "Exception raised when shelling out: #{error.inspect}"
    end
  end

  def colorize(name, string)
    [Term::ANSIColor.send(name), string, Term::ANSIColor.reset].join
  end

end

