# stdlib
require "pp"
require "set"
require "open3"
require "fileutils"

# others
require "rubygems"
gem "rb-readline"
require "readline"

Readline.completion_append_character = nil
#Readline.basic_word_break_characters = ""

gem "json"
require "json"

module Consolize
  def self.included(mod)
    mod.module_eval do
      @console = Console.new
      def self.console
        @console
      end

      def self.setup_console(&block)
        console = @console
        @console.on("quit", "q", "exit") do
          console.exit
        end
        @console.on("") do
          puts "Giving me the silent treatment, eh?"
        end
        @console.instance_exec(console, &block)
      end

      def console
        self.class.console.run(self)
      end
    end
  end
end

class Console

  attr_reader :store, :commands
  def initialize
    @patterns = {}
    @commands = Set.new
    Readline.completion_proc = self.method(:complete)
  end

  def complete(str)
    case Readline.line_buffer
    when /^\s*!/
      # if we're in the middle of a bang-exec command, completion
      # should look at the file system.
      self.dir_complete(str)
    else
      # otherwise use the internal dict.
      self.term_complete(str)
    end
  end

  def dir_complete(str)
    Dir.glob("#{str}*")
  end

  def term_complete(str)
    # Terms can be either commands or indexes into the configuration
    # data structure.  No command contains a ".", so that's the test
    # we use to distinguish.
    bits = str.split(".")
    if bits.size > 1
      # Somebody should have documented this when he wrote it, because
      # he now does not remember exactly what he was trying to achieve.
      # He thinks that it's an attempt to allow completion of either
      # full configuration index strings, or of component parts.
      # E.g., if the configuration contains foo.bar.baz, this code
      # will offer both "foo" and "foo.bar.baz" as completions for "fo".
      v1 = @completions.grep(/^#{Regexp.escape(str)}/)
      v2 = @completions.grep(/^#{Regexp.escape(bits.last)}/)
      (v1 + v2.map {|x| (bits.slice(0..-2) << x).join(".") }).uniq
    else
      self.command_complete(str) +
        @completions.grep(/^#{Regexp.escape(str)}/)
    end
  end

  def command_complete(str)
    @commands.grep(/^#{Regexp.escape(str)}/) 
  end

  def sanitize(str)
    # ANSI code stripper regex cargo culted from
    # http://www.commandlinefu.com/commands/view/3584/remove-color-codes-special-characters-with-sed
    str.gsub(/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]/, "")
  end

  def on(*pattern, &block)
    pattern.flatten.each do |pattern|
      @patterns[pattern] = block
      self.add_command(pattern)
    end
  end

  def on_bang(&block)
    on(/^\!\s*(.*)$/, &block)
  end

  def add_command(pattern)
    if pattern.is_a?(String)
      @commands << pattern
    else
      bits = pattern.source.split(" ")
      if bits.size > 1
        @commands << bits.first
      end
    end
  end

  def run(context)
    @completions = context.completions rescue Set.new
    @run = true
    while @run && line = Readline.readline("<3: ", true)
      self.parse(context, line.chomp)
    end
  end

  def exit
    @run = false
  end

  # Attempt to find a registered command that matches the input
  # string.  Upon failure, print an encouraging message.
  def parse(context, input_string)
    _p, block= @patterns.detect do |pattern, block|
      pattern === input_string
    end
    if block
      # Perlish global ugliness necessitated by the use of
      # Enumerable#detect above.  FIXME.
      if $1
        # if the regex had a group (based on the assumption that $1
        # represents the result of the === that matched), call the block
        # with all the group matches as arguments.
        context.instance_exec($~[1..-1], &block)
      else
        context.instance_eval(&block)
      end
    else
      puts "i love you"
    end
  end

end

