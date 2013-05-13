module Salt
  module Commands
    class Role < BaseCommand

      def run(args=[])
        raise "No roles given. Please pass roles to set" unless roles
        if list
          puts current_roles
        else
          vm = find_machine! name
          puts salt_cmd vm, "grains.setval roles #{roles.split(",")} && restart salt-minion"
        end
      end
      
      def current_roles
        @current_roles ||= `#{sudo_cmd(master_server, "grains.item roles")}`.split("\n")[1..-1]
      end

      def self.additional_options(x)
        x.on("-r", "--roles <roles>", "Roles") {|n| config[:roles] = n}
        x.on('-l', '--list', "List keys") {config[:list] = true }
      end

    end
  end
end

Salt.register_command "role", Salt::Commands::Role