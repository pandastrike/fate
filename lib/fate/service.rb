require "set"

gem "json-schema"
require "json-schema"
gem "squeeze"
require "squeeze/hash_tree"

require "fate/logger"
require "fate/output"

class Fate

  class Service

    SpecificationSchema = {
      "type" => "object",
      "properties" => {
        "commands" => {
          "type" => "object",
          "required" => true,
          "additionalProperties" => {
            "type" => ["object", "string"]
          }
        },
        "groups" => {
          "type" => "object",
          "additionalProperties" => {
            "type" => ["array"]
          }
        }
      },
      "additionalProperties" => false
    }

    def self.validate(spec)
      JSON::Validator.fully_validate(SpecificationSchema, spec)
    end

    attr_reader :names, :commands, :completions, :specification
    attr_reader :output_handlers, :logger
    def initialize(specification, options)
      stringify(specification)

      validation = self.class.validate(specification)
      if validation.size > 0
        puts "Invalid specification:"
        puts validation
        exit
      end

      @specification = specification
      @options = options

      @commands = process_commands(@specification["commands"])
      @names = @commands.keys
      @groups = @specification["groups"] || {}
      @completions.merge @groups.keys

      @longest_name = @commands.keys.sort_by {|k| k.size }.last.size
      @logger = Fate::MultiLogger.new(:io => STDOUT, :width => @longest_name)
      @output_handlers = Output::Handlers.new(self, options[:output] || {})
    end

    def stringify(hash)
      keys = hash.keys
      keys.each do |key|
        if key.is_a? Symbol
          value = hash.delete(key)
          if value.is_a? Hash
            stringify(value)
          end
          hash[key.to_s] = value
        end
      end
    end

    def process_commands(hash)
      hash = Squeeze::HashTree[hash]

      out = {}
      @completions ||= Set.new
      hash.each_path do |path, value|
        key = path.join(".")
        # add dot-delimited command names to the completions
        @completions += path.map {|s| s.to_s }
        @completions << key
        # register each command under the dot-delimited name
        out[key] = value
      end
      out
    end

    def resolve_commands(name)
      targets = []
      if @commands.has_key?(name)
        targets << name
      elsif @groups.has_key?(name)
        @groups[name].each do |gname|
          targets += resolve_commands(gname)
        end
      else
        @commands.each do |cname, _command|
          if cname.split(".").first == name
            targets << cname
          end
        end
      end
      targets
    end


    def start_order(command_names)
      # presuming the spec file ordered the commands where the dependencies
      # come before the dependers, we should stop the processes in reverse order,
      # then start them back up again in forward order.
      command_names.sort_by {|name| self.names.index(name) }
    end

    def stop_order(command_names)
      start_order(command_names).reverse
    end

  end

end

