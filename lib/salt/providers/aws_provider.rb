require 'vagrant'

module Salt
  module Providers
    class AwsProvider < BaseProvider
      
      # Launch
      def launch(vm)
        opts = {
          username: 'ubuntu',
          private_key_path: build_keypath,
          public_key_path: "#{build_keypath}.pub",
          tags: {name: name},
        }
        compute.servers.bootstrap(opts)
      end
      
      def teardown(vm)
        vm.raw.destroy if vm.raw.ready?
      end
      
      ## Find a vm named
      def find(name)
        list.select do |vm|
          vm.name.to_s.index(name.to_s)
        end.first
      end
      
      ## List of the vm objects
      def list
        @list ||= raw_list.map do |vm|
          Machine.new({
            state: vm.state.to_sym,
            name: vm.tags["name"],
            user: user,
            public_ips: [vm.public_ip_address],
            private_ips: [vm.private_ip_address],
            key: build_keypath,
            raw: vm
          })
        end
      end
      
      ###### PRIVATE
      private
      def build_keypath
        aws[:keyname] ? "#{ENV["HOME"]}/.ec2/#{aws[:keyname]}" : "#{ENV["HOME"]}/.ssh/id_rsa"
      end
      def raw_list
        compute.servers
      end
      def compute
        Fog.credential = aws[:keyname] if aws.has_key?(:keyname)
        @compute ||= Fog::Compute.new({provider: "AWS",
                                      aws_access_key_id: aws_access_key_id,
                                      aws_secret_access_key: aws_secret_access_key})
      end
      
      def aws_access_key_id
        ENV["AWS_ACCESS_KEY"] || aws[:access_key]
      end
      
      def aws_secret_access_key
        ENV["AWS_ACCESS_KEY"] || aws[:secret_key]
      end
      
    end
  end
end

Salt.register_provider "aws", Salt::Providers::AwsProvider