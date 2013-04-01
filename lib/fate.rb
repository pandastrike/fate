
gem "term-ansicolor"
require "term/ansicolor"

require "fate/service"
require "fate/process_manager"

Thread.abort_on_exception = true

class Fate

  def self.start(specification, &block)
    self.new(specification).start(&block)
  end

  attr_reader :service, :manager, :completions, :logger

  def initialize(spec, options={})
    @service = Service.new(spec, options)
    @completions = @service.completions

    @spec = spec
    @logger = @service.logger["Fate Control"]

    @manager = ProcessManager.new(@service, options)
  end

  def log(*args, &block)
    @logger.log(*args, &block)
  end

  def run(&block)
    if start
      if block
        yield(self)
        stop
      end
    else
      logger.error "Failed to start"
    end
  end

  def start(command_specs=[])
    if command_specs.size > 0
      command_specs.each do |command_spec|
        self.start_command(command_spec)
      end
    else
      if manager.start_group(@service.commands)
        logger.green "All commands are running."
        true
      else
        false
      end
    end
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

  def start_command(command_spec)
    names = @service.resolve_commands(command_spec)
    if names.empty?
      puts "No commands found for: #{command_spec}"
    else
      commands = {}
      names.each do |name|
        command = @service.commands[name]
        commands[name] = command
      end
      if manager.start_group(commands)
        logger.green "All commands in '#{command_spec}' running."
      else
        logger.red "Failed to start '#{command_spec}'."
      end
    end
  end

  def stop_command(command_spec)
    names = @service.resolve_commands(command_spec)
    if names.empty?
      puts "No commands found for: #{command_spec}"
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

