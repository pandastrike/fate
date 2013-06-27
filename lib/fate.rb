
gem "term-ansicolor"
require "term/ansicolor"

require "fate/service"
require "fate/process_manager"

Thread.abort_on_exception = true

class Fate

  def self.start(specification, &block)
    self.new(specification).start(&block)
  end

  attr_reader :service, :manager, :control
  def initialize(specification, options)
    @service = Fate::Service.new(specification, options)
    @manager = Fate::ProcessManager.new(service, options)
    @control = Fate::Control.new(@manager, options)
  end

  class Control

    attr_reader :service, :manager, :completions, :logger

    def initialize(manager, options={})
      @manager = manager
      @service = @manager.service
      @completions = @service.completions

      @spec = @service.specification
      @logger = @service.logger["Fate Control"]
    end

    def log(*args, &block)
      @logger.log(*args, &block)
    end

    def start(*command_strings)
      if manager.start(command_strings)
        logger.green "All processes are running."
      else
        logger.error "Failed to start."
      end
    end

    def stop(*command_strings)
      manager.stop(command_strings)
    end

    def restart(*command_strings)
      stop(*command_strings)
      start(*command_strings)
    end

    # Run only the processes specified by the arguments.  Any existing
    # processes outside this set will be stopped.
    def run(*command_strings)
      manager.run(command_strings)
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
end

