require 'fog'

module Salt
  module Commands
    class Upgrade < BaseCommand
      def run(args=[])
        require_master_server!
        
        dsystem sudo_cmd master_server, "apt-get -y upgrade salt-master"
        dsystem sudo_cmd master_server, "service salt-master restart"
        dsystem salt_cmd master_server, "pkg.upgrade salt-minion"
        dsystem salt_cmd master_server, "service.restart salt-minion"
      end
    end
  end
end

Salt.register_command "upgrade", Salt::Commands::Upgrade