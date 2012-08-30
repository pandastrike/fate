require "set"

gem "term-ansicolor"
gem "squeeze"
require "term/ansicolor"
require "squeeze/hash_tree"

require "fate/formatter"
require "fate/manager"

Thread.abort_on_exception = true

class Fate

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

  def start(&block)
    manager.spawn_commands(@name_commands)
    if block
      yield(self)
      manager.stop
    end
  end

  def start_command(name)
    if command = @name_commands[name]
      manager.start_command(name, command)
    else
      puts "No such command registered: #{name}"
    end
  end

  def restart
    manager.stop
    start
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

end

