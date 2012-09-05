require "rubygems"
require "json"

# set up loadpath
here = File.dirname(__FILE__)
FATE_ROOT = File.expand_path("#{here}/..")
$LOAD_PATH.unshift("#{FATE_ROOT}/lib")

require "fate"


string = File.read("examples/simple.json")
configuration = JSON.parse(string, :symbolize_names => true)

color_logger = Fate::LogRelay.new("test/logs/colors.log")

fate = Fate.new(
  configuration,
  :default_log => STDOUT,
  :loggers => {
    "default" => Fate::LogRelay.new("test/logs/default.log"),
    "one" => Fate::LogRelay.new("test/logs/one.log"),
    "two" => Fate::LogRelay.new("test/logs/two.log"),
    "colors.vermilion" => color_logger,
    "colors.green" => color_logger
  }
)  


fate.run do
  puts "hello there"
  sleep 5
end



