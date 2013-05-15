require 'fog'

module Salt
  module Commands
    class SSH < BaseCommand
      def run(args=[])
        vm = find name
        cmd = _ssh_cmd vm
        puts "#{cmd}" if debug_level
        Kernel.exec cmd
      end
    end
  end
end

Salt.register_command "ssh", Salt::Commands::SSH