require "pp"

# set up loadpath
here = File.dirname(__FILE__)
FATE_ROOT = File.expand_path("#{here}/..")
$LOAD_PATH.unshift("#{FATE_ROOT}/lib")

require "fate/service"

service = Fate::Service.new(
  {
    "commands" => {
      "one" => "command_one",
      "two" => "command_two",
      "colors" => {
        "red" => "command_red",
        "blue" => "command_blue"
      }
    },
    "groups" => {
      "numbers" => ["one", "two"],
      "mixed" => ["one", "colors.blue"],
    }
  },
  {}
)

describe "Fate::Service" do

  specify "#resolve_commands" do
    commands = service.resolve_commands("one")
    commands.sort.should == %w[ one ]

    commands = service.resolve_commands("colors.blue")
    commands.sort.should == %w[ colors.blue ]

    commands = service.resolve_commands("colors")
    commands.sort.should == %w[ colors.blue colors.red ]

    commands = service.resolve_commands("numbers")
    commands.sort.should == %w[ one two ]

    commands = service.resolve_commands("mixed")
    commands.sort.should == %w[ colors.blue one ]
  end

end


