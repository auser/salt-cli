module Salt
  module Debug
    def debug(msg)
      puts "#{msg}" if debug_level
    end
  end
end