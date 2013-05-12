module Salt
  module SSH
    
    def salt_cmd(vm, cmd)
      salt_cmd = (vm.name.to_s == "master") ? "salt '#{pattern}'" : "salt-call"
      cmd = sudo_cmd(vm, [salt_cmd, cmd].join(" "))
      puts "Running: #{cmd}" if debug
      `#{cmd}`
    end
    
    def sudo_cmd(vm, cmd)
      ssh_cmd(vm, "sudo #{cmd}")
    end
    
    def rsync_cmd(vm, local_path, remote_path)
      [
        rsync_opts(vm).flatten, local_path, "#{ssh_host_port(vm)}:#{remote_path}"
      ].flatten.join(' ')
    end
    
    def ssh_cmd(vm, cmd)
      [_ssh_cmd(vm), "\"#{cmd}\""].flatten.join(' ')
    end
    
    def _ssh_cmd(vm)
      ['ssh', ssh_opts(vm), ssh_host_port(vm)].flatten.join(' ')
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
        "#{debug ? "-v" : ""}",
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