require 'ostruct'

module Salt
  # Base command
  class Base < OpenStruct
    def run
      raise "Not implemented"
    end

    def ssh_cmd(opts={})
      puts _ssh_cmd(opts)
    end

    # TODO: Refactor
    def _ssh_cmd(opts={})
      base_cmd = ['ssh', ssh_opts(opts), "#{opts[:username] || 'root'}@#{opts[:ip]}" ]
      if opts[:command]
        base_cmd << opts[:command]
      end
      base_cmd.flatten.join(' ')
    end

    def ssh_opts
      [
        '-p', (port || 22).to_s,
        '-o', 'LogLevel=FATAL',
        '-o', 'StrictHostKeyChecking=no',
        '-o', 'UserKnownHostsFile=/dev/null',
        '-o', 'ForwardAgent=yes',
        '-i', "'#{keypath || "#{ENV["HOME"]}/.ssh/id_rsa"}'"
      ]
    end

    def _ssh(commands, &block)

      [*commands].each do |command|
        c = _ssh_cmd opts.merge(:command => "'#{command.strip}'")

        dsystem(c, opts)
      end
    end

    def sudo_ssh(commands, opts, &blk)
      sudo_commands = []
      [*commands].each do |command|
        sudo_commands << "sudo #{command.strip}"
      end
      _ssh(sudo_commands, opts, &blk)
    end

    def dsystem(cmd, opts={})
      dputs "Running #{cmd}", opts
      system(cmd)
    end
  end
end
