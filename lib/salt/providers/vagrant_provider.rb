require 'vagrant'

module Salt
  module Providers
    class VagrantProvider < BaseProvider
      
      # Launch
      def launch(name)
        find(name).up
      end
      
      ## Find a vm named
      def find(name)
        list.select do |vm|
          vm.name.to_s.index(name)
        end.first
      end
      
      ## List of the vm objects
      def list
        @list ||= env.vms_ordered.map do |vm|
          Machine.new({
            state: vm.state,
            name: vm.name,
            user: vm.config.ssh.username,
            public_ips: Hash[vm.config.vm.networks][:hostonly],
            private_ips: Hash[vm.config.vm.networks][:private],
            key: vm.config.ssh.private_key_path || vm.env.default_private_key_path
          })
        end
      end
      
      ###### PRIVATE
      private
      def env
        @env = ::Vagrant::Environment.new
      end
      
    end
  end
end

Salt.register_provider "vagrant", Salt::Providers::VagrantProvider