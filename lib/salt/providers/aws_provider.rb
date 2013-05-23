require 'vagrant'
require 'pp'

module Salt
  module Providers
    class AwsProvider < BaseProvider
      
      # Launch
      def launch(vm)
        unless security_group
          create_security_group! do |group|
            group.authorize_port_range(22..22)
            group.authorize_port_range(4505..4506)
          end
        end
        
        ## Open any ports if necessary
        to_open_ports.each do |port|
          puts "  authorizing security group port #{port}" if debug_level
          security_group.authorize_port_range(Range.new(port, port)) unless current_open_ports.include?(port)
        end
        
        [current_open_ports - to_open_ports].flatten.each do |port|
          puts "  revoking security group port #{port}" if debug_level
          security_group.revoke_port_range(Range.new(port, port))
        end
        
        flavor_id = machine_config_or_default(:flavor)
        image_id = machine_config_or_default(:image_id)
        
        opts = {
          username: 'ubuntu',
          private_key_path: build_keypath,
          public_key_path: "#{build_keypath}.pub",
          tags: {name: name, environment: environment},
          security_groups: [security_group.name],
          flavor_id: flavor_id,
          image_id: image_id
        }
        
        puts "launching.."
        pp opts
        compute.servers.bootstrap(opts)
        ## Need to support private ips on ec2
      end
      
      def teardown(vm)
        vm.raw.destroy if vm.raw.ready?
      end
      
      ## Find a vm named
      def find(name)
        list.select do |vm|
          vm.name.to_s.index(name.to_s) && vm.running?
        end.first
      end
      
      ## List of the vm objects
      def list
        @list ||= raw_list.map do |vm|
          Machine.new({
            state: vm.state.to_sym,
            name: vm.tags["name"],
            user: user,
            dns: vm.dns_name,
            public_ip: vm.public_ip_address,
            private_ip: vm.private_ip_address,
            preferred_ip: vm.private_ip_address,
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
      def security_group
        @security_group ||= compute.security_groups.get("#{name}-#{aws[:keyname]}")
      end
      ### Just a small helper to compute the available ports
      def current_open_ports
        tcp_ports = []
        security_group.ip_permissions.each do |hsh|
          proto, from, to = hsh['ipProtocol'], hsh['fromPort'], hsh['toPort']
          tcp_ports.push Range.new(from, to).to_a
        end
        tcp_ports.flatten
      end
      def create_security_group!(&block)
        group = compute.security_groups.new({name: "#{name}-#{aws[:keyname]}",
                                    description: "#{name} group for #{aws[:keyname]}"})
        group.save
        yield(group) if block_given?
      end
      def to_open_ports
        all_ports = []
        all_ports << machine_config[:default][:ports].flatten if machine_config.has_key?(:default)
        all_ports << machine_config[real_name][:ports].flatten if machine_config.has_key?(real_name)
        all_ports.flatten
      end
      def real_name
        name.split('-')[-1].to_sym
      end
      def machine_config_or_default(field)
        if machine_config[real_name] && machine_config[real_name].has_key?(field)
          machine_config[real_name][field]
        else
          machine_config[:default][field]
        end
      end
      def machine_config
        @machine_config ||= config[:aws][:machines] || {}
      end
      def compute
        Fog.credential = aws[:keyname] if aws.has_key?(:keyname)
        @compute ||= Fog::Compute.new({provider: "AWS",
                                      aws_access_key_id: aws_access_key_id,
                                      aws_secret_access_key: aws_secret_access_key})
      end
      def reset!
        @list = nil
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