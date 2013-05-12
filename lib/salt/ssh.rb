module Salt
  module SSH
    
    def salt_cmd(vm, cmd)
      salt_cmd = vm.name == "master" ? "salt '#{pattern}'" : "salt-call"
      sudo_cmd(vm, [salt_cmd, cmd].join(" "))
    end
    
    def sudo_cmd(vm, commands)
      sudo_commands = []
      [*commands].each do |command|
        sudo_commands << "sudo #{command.strip}"
      end
      _ssh(vm, sudo_commands)
    end
    
    def rsync_cmd(vm, local, remote)
      cmd = [
        rsync_opts(vm).flatten, local_path, "#{ssh_host_port}:#{remote_path}"
      ].flatten
      cmd
    end
    
    def ssh_cmd(vm, cmd)
      ['ssh', ssh_opts(vm), 
        ssh_host_port(vm), "\"#{cmd}\""
      ].flatten.join(' ')
    end
    
    def ssh_host_port(vm)
      "#{vm.user || 'root'}@#{vm.public_ips[0]}"
    end

    def ssh_opts(vm)
      [
        '-p', (vm.port || 22).to_s,
        '-o', 'LogLevel=FATAL',
        '-o', 'StrictHostKeyChecking=no',
        '-o', 'UserKnownHostsFile=/dev/null',
        '-o', 'ForwardAgent=yes',
        '-i', "'#{vm.key || "#{ENV["HOME"]}/.ssh/id_rsa"}'"
      ]
    end
    
    def rsync_opts(vm)
      [
        "rsync", "-az",
        "#{opts[:debug] ? "-v" : ""}",
        "-e 'ssh #{ssh_opts(vm).join(' ')}'"
      ]
    end

    def _ssh(vm, commands)

      [*commands].each do |command|
        c = ssh_cmd vm, "#{command.strip.gsub(/"/, '')}"
        
        system(c)
      end
    end

  end
end