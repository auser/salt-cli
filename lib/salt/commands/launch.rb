require 'fog'

module Salt
  module Commands
    class Launch < BaseCommand
      def run(args)
        # Hash[vm.config.vm.networks][:hostonly].first,
        vm = find_machine! name
        if vm.state == :running
          puts "The machine is already running. Not launching"
        else
          provider.launch(name)
        end
        if roles
          Salt.run_provider_command(provider, "add_role", args)
        end
      end
      
      def self.additional_options(x)
        x.on("-r", "--roles <roles>", "Roles") {|n| config[:roles] = n.split(",")}
      end
      
    end
  end
end

Salt.register_command "launch", Salt::Commands::Launch