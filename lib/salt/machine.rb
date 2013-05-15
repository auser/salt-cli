module Salt
  class Machine < OpenStruct
    
    def running?
      state == :running
    end
    
    def ip
      public_ips[0]
    end
    
  end
end