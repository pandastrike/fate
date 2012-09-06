class Fate
  module Output

    class Handlers

      def initialize(service, handlers)
        @service = service
        @handlers = handlers
      end

      def [](name)
        if handler = @handlers[name]
          handler
        elsif @handlers["default"]
          @handlers[name] = @handlers["default"][name]
        else
          @handlers[name] = @service.logger[name]
        end
      end

    end

    class IOFilter
      def initialize(master, name)
        @master = master
        @name = name
      end

      def write(string)
        @master.io.flush
        @master.io.write(format(@name, string))
      end

      def method_missing(method, *args, &block)
        if @master.io.respond_to?(method)
          @master.io.send(method, *args, &block)
        else
          super
        end
      end
    end

    class IOMux
      attr_reader :io
      attr_accessor :last_identifier
      def initialize(options)
        @last_identifier = nil
        if file = options[:file]
          @io = File.new(file, "a")
        elsif io = options[:io]
          @io = io
        end
        @handlers = {}
      end

      def [](name)
        @handlers[name] ||= NamedIO.new(self, name)
      end

      class NamedIO < IOFilter

        def format(name, string)
          if name == @master.last_identifier
            string
          else
            @master.last_identifier = name
            "==> #{name} <==\n#{string}"
          end
        end

      end

    end

  end
end

