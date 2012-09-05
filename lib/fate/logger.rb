class Fate

  class Logger
    def initialize(options)
      @name = options[:name]
      @width = options[:width]
      if file = options[:file]
        @log = File.new(file, "a")
      elsif io = options[:io]
        @log = io
      end
    end

    def log(string)
      if block_given?
        line = colorize(string, format(yield))
      else
        line = format(string)
      end
      @log.puts line
      @log.flush
    end

    def error(string)
      log("red") { string }
    end

    def green(string)
      log("green") { string }
    end

    def info(string)
      log("yellow") { string }
    end

    def debug(string)
      log(string)
    end

    def format(string)
      self.class.format_line(@name, @width, string)
    end

    def self.format_line(identifier, width, string)
      if identifier == @last_identifier
        "%-#{width}s - %s" % [nil, string]
      else
        @last_identifier = identifier
        "%-#{width}s - %s" % [identifier, string]
      end
    end

    def colorize(name, string)
      [Term::ANSIColor.send(name), string, Term::ANSIColor.reset].join
    end


  end

end
