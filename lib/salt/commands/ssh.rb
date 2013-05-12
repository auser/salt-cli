require 'fog'

module Salt
  module Commands
    class SSH < BaseCommand
      def run(args)
        vm = find_machine! name
        cmd = _ssh_cmd vm
        Kernel.exec cmd
      end
    end
  end
end

Salt.register_command "ssh", Salt::Commands::SSH