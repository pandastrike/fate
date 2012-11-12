require "harp"
class Fate

  include Harp

  setup_harp do |harp|

    command("help") do
      commands = harp.command_names.select {|c| c.size > 1 } + ["!"]
      puts "* Available commands: " << commands.sort.join(" ")
    end

    command("quit", :alias => "q") { exit }
    command("exit") { exit }

    command("stop") do
      self.stop
    end

    command("stop", :process_name) do |args|
      command = args.first
      self.stop_command(args.first)
    end

    command("start", :process_name) do |args|
      command = args.first
      self.start_command(args.first)
    end

    command("restart") do
      self.restart
    end

    command("restart", :process_name) do |args|
      command = args.first
      self.restart_command(args.first)
    end

    command("commands") do
      puts self.service.names
    end

    command("running") do
      puts self.running
    end

    command("configuration") do
      puts JSON.pretty_generate(self.service.specification)
    end

  end

end
