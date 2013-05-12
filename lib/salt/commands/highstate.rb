module Salt
  module Commands
    class Highstate < BaseCommand
      def run(args=[])
        vm = find_machine! name
        salt_cmd vm, "state.highstate"
      end
    end
  end
end

Salt.register_command "highstate", Salt::Commands::Highstate