class Fate

  # Simple logging class designed to interleave the output from multiple
  # processes while making it obvious which lines were logged by which process.
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

  class MultiLogger

    attr_reader :width
    def initialize(options)
      @width = options[:width]
      if file = options[:file]
        @io = File.new(file, "a")
      elsif io = options[:io]
        @io = io
      end
    end

    def [](name)
      Sublogger.new(self, name)
    end

    class Sublogger
      def initialize(multi_logger, name)
        @multi_logger = multi_logger
        @name = name
      end

      def method_missing(method, *args, &block)
        if @multi_logger.respond_to?(method)
          # insert this logger's name into every relayed call.
          @multi_logger.send(method, @name, *args, &block)
        else
          super
        end
      end
    end

    def write(name, string, color=nil)
      if color
        line = colorize(color, format(name, string))
      else
        line = format(name, string)
      end
      @io.puts line
      @io.flush
    end

    def error(name, string)
      write(name, string, "red")
    end

    def green(name, string)
      write(name, string, "green")
    end

    def info(name, string)
      write(name, string, "yellow")
    end

    def debug(name, string)
      write(name, string)
    end

    def format(name, string)
      if name == @last_identifier
        "%-#{width}s - %s" % [nil, string]
      else
        @last_identifier = name
        "%-#{width}s - %s" % [name, string]
      end
    end

    def colorize(name, string)
      [Term::ANSIColor.send(name), string, Term::ANSIColor.reset].join
    end

  end

end
