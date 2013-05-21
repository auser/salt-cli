module Salt
  module Commands
    class Role < BaseCommand

      def run(args=[])
        require_master_server!
        
        if list
          if available_roles
            puts "Available roles:"
            available_roles.each do |name|
              puts "  #{name}"
            end
          else
            current_roles.each do |name, hsh|
              puts "Server: #{name}"
              if hsh && hsh.has_key?("roles")
                puts "  roles: #{hsh['roles']}"
              end
            end
          end
        else
          raise "No roles given. Please pass roles to set" unless roles
          vm = find name
          puts salt_cmd(vm, "grains.setval roles \"[#{roles}]\" && sudo restart salt-minion")
        end
      end
      
      def available_roles
        Dir["#{Salt.salt_dir}/pillar/roles/*.sls"].map {|f| File.basename(f, File.extname(f)) }
      end
      
      def current_roles
        @current_roles ||= YAML.load(`#{sudo_cmd(master_server, "salt '*' grains.item roles")}`)
      end

      def self.additional_options(x)
        x.on('-a', '--available', "List the available roles") { config[:available] = true}
        x.on("-r", "--roles <roles>", "Roles") {|n| config[:roles] = n}
        x.on('-l', '--list', "List keys") {config[:list] = true }
      end

    end
  end
end

Salt.register_command "role", Salt::Commands::Role