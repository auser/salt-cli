module Salt
  module Debug
    def debug(msg)
      puts "#{msg}" if debug_level
    end
    
    def debug_level
      config[:debug_level]
    end
  end
end