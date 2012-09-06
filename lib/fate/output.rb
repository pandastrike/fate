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
        @io = @master.io
        @name = name
      end

      # duck typing for IO
      def write(string)
        num = @io.write(@master.format(@name, string))
        @io.flush
        num
      end

      def method_missing(method, *args, &block)
        if @io.respond_to?(method)
          @io.send(method, *args, &block)
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
        @handlers[name] ||= IOFilter.new(self, name)
      end

      def format(name, string)
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

