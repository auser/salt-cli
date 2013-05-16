require 'vagrant'

module Salt
  module Providers
    class VagrantProvider < BaseProvider
      
      # Launch
      def launch(vm)
        vm = find name
        if vm.state == :running
          puts "The machine is already running. Not launching"
        else
          vm.raw.up
          reset!
        end
      end
      
      def teardown(vm)
        vm.raw.destroy
      end
      
      ## Find a vm named
      def find(name)
        list.select do |vm|
          vm.name.to_s.index(name.to_s)
        end.first
      end
      
      ## List of the vm objects
      def list
        @list ||= env.vms_ordered.map do |vm|
          Machine.new({
            state: vm.state,
            name: vm.name,
            user: vm.config.ssh.username,
            public_ip: Hash[vm.config.vm.networks][:hostonly].first,
            private_ip: Hash[vm.config.vm.networks][:private],
            preferred_ip: Hash[vm.config.vm.networks][:hostonly].first,
            key: vm.config.ssh.private_key_path || vm.env.default_private_key_path,
            raw: vm
          })
        end
      end
      
      ###### PRIVATE
      private
      def reset!
        @list = nil
      end
      def env
        @env = ::Vagrant::Environment.new
      end
      
    end
  end
end

Salt.register_provider "vagrant", Salt::Providers::VagrantProvider