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
                  self.send "#{k}=", v
                end
                provider.set_name new_name
                launch_by_name(name.to_s)
              end
            end
            provider.set_name "#{environment}-master"
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
        
          if n == "master"
            run_after_launch_master(n)
          else
            run_after_launch_non_master(n)
          end
        
          run_after_launch(n)
        end
      end
      
      def run_after_launch_master(n=name)
        Salt::Commands::Upload.new(provider, config.merge(name: "master")).run([])
        5.times {|i| print "."; sleep 1; }
      end
      
      def run_after_launch_non_master(n=name)
        if true || auto_accept
          debug "Accepting the key"
          Salt::Commands::Key.new(provider, config.merge(force: true, name: n)).run([])
          5.times {|i| print "."; sleep 1; }
        end
        
        if roles
          debug "Assigning the roles #{roles.join(',')} to #{n}"
          Salt::Commands::Role.new(provider, config.merge(name: n, debug: debug_level, roles: roles.join(','))).run([])
          5.times {|i| print "."; sleep 1; }
        end
        
        ## Run mine.update ALWAYS
        salt_cmd find(n), 'mine.update'
      end
      
      def run_after_launch(n=name)
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