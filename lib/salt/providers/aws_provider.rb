require 'vagrant'
require 'pp'

module Salt
  module Providers
    class AwsProvider < BaseProvider
      
      # Launch
      def launch(vm)
        create_security_group! unless security_group
        security_group.reload
        %w(tcp udp).each do |proto|
          security_group.revoke_port_range(1..65535, ip_protocol: proto)
        end
        
        ## Open any ports if necessary
        to_open_ports.each do |proto, ports|
          ports.each do |port|
            puts "  authorizing security group port #{proto} #{port}" if debug_level
            unless current_open_ports[proto.to_sym].include?(port)
              security_group.authorize_port_range(Range.new(port, port), {ip_protocol: proto})
            end
          end
        end
        # Grant access to all other of our ports
        all_other_security_groups.each do |sg|
          security_group.authorize_port_range(22..65535, {group: sg.name})
        end
        
        flavor_id = machine_config_or_default(:flavor)
        image_id = machine_config_or_default(:image_id)
        
        opts = {
          username: 'ubuntu',
          private_key_path: build_keypath,
          public_key_path: "#{build_keypath}.pub",
          tags: {name: name, environment: environment},
          groups: [security_group.name],
          flavor_id: flavor_id,
          image_id: image_id
        }
        
        puts "launching.."
        pp opts
        compute.servers.bootstrap(opts)
        reset!
        ## Need to support private ips on ec2
      end
      
      def teardown(vm)
        vm.raw.destroy if vm.raw.ready?
        destroy_security_group!
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
      def all_other_security_groups
        running_list.map do |vm|
          compute.security_groups.get("#{vm.name}-#{aws[:keyname]}") unless vm.name.to_s.index(name)
        end.compact
      end
      ### Just a small helper to compute the available ports
      def current_open_ports
        tcp_ports = []
        udp_ports = []
        security_group.ip_permissions.each do |hsh|
          proto, from, to = hsh['ipProtocol'], hsh['fromPort'], hsh['toPort']
          case proto
          when 'tcp'
            tcp_ports.push Range.new(from, to).to_a
          when 'udp'
            udp_ports.push Range.new(from, to).to_a
          end
        end
        {tcp: tcp_ports.flatten, udp: udp_ports.flatten}
      end
      #### TCP
      def create_security_group!(&block)
        group = compute.security_groups.new({name: "#{name}-#{aws[:keyname]}",
                                    description: "#{name} group for #{aws[:keyname]}"})
        group.save
        group
      end
      def destroy_security_group!
        compute.security_groups.get(security_group.name).destroy rescue nil
      end
      def to_open_ports
        all_ports = {
          udp: [],
          tcp: [22]
        }
        [:default, real_name].each do |level|
          if machine_config[level.to_sym].has_key?(:ports)
            (machine_config[level.to_sym][:ports] || []).each do |pr, ports|
              (ports || []).each {|port| all_ports[pr] << port }
            end
          end
        end
        all_ports
      end
      def real_name
        name.split('-')[-1].to_sym
      end
      def machine_config_or_default(field)
        if machine_config[real_name] && machine_config[real_name].has_key?(field)
          machine_config[real_name][field]
        else
          machine_config[:default].has_key?(field) ? machine_config[:default][field] : nil
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
        @list = @security_group = @compute = nil
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