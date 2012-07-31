# Cross-VM compatibility
# thanks to http://ku1ik.com/2010/09/18/open3-and-the-pid-of-the-spawn.html
# TODO: consider using systemu: https://github.com/ahoward/systemu/
if IO.respond_to?(:popen4)
  def open4(*args)
    IO.popen4(*args)
  end
else
  require 'open4'
end

class Commando

  def self.start(commands, &block)
    self.new(commands).start(&block)
  end

  def initialize(commands)
    @commands = commands
    @threads = []
    @process_tracker = {}
  end

  def start(&block)
    @running = []
    @commands.each do |command|
      spawn(command)
    end

    at_exit { stop }

    Thread.new do
      # pid of -1 means to wait for any child process
      pid, status = Process.wait2(-1)
      if status.exitstatus != 0
        puts "Command exited with code #{status}:"
        puts "  (#{pid}) #{@process_tracker[pid]}"
        exit(status.exitstatus)
      end
    end

    # Command threads add themselves to the array when they believe
    # their commands are ready.
    until @threads.size == @commands.size
      sleep 0.1
    end

    print "All commands are running. "
    if block
      puts "Evaluating the block passed to Commando#start."
      yield
      stop
    else
      #puts "Use Ctrl-C (or another signal of your choice) to shut down."
      puts "say 'quit' when you're done (or use the signal of your choice)"
      loop do
        line = STDIN.gets.chomp
        if line == "quit"
          break
        end
      end
    end

  end

  def stop
    if @process_tracker.size != 0
      command = "kill #{@process_tracker.keys.join(' ')}"
      system command
      @process_tracker.clear
    end
  end

  def spawn(command)
    return Thread.new do
      pid, stdin, stdout, stderr = open4(command)
      puts "Starting (#{pid}): #{command}"
      @process_tracker[pid] = command

      Thread.new do
        while line = stderr.gets
          $stderr.puts "(#{pid}) #{line}"
        end
      end

      # First line written to STDOUT is interpreted as the service
      # signalling that it is ready.
      line = stdout.gets
      STDOUT.puts format_line(pid, line)
      @threads << Thread.current

      while line = stdout.gets
        STDOUT.puts format_line(pid, line)
      end
    end
  end

  def format_line(pid, line)
    "(#{pid}) #{line}"
  end


end


