require 'ostruct'

module Salt
  # Base command
  class BaseCommand < OpenStruct

    def run(args, opts={})
      raise "Not implemented"
    end

    def ssh_cmd(cmd, opts={})
      ['ssh', ssh_opts, "#{user || 'root'}@#{ip}", "\"#{cmd}\""].flatten.join(' ')
    end

    def ssh_opts
      [
        '-p', (port || 22).to_s,
        '-o', 'LogLevel=FATAL',
        '-o', 'StrictHostKeyChecking=no',
        '-o', 'UserKnownHostsFile=/dev/null',
        '-o', 'ForwardAgent=yes',
        '-i', "'#{key || "#{ENV["HOME"]}/.ssh/id_rsa"}'"
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

    def self.config
      @config ||= {
        pattern: '*',
        ip: ENV["SALTMASTER"],
        key: ENV["SALTKEY"],
        name: "master",
        config: load_config(File.join(Dir.pwd, "config.yml"))
      }
    end

    def self.run_command(args)
      op = option_parser
      additional_options(op)
      op.parse!(args)

      new(config).run(args)
    end

    def self.option_parser
      OptionParser.new do |x|
        x.banner = "#{self.class}"
        x.separator ''
        x.on("-c", "--config <name>", "config") do |n| 
          @config = load_config(n).merge(config)
        end
        x.on("-n", "--name <name>", "The name of the server") {|n| config[:name] = n}
        x.on("-i", "--ip <ip>", "The ip of the server") {|n| config[:ip] = n}
        x.on("-u", "--user <user>", "The username") {|n| config[:user] = n}
        x.on("-k", "--key <key>", "The key for the server") {|n| config[:key] = n}
        x.on("-p", "--pattern <roles>", "Pattern to match") {|n| config[:pattern] = n}
      end
    end
    def self.load_config(file)
      begin
        f = File.open(file, 'r') 
        YAML.load(ERB.new(f))
      rescue
      end
    end
    def self.additional_options(parser)
    end
  end
end
