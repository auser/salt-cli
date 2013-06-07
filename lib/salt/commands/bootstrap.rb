module Salt
  module Commands
    class Bootstrap < BaseCommand

      def run(args=[])
        vm = find name
        bname = name == "#{environment}-master" ? "master" : "minion"
        localpath = File.join(Salt.bootstrap_dir, "#{bname}.sh")
        remotepath = "/tmp/#{bname}.sh"
        system rsync_cmd(vm, localpath, remotepath)
        
        index = provider.running_list.size
        
        if name == "#{environment}-master" 
          cmd = "sudo /bin/sh #{remotepath} #{provider.to_s} #{environment}"
        else
          rs = roles ? roles.join(",") : ""
          cmd = "sudo /bin/sh #{remotepath} #{provider.to_s} #{name} #{master_server.preferred_ip} #{environment} #{index} #{rs}"
        end
        
        debug cmd
        IO.popen(sudo_cmd(vm, cmd)) do |d|
          while line = d.gets
            puts line if debug_level
          end
        end
      end

      def self.additional_options(x)
        x.on("-m", "--command <command>", "Command to run") {|n| config[:command] = n}
        x.on("-r", "--roles <roles>", "Roles") {|n| config[:roles] = n}
      end

    end
  end
end

Salt.register_command "bootstrap", Salt::Commands::Bootstrap