require 'fog'

module Salt
  module Commands
    class Teardown < BaseCommand
      def run(args=[])
        vm = find name
        if vm.state == :running
          Salt::Commands::Key.new(provider, config.merge(delete: true, name: name)).run([])
          provider.teardown(vm)
        else
          puts "Not running"
        end
      end
      
      def self.additional_options(x)
      end
      
    end
  end
end

Salt.register_command "teardown", Salt::Commands::Teardown