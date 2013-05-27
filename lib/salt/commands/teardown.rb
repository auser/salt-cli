require 'fog'

module Salt
  module Commands
    class Teardown < BaseCommand
      def run(args=[])
        vm = find name
        unless vm
          puts "Machine not found or not running: #{name}"
          return
        end
        if vm.state == :running
          require_confirmation! <<-EOE
          Are you sure you want to teardown the machine #{name}.
          This <%= color('cannot', RED) %> be undone
          EOE
          provider.teardown(vm)
          if name != "#{environment}-master"
            Salt::Commands::Key.new(provider, config.merge(delete: true, name: name)).run([])
            salt_cmd master_server, 'data.clear'
          end
          destroy_security_group! if security_group
        else
          puts "Not running"
        end
      end
      
      def self.additional_options(x)
      end
      
      def destroy_security_group!
        security_group.destroy
      end
      
      def security_group
        @security_group ||= compute.security_groups.get("#{name}-#{aws[:keyname]}")
      end
      
    end
  end
end

Salt.register_command "teardown", Salt::Commands::Teardown