module Salt
  module Commands
    class AddRole < BaseCommand

      def run(args=[])
        raise "No roles given. Please pass roles to set" unless roles
        vm = find_machine! name
        puts salt_cmd vm, "grains.setval roles #{roles.split(",")} && restart salt-minion"
      end

      def self.additional_options(x)
        x.on("-r", "--roles <roles>", "Roles") {|n| config[:roles] = n}
      end

    end
  end
end

Salt.register_command "add_role", Salt::Commands::AddRole