module Salt
  module Commands
    class Role < BaseCommand

      def run(args=[])
        if list
          current_roles.each do |name, hsh|
            puts "Server: #{name}"
            if hsh && hsh.has_key?("roles")
              puts "  roles: #{hsh['roles']}"
            end
          end
        else
          raise "No roles given. Please pass roles to set" unless roles
          vm = find name
          puts salt_cmd vm, "grains.setval roles #{roles.split(",")} && sudo restart salt-minion"
        end
      end
      
      def current_roles
        @current_roles ||= YAML.load(`#{sudo_cmd(master_server, "salt '*' grains.item roles")}`)
      end

      def self.additional_options(x)
        x.on("-r", "--roles <roles>", "Roles") {|n| config[:roles] = n}
        x.on('-l', '--list', "List keys") {config[:list] = true }
      end

    end
  end
end

Salt.register_command "role", Salt::Commands::Role