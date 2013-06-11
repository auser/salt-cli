require 'fog'

module Salt
  module Commands
    class SSH < BaseCommand
      def run(args=[])
        vm = find name
        unless vm
          puts "ERROR! Could not find machine by name: #{name}"
          puts "Check your name and try again"
          return
        end
        cmd = _ssh_cmd vm
        puts "#{cmd}" if debug_level
        Kernel.exec cmd
      end
    end
  end
end

Salt.register_command "ssh", Salt::Commands::SSH