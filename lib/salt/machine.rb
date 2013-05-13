module Salt
  class Machine < OpenStruct
    
    def running?
      state == :running
    end
    
  end
end