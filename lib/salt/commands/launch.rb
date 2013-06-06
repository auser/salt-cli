require 'fog'

module Salt
  module Commands
    class Launch < BaseCommand
      def run(args=[])
        if launch_plan
          if config[:plans] && config[:plans][launch_plan.to_sym]
            plan = config[:plans][launch_plan.to_sym]
            plan.each do |mach|
              mach.each do |name, custom_opts|
                old_config = config.dup
                custom_opts = custom_opts || {}
                # Change this on the fly
                # Somewhat of a dirty approach.
                # This really should be cleaned up
                # This gigantic method basically replicates calling a command from
                # the commandline.
                new_name = BaseCommand.generate_name({name: name, environment: environment})
                custom_opts.merge!(name: new_name)
                custom_opts.each do |k,v|
                  self.config[k] = v
                  instance_variable_set("@#{k}", v)
                end
                provider.set_name new_name
                launch_by_name(name.to_s)
              end
            end
            master_name = BaseCommand.generate_name({name: name, environment: environment})
            provider.set_name master_name
            Salt::Commands::Highstate.new(provider, config.merge(name: "master")).run([])
          else
            puts "ERROR: Launch plan #{launch_plan} not found"
            exit
          end
        else
          launch_by_name
        end
      end
      
      def launch_by_name(n=name)
        vm = find n
        if vm && vm.running?
          puts "Machine (#{n}) already running. Not launching a new one"
        else
          provider.launch(vm)
          Salt::Commands::Bootstrap.new(provider, config).run([])
        
          if name == "#{environment}-master"
            run_after_launch_master
          else
            run_after_launch_non_master
          end
        
          run_after_launch
        end
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
        x.on("-p", "--plan <plan_name>", "Launch a plan") {|n| config[:launch_plan] = n}
      end
      
    end
  end
end

Salt.register_command "launch", Salt::Commands::Launch