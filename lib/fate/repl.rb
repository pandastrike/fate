gem "harp"
require "harp"
class Fate

  include Harp

  setup_repl do |repl|

    on("help") do
      commands = repl.commands.select {|c| c.size > 1 } + ["!"]
      puts "* Available commands: " << commands.sort.join(" ")
    end

    on("quit", "q", "exit") do
      exit
    end

    on("stop") do
      self.stop
    end

    on(/^stop (\S+)$/) do |args|
      command = args.first
      self.stop_command(args.first)
    end

    on(/^start (\S+)$/) do |args|
      command = args.first
      self.start_command(args.first)
    end

    on("restart") do
      self.restart
    end

    on(/restart (\S+)$/) do |args|
      command = args.first
      self.restart_command(args.first)
    end

    on_bang do |args|
      self.system args.first
    end

    on("commands") do
      puts self.service.names
    end

    on("running") do
      puts self.running
    end

    on("configuration", "config") do
      puts JSON.pretty_generate(self.service.specification)
    end

  end

end
