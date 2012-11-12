require "rubygems"

# set up loadpath
here = File.dirname(__FILE__)
FATE_ROOT = File.expand_path("#{here}/..")
$LOAD_PATH.unshift("#{FATE_ROOT}/lib")

require "fate"
require "fate/repl"

configuration = {
  :commands => {
    :exiter => "ruby test/processes/exiter.rb 1 1",
    :one => "ruby test/processes/delayer.rb 2",
    :two => "ruby test/processes/delayer.rb 3",
  }
}

color_output = File.new("test/logs/colors.log", "a")

fate = Fate.new(
  configuration,
)  

fate.start
fate.repl
