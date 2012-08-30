gem "consolize"
require "consolize"
class Fate

  include Consolize

  setup_console do |console|

    on("help") do
      commands = console.commands.select {|c| c.size > 1 } + ["!"]
      puts "* Available commands: " << commands.sort.join(" ")
    end

    on("quit", "q", "exit") do
      exit
    end

    on(/stop (\S+)$/) do |args|
      command = args.first
      self.manager.stop_command(args.first)
    end

    on(/start (\S+)$/) do |args|
      command = args.first
      self.start_command(args.first)
    end

    on("restart") do
      self.restart
    end

    on(/restart (\S+)$/) do |args|
      command = args.first
      self.manager.restart_command(args.first)
    end

    on_bang do |args|
      self.system args.first
    end

    on("commands") do
      puts JSON.pretty_generate(self.name_commands)
    end

    on("running") do
      puts self.manager.running
    end

    on("configuration", "config") do
      puts JSON.pretty_generate(configuration)
    end

  end

end
