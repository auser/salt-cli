module Salt
  class BaseProvider
    #### PUBLIC METHODS
    def inventory
      raise UnimplementedError.new("inventory")
    end
  end
end
