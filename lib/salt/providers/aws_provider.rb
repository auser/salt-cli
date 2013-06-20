require 'vagrant'
require 'pp'
require 'salt/debug'

module Salt
  module Providers
    class AwsProvider < BaseProvider
      include Debug
      
      # Launch
      def launch(vm, opts={})
        security_group = create_security_group! unless security_group
        security_group.reload if security_group
        %w(tcp udp).each do |proto|
          security_group.revoke_port_range(1..65535, ip_protocol: proto) rescue nil
        end
        
        debug "  running with #{security_group.name}"
        ## Open any ports if necessary
        to_open_ports(opts).each do |proto, ports|
          ports.each do |port|
            range = case port.class.to_s
            when "Fixnum"
              Range.new(port, port)
            when "String"
              e = port.split("..").map(&:to_i)
              Range.new e[0],e[1]
            end
            debug "  authorizing security group port #{proto} #{port}"
            unless current_open_ports[proto.to_sym].include?(port)
              security_group.authorize_port_range(range, {ip_protocol: proto}) rescue nil
            end
          end
        end

        # Grant access to all other of our ports
        all_other_security_groups.each do |sg|
          security_group.authorize_port_range(22..65535, {group: "'#{sg.name}'"}) rescue nil
        end
        
        flavor_id = opts[:flavor] || machine_config_or_default(:flavor)
        image_id = opts[:image_id] || machine_config_or_default(:image_id)
        
        opts = {
          username: 'ubuntu',
          private_key_path: build_keypath,
          public_key_path: "#{build_keypath}.pub",
          tags: {name: machine_name, environment: config[:environment]},
          groups: [security_group.name],
          flavor_id: flavor_id,
          image_id: image_id
        }
        opts.merge!(key_name: aws[:keyname]) if aws[:keyname]
        puts "Launching #{config[:name]} (#{machine_name})"
        p compute.servers.bootstrap(opts)
        ## Need to support private ips on ec2
      end
      
      def machine_name
        "#{config[:name] || 'master'}-#{config[:environment] || 'development'}"
      end
      
      def teardown(vm)
        vm.raw.destroy if vm.raw.ready?
        destroy_security_group!(security_group)
      end
      
      # Cleanup
      def cleanup!
        # Cleanup security_groups
        all_security_groups(false).each do |sg|
          debug "Cleaning up security group: #{sg.name}"
          destroy_security_group!(sg) if sg
        end
      end
      
      ## Find a vm named
      def find(name)
        list.select do |vm|
          p [:vm, vm.name, config[:name]] if vm.running?
          vm.name.to_s.index(config[:name].to_s) && vm.running?
        end.first
      end
      
      ## List of the vm objects
      def list
        @list ||= raw_list.map do |vm|
          if vm.tags && vm.tags['name'] && vm.tags['name'].index(config[:environment])
            Machine.new({
              state: vm.state.to_sym,
              name: vm.tags["name"],
              user: config[:user],
              dns: vm.dns_name,
              public_ip: vm.public_ip_address,
              private_ip: vm.private_ip_address,
              preferred_ip: vm.private_ip_address,
              key: build_keypath,
              raw: vm
            })
          end
        end.compact
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
        @security_group ||= compute.security_groups.get("#{config[:name]}-#{aws[:keyname]}")
      end
      def all_other_security_groups
        all_security_groups.reject {|sg| config[:name].to_s.index(sg.name) }
      end
      def all_security_groups(only_running=true)
        (only_running ? running_list : list).map do |vm|
          compute.security_groups.get("#{vm.name}-#{aws[:keyname]}")
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
        sg_name = "#{config[:name]}-#{aws[:keyname]}"
        debug "Creating security group #{sg_name}"
        group = compute.security_groups.new({name: sg_name,
                                    description: "#{config[:name]} group for #{aws[:keyname]}"})
        group.save rescue nil
        group
      end
      def destroy_security_group!(security_group)
        sg = compute.security_groups.get(security_group.name) rescue nil
      	unless sg.nil? || sg.name == "default"
      		sg.ip_permissions.each do |permission|
      			opts = {}
      			opts[:ip_protocol] = permission['ipProtocol'] if permission['ipProtocol'] && !permission['ipProtocol'].empty?
      			range = Range.new(permission['fromPort'],permission['toPort'])

      			if permission['groups'] && !permission['groups'].empty?
      				permission['groups'].each do |pgroup| 
      					sg.revoke_port_range(range, opts.merge(group: pgroup['groupName']))
      				end
      			else
      				sg.revoke_port_range(range, opts)
      			end
      		end

          begin
            sg.destroy
          rescue Exception => e
            puts "There was an error destroying the security_group: "
            puts e
          end
        end
      end
      def to_open_ports(opts)
        all_ports = {
          udp: [],
          tcp: [22]
        }
        [:default, real_name].each do |level|
          if machine_config[level.to_sym] && machine_config[level.to_sym].has_key?(:ports)
            (machine_config[level.to_sym][:ports] || []).each do |pr, ports|
              (ports || []).each {|port| all_ports[pr] << port }
            end
          end
        end
        if opts.has_key?(:ports)
          opts[:ports].each do |pr, ports|
            (ports || []).each {|port| all_ports[pr] << port}
          end
        end
        all_ports
      end
      def real_name
        config[:name].split('-')[-1].to_sym
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
      
      ## Build a compute object in fog
      def compute
        @compute ||= Fog::Compute.new({provider: "AWS",
                                      aws_access_key_id: aws_access_key_id,
                                      aws_secret_access_key: aws_secret_access_key})
        if aws.has_key?(:keyname)
          # aws[:keyname]
          Fog.credentials = Fog.credentials.merge({
              private_key_path: build_keypath, 
              public_key_path: "#{build_keypath}.pub"
          })
          @compute.import_key_pair(aws[:keyname], IO.read("#{build_keypath}.pub")) if @compute.key_pairs.get(aws[:keyname]).nil?
        end
        @compute
      end
      def reset!
        @list = @security_group = @compute = nil
      end
      
      def aws
        config[:aws] || {}
      end
      
      def aws_access_key_id
        ENV["AWS_ACCESS_KEY"] || aws[:access_key]
      end
      
      def aws_secret_access_key
        ENV["AWS_SECRET_ACCESS_KEY"] || aws[:secret_key]
      end
      
    end
  end
end

Salt.register_provider "aws", Salt::Providers::AwsProvider