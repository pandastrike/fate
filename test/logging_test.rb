require "rubygems"

# set up loadpath
here = File.dirname(__FILE__)
FATE_ROOT = File.expand_path("#{here}/..")
$LOAD_PATH.unshift("#{FATE_ROOT}/lib")

require "fate"

configuration = {
  :commands => {
    :one => "ruby test/exiting.rb",
    :two => "tail -f README.md"
  }
}

color_output = File.new("test/logs/colors.log", "a")

fate = Fate.new(
  configuration,
  :output => {
    "default" => Fate::Output::IOMux.new(:file => "test/logs/default.log"),
    "one" => File.new("test/logs/one.log", "a"),
    "colors.vermilion" => color_output,
    "colors.green" => color_output
  }
)  


fate.run do
  puts "logging test says, 'hello, there'"
  sleep 4
end



