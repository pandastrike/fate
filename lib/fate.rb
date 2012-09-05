require "set"

gem "term-ansicolor"
gem "squeeze"
require "term/ansicolor"
require "squeeze/hash_tree"

require "fate/logger"
require "fate/service"
require "fate/manager"

Thread.abort_on_exception = true

class Fate

  def self.start(specification, &block)
    self.new(specification).start(&block)
  end

  attr_reader :service, :manager, :completions, :logger

  def initialize(spec, options={})
    @service = Service.new(spec, options)
    @completions = @service.completions
    @command_width = @service.longest_name

    @spec = spec
    @logger = @service.logger("Fate Control")

    @manager = Manager.new(@service)
  end

  def log(*args, &block)
    @logger.log(*args, &block)
  end

  def run(&block)
    start
    if block
      yield(self)
      manager.stop
    end
  end

  def start
    manager.start_group(@service.commands)
    logger.green "All commands are running."
  end

  def stop
    ordered = @service.stop_order(manager.running)
    ordered.each do |name|
      manager.stop_command(name)
    end
  end

  def restart
    stop
    # FIXME: this is here to prevent redis-server from crying
    sleep 0.5
    start
  end

  def start_command(spec)
    names = @service.resolve_commands(spec)
    if names.empty?
      puts "No commands found for: #{spec}"
    else
      names.each do |name|
        command = @service.commands[name]
        manager.start_command(name, command)
      end
    end
  end

  def stop_command(spec)
    names = @service.resolve_commands(spec)
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

