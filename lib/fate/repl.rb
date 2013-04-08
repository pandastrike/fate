require "harp"
class Fate
  class Control

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
        self.stop(args.first)
      end

      command("run") do
        self.run
      end

      command("run", :process_name) do |args|
        command = args.first
        self.run(args.first)
      end

      command("start", :process_name) do |args|
        command = args.first
        self.start(args.first)
      end

      command("restart") do
        self.restart
      end

      command("restart", :process_name) do |args|
        command = args.first
        self.restart(args.first)
      end

      command("processes") do
        puts self.service.names
      end

      #command("groups") do
      #end

      command("running") do
        puts self.running
      end

      command("configuration") do
        puts JSON.pretty_generate(self.service.specification)
      end

    end

  end
end

