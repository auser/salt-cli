require 'fog'

module Salt
  module Commands
    class Launch < BaseCommand
      def run(args=[])
        debug "Launching vm..."
        vm = find name
        # if vm && vm.running?
          # puts "Machine already running. Not launching a new one"
        # else
          provider.launch(vm)
        # end
        Salt::Commands::Bootstrap.new(provider, config).run([])
        
        if name == "#{environment}-master"
          run_after_launch_master
        else
          run_after_launch_non_master
        end
        
        run_after_launch
      end
      
      def run_after_launch_master
        Salt::Commands::Upload.new(provider, config).run([])
        5.times {|i| print "."; sleep 1; }
      end
      
      def run_after_launch_non_master
        if true || auto_accept
          debug "Accepting the key"
          Salt::Commands::Key.new(provider, config.merge(force: true, name: name)).run([])
          5.times {|i| print "."; sleep 1; }
        end
    
        if roles
          debug "Assigning the roles #{roles.join(', ')}"
          Salt::Commands::Role.new(provider, config.merge(debug: true, roles: roles.join(','))).run([])
        end
      end
      
      def run_after_launch
      end
      
      def self.additional_options(x)
        x.on("-r", "--roles <roles>", "Roles") {|n| config[:roles] = n.split(",")}
        x.on('-p', '--ports <ports>', "Port to open up (if necessary)") {|n| config[:ports] = n.split(",")}
        x.on("-a", "--auto_accept", "Auto accept the new role") {|n| config[:auto_accept] = true}
      end
      
    end
  end
end

Salt.register_command "launch", Salt::Commands::Launch