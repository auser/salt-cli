require "salt/machine"

module Salt
  class BaseProvider# < OpenStruct
    
    attr_reader :config
    
    def initialize(opts={})
      @config = opts
    end
    
    #### PUBLIC METHODS
    def list
      raise UnimplementedError.new("list")
    end
    
    # Cleanup
    def cleanup!
      raise UnimplementedError.new("cleanup")
    end
    
    def running_list
      list.select {|vm| vm.running? }
    end
    
    def to_s
      self.class.to_s.split("::")[-1].downcase
    end
    
    def set_name(new_name)
      config[:name] = new_name
    end
    
    def update_config!(opts={})
      config.merge!(opts)
    end
    
    def reset!
    end
    
  end
end

require 'salt/providers/vagrant_provider'
require 'salt/providers/aws_provider'