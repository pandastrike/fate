class Fate

  # Simple logging class designed to interleave the output from multiple
  # processes while making it obvious which lines were logged by which process.

  class MultiLogger

    attr_reader :width, :io
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
      def initialize(master, name)
        @master = master
        @io = @master.io
        @name = name
      end

      # duck typing for IO
      def write(string)
        return 0 unless string
        num = @io.write(@master.format(@name, string))
        @io.flush
        num
      end

      def method_missing(method, *args, &block)
        if @master.respond_to?(method)
          # insert this logger's name into every relayed call.
          @master.send(method, @name, *args, &block)
        elsif @io.respond_to?(method)
          @io.send(method, *args, &block)
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
      num = @io.write line
      @io.flush
      num
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
      string.chomp!
      if name == @last_identifier
        "%-#{width}s - %s\n" % [nil, string]
      else
        @last_identifier = name
        "%-#{width}s - %s\n" % [name, string]
      end
    end

    def colorize(name, string)
      [Term::ANSIColor.send(name), string, Term::ANSIColor.reset].join
    end

  end

end
