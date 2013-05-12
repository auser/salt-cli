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
          
          if provider.launch(vm)
            if true || auto_accept
              Salt.run_provider_command(provider, "add_key")
            end
          
            if roles
              Salt.run_provider_command(provider, "add_role", args)
            end
          end
          
        end
      end
      
      def self.additional_options(x)
        x.on("-r", "--roles <roles>", "Roles") {|n| config[:roles] = n.split(",")}
        x.on("-a", "--auto_accept", "Auto accept the new role") {|n| config[:auto_accept] = true}
      end
      
    end
  end
end

Salt.register_command "launch", Salt::Commands::Launch