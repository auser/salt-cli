require 'fog'

module Salt
  module Commands
    class SSH < BaseCommand
      def run(args)
        vm = find_machine! name
        cmd = ssh_cmd "sudo salt '#{pattern}'", vm
        puts `#{cmd}`
      end
    end
  end
end

Salt.register_command "ssh", Salt::Commands::SSH