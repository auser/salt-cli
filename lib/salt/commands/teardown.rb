require 'fog'

module Salt
  module Commands
    class Teardown < BaseCommand
      def run(args=[])
        if all
          teardown_all!
        else
          teardown_single!(name)
        end
        cleanup! if cleanup
      end
      
      def teardown_all!
        provider.running_list.each do |m|
          teardown_single! m.name unless m.name == "#{environment}-master"
        end
        teardown_single!("#{environment}-master")
      end
      
      def teardown_single!(name)
        vm = find name
        if vm
          if vm.state == :running
            unless force_yes
              require_confirmation! <<-EOE
              Are you sure you want to teardown the machine #{name}.
              This <%= color('cannot', RED) %> be undone
              EOE
            end
            provider.teardown(vm)
            if name != "#{environment}-master"
              Salt::Commands::Key.new(provider, config.merge(delete: true, name: name)).run([])
            end
          else
            puts "Machine not found or not running: #{name}"
          end
        else
          puts "Not running"
        end
      end
      
      def cleanup!
        provider.cleanup!
      end
      
      def self.additional_options(x)
        x.on('-y', '--yes', "Answer yes to all questions") {config[:force_yes] = true}
        x.on('-a', '--all', "Teardown all running nodes") {config[:all] = true}
        x.on('--clean', "Cleanup all security groups") {config[:cleanup] = true }
      end
      
    end
  end
end

Salt.register_command "teardown", Salt::Commands::Teardown