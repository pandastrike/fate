class Fate

  module Formatter
    def format_line(identifier, line)
      if identifier == @last_identifier
        "%-#{@command_width}s - %s" % [nil, line]
      else
        @last_identifier = identifier
        "%-#{@command_width}s - %s" % [identifier, line]
      end
    end

    def colorize(name, string)
      [Term::ANSIColor.send(name), string, Term::ANSIColor.reset].join
    end
  end

end
