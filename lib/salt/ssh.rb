module Salt
  module SSH
    
    def salt_cmd(vm, cmd)
      salt_cmd = (vm.name.to_s == "#{environment}-master") ? "salt '#{pattern}'" : "salt-call"
      cmd = sudo_cmd(vm, [salt_cmd, cmd].join(" "))
      dsystem(cmd)
    end
    
    def sudo_cmd(vm, cmd)
      ssh_cmd(vm, "sudo #{cmd}")
    end
    
    def rsync_cmd(vm, local_path, remote_path)
      [
        rsync_opts(vm).flatten, "#{local_path}", "#{ssh_host_port(vm)}:#{remote_path}"
      ].flatten.join(' ')
    end
    
    def ssh_cmd(vm, cmd)
      [_ssh_cmd(vm), "\"#{cmd.gsub(/"/, '\"')}\""].flatten.join(' ')
    end
    
    def _ssh_cmd(vm)
      ['ssh', ssh_opts(vm), ssh_host_port(vm)].flatten.join(' ')
    end
    
    def ssh_host_port(vm)
      "#{vm.user || 'root'}@#{vm.public_ip}"
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
        "#{debug_level ? "-v" : ""}",
        "-e \"ssh #{ssh_opts(vm).join(' ')}\""
      ]
    end

    def _ssh(vm, commands)

      [*commands].each do |command|
        c = ssh_cmd vm, "#{command.strip.gsub(/"/, '')}"
        
        dsystem(c)
      end
    end
    
    def dsystem(cmd)
      if debug_level
        puts "Running: #{cmd}"
        IO.popen(cmd,:err => [:child, :out]) do |d|
          while line = d.gets
            puts line
          end
        end
      else
        system(cmd)
      end
    end

  end
end