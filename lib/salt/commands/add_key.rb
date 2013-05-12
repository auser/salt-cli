module Salt
  module Commands
    class AddKey < BaseCommand

      def run(args)
        master = master_server
        vm = find_machine! name
        cmd = sudo_cmd master, "salt-key -a #{name}"
        puts cmd
      end

      def self.additional_options(x)
      end

    end
  end
end

Salt.register_command "add_key", Salt::Commands::AddKey