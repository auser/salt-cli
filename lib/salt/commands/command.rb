module Salt
  module Commands
    class Command < BaseCommand

      def run(args)
        vm = find_machine! name
        puts salt_cmd vm, "#{command}"
      end

      def self.additional_options(x)
        x.on("-m", "--command <command>", "Command to run") {|n| config[:command] = n}
      end

    end
  end
end

Salt.register_command "command", Salt::Commands::Command