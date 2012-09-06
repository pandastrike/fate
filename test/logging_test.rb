require "rubygems"
require "json"

# set up loadpath
here = File.dirname(__FILE__)
FATE_ROOT = File.expand_path("#{here}/..")
$LOAD_PATH.unshift("#{FATE_ROOT}/lib")

require "fate"


string = File.read("examples/simple.json")
configuration = JSON.parse(string, :symbolize_names => true)

color_output = Fate::Output::Relay.new(:file => "test/logs/colors.log")

fate = Fate.new(
  configuration,
  :output => {
    "default" => Fate::Output::MultiRelay.new(:file => "test/logs/default.log"),
    "one" => Fate::Output::Relay.new(:file => "test/logs/one.log"),
    "two" => Fate::Output::Relay.new(:file => "test/logs/two.log"),
    "colors.vermilion" => color_output,
    "colors.green" => color_output
  }
)  


fate.run do
  puts "logging test says, 'hello, there'"
  sleep 4
end



