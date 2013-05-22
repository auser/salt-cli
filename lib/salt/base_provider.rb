require "salt/machine"

module Salt
  class BaseProvider < OpenStruct
    #### PUBLIC METHODS
    def list
      raise UnimplementedError.new("inventory")
    end
    
    def to_s
      self.class.to_s.split("::")[-1].downcase
    end
    
  end
end

require 'salt/providers/vagrant_provider'
require 'salt/providers/aws_provider'