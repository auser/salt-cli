require 'ostruct'
require 'salt/ssh'

module Salt
  # Base command
  class BaseCommand < OpenStruct
    include SSH
    attr_reader :config, :provider
    
    def initialize(provider, opts={})
      @provider = provider
      super(opts)
    end

    def run(args, opts={})
      raise "Not implemented"
    end
    
    # PRIVATE
    def find_machine!(name)
      found_provider = provider.find(name)
      unless found_provider
        puts <<-EOE
        No provider with the name #{name} can be found. Check your config.
        EOE
      exit(1)
      end
      found_provider
    end
    
    def master_server
      find_machine! "master"
    end
    
    def self.config
      @config ||= Salt.default_config
    end

    def self.run_command(provider, args)
      op = option_parser
      additional_options(op)
      op.parse!(args)
      
      provider = Salt.get_provider(provider).new(config) if provider.is_a?(String)
      new(provider, config).run(args)
    end
    
    def self.get_provider(provider_name)
      all_providers[provider_name]
    end

    def self.option_parser
      OptionParser.new do |x|
        x.banner = "#{self.class}"
        x.separator ''
        x.on("-c", "--config <name>", "config") do |n| 
          @config.merge!(Salt.read_config(n, config).merge(config))
        end
        x.on("-n", "--name <name>", "The name of the server") {|n| config[:name] = n}
        x.on("-i", "--ip <ip>", "The ip of the server") {|n| config[:ip] = n}
        x.on("-u", "--user <user>", "The username") {|n| config[:user] = n}
        x.on("-k", "--key <key>", "The key for the server") {|n| config[:key] = n}
        x.on("-t", "--target <roles>", "Pattern to match") {|n| config[:pattern] = n}
      end
    end
    def self.load_config(file)
      begin
        f = File.open(file, 'r') 
        YAML.load(ERB.new(f))
      rescue
      end
    end
    def self.additional_options(parser)
    end
  end
end

require 'salt/commands/list'
require 'salt/commands/launch'
require 'salt/commands/ssh'

require 'salt/commands/add_key'
require 'salt/commands/add_role'
require 'salt/commands/highstate'