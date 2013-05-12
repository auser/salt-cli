require "salt/machine"

module Salt
  class BaseProvider < OpenStruct
    #### PUBLIC METHODS
    def list
      raise UnimplementedError.new("inventory")
    end
    
  end
end

require 'salt/providers/vagrant_provider'