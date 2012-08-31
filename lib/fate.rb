require "set"

gem "term-ansicolor"
gem "squeeze"
require "term/ansicolor"
require "squeeze/hash_tree"

require "fate/formatter"
require "fate/manager"

Thread.abort_on_exception = true

class Fate

  class CommandRegistry
    # TODO
  end

  include Formatter

  def self.start(configuration, &block)
    self.new(configuration).start(&block)
  end

  attr_reader :manager, :configuration, :completions, :name_commands

  def initialize(configuration, options={})
    @configuration = configuration
    @options = options
    if logfile = options[:service_log]
      @log = File.new(logfile, "a")
    else
      @log = STDOUT
    end
    commands = Squeeze::HashTree[@configuration[:commands]]

    @completions = Set.new

    @name_commands = {}
    commands.each_path do |path, value|
      key = path.join(".")
      # add dot-delimited command names to the completions
      @completions += path.map {|s| s.to_s }
      @completions << key
      # register each command under the dot-delimited name
      @name_commands[key] = value
    end
    @command_width = @name_commands.keys.sort_by {|k| k.size }.last.size

    @manager = Manager.new(:log => @log, :command_width => @command_width)

    @threads = {}
    @pid_names = {}
    @name_pids = {}
  end

  def run(&block)
    start
    if block
      yield(self)
      manager.stop
    end
  end

  def start
    manager.start_group(@name_commands)
    message = format_line("Fate Control", "All commands are running. ")
    puts colorize("green", message)
  end

  def stop
    keys = @name_commands.keys
    # presuming the spec file ordered the commands where the dependencies
    # come before the dependers, we should stop the processes in reverse order,
    # then start them back up again in forward order.
    names = manager.running.sort_by {|name| keys.index(name) }
    names.reverse.each do |name|
      manager.stop_command(name)
    end
  end

  def restart
    stop
    # FIXME: this is here to prevent redis-server from crying
    sleep 0.5
    start
  end

  def resolve_commands(name)
    targets = []
    if @name_commands.has_key?(name)
      targets << name
    else
      @name_commands.each do |cname, _command|
        if cname.split(".").first == name
          targets << cname
        end
      end
    end
    targets
  end

  def start_command(spec)
    names = resolve_commands(spec)
    if names.empty?
      puts "No commands found for: #{spec}"
    else
      names.each do |name|
        command = @name_commands[name]
        manager.start_command(name, command)
      end
    end
  end

  def stop_command(spec)
    names = resolve_commands(spec)
    if names.empty?
      puts "No commands found for: #{spec}"
    else
      names.each do |name|
        manager.stop_command(name)
      end
    end
  end

  def restart_command(name)
    stop_command(name)
    start_command(name)
  end

  def running
    manager.running
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

