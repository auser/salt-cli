require 'fog'

module Salt
  module Commands
    class Launch < BaseCommand
      def run(args=[])
        if config[:launch_plan]
          plan_name = config[:launch_plan].to_sym
          threads = []
          if config[:plans] && config[:plans][plan_name]
            plan = config[:plans][plan_name]
            
            ## WE HAVE TO LAUNCH THE MASTER FIRST
            m = plan.delete(:master)
            m.each {|k,v| self.config[k] = v }
            provider.set_name "master"
            launch_by_name("master", provider)
            # THEN WE CAN LAUNCH EVERY OTHER MACHINE
            plan.each do |name, custom_opts|
              threads << Thread.new do
                old_config = config.dup
                custom_opts = custom_opts || {}
                pr = Salt.get_provider(config[:provider_name]).new(config)
                custom_opts.merge!(name: name)
                custom_opts.each {|k,v| self.config[k] = v }
                pr.set_name new_name
                launch_by_name(name.to_s, pr)
              end
            end
            threads.each {|t| t.join }
            provider.set_name "#{environment}-master"
            if config[:overstate]
              Salt::Commands::Overstate.new(provider, config.merge(name: "master")).run([])
            else
              Salt::Commands::Highstate.new(provider, config.merge(name: "master")).run([])
            end
          else
            puts "ERROR: Launch plan #{launch_plan} not found"
            exit
          end
        else
          launch_by_name
        end
      end
      
      def launch_by_name(n=name, pr=provider)
        vm = find n
        if vm && vm.running?
          puts "Machine (#{n}) already running. Not launching a new one"
        else
          pr.launch(vm)
          Salt::Commands::Bootstrap.new(pr).run([])
        
          if n == "master"
            run_after_launch_master(n, pr)
          else
            run_after_launch_non_master(n, pr)
          end
        
          run_after_launch(n)
        end
      end
      
      def run_after_launch_master(n=name, pr=provider)
        pr.config.merge!(name: "master")
        Salt::Commands::Upload.new(pr).run([])
        5.times {|i| print "."; sleep 1; }
      end
      
      def run_after_launch_non_master(n=name,pr=provider)
        if true || auto_accept
          debug "Accepting the key"
          pr.config.merge!(force: true, name: n)
          Salt::Commands::Key.new(pr).run([])
          5.times {|i| print "."; sleep 1; }
        end
        
        if roles
          debug "Assigning the roles #{roles.join(',')} to #{n}"
          pr.update_config!(name: n, debug: config[:debug_level], roles: config[:roles].join(","))
          Salt::Commands::Role.new(pr).run([])
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
        x.on("-o", "--overstate", "Use overstate instead of highstate") {config[:overstate] = true}
      end
      
    end
  end
end

Salt.register_command "launch", Salt::Commands::Launch