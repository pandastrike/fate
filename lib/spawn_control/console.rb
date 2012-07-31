require "consolize"
class SpawnControl

  include Consolize

  setup_console do |console|

    on("help") do
      commands = console.commands.select {|c| c.size > 1 } + ["!"]
      puts "* Available commands: " << commands.sort.join(" ")
      puts "* Tab completion works for commands and config keys"
    end

    on("quit") do
      exit
    end

    on_bang do |args|
      system args.first
    end

    on("commands") do
      puts JSON.pretty_generate(commands)
    end

    on("configuration", "config") do
      puts JSON.pretty_generate(configuration)
    end

  end

end
