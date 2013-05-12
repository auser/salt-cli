module Salt
  module Commands
    class AddRole < BaseCommand

      def run(args)
        raise "No roles given. Please pass roles to set" unless roles
        vm = find_machine! name
        cmd = salt_cmd vm, "grains.setval roles #{roles}"
        puts `#{cmd}`
      end

      def self.additional_options(x)
        x.on("-r", "--roles <roles>", "Roles") {|n| run_options[:roles] = n}
      end

    end
  end
end

Salt.register_command "add_role", Salt::Commands::AddRole