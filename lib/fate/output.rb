class Fate
  module Output

    class Handlers

      def initialize(service, handlers)
        @service = service
        @handlers = handlers
      end

      def relay(name, string)
        if handler = @handlers[name]
          handler.puts(string)
        elsif handler = @handlers["default"]
          handler.relay(name, string)
        else
          @service.logger.write(name, string)
        end
      end

    end

    class Relay
      def initialize(options)
        if file = options[:file]
          @io = File.new(file, "a")
        elsif io = options[:io]
          @io = io
        end
      end

      def puts(string)
        @io.puts string
        @io.flush
      end
    end

    class MultiRelay

      def initialize(options)
        if file = options[:file]
          @io = File.new(file, "a")
        elsif io = options[:io]
          @io = io
        end
      end

      def relay(name, string)
        @io.puts(format_line(name, string))
        @io.flush
      end

      def format_line(name, string)
        if name == @last_identifier
          string
        else
          @last_identifier = name
          "==> #{name} <==\n#{string}"
        end
      end
    end

  end
end

