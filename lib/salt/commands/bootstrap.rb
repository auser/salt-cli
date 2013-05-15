module Salt
  module Commands
    class Bootstrap < BaseCommand

      def run(args=[])
        vm = find name
        bname = name == "master" ? "master" : "minion"
        localpath = File.join(Salt.bootstrap_dir, "#{bname}.sh")
        remotepath = "/tmp/#{bname}.sh"
        system rsync_cmd(vm, localpath, remotepath)
        
        if name == "master" 
          cmd = "sudo /bin/sh #{remotepath} #{environment}"
        else 
          cmd = "sudo /bin/sh #{remotepath} #{name} #{master_server.preferred_ip} #{environment}"
        end
        
        IO.popen(sudo_cmd(vm, cmd)) do |d|
          while line = d.gets
            puts line
          end
        end
      end

      def self.additional_options(x)
        x.on("-m", "--command <command>", "Command to run") {|n| config[:command] = n}
      end

    end
  end
end

Salt.register_command "bootstrap", Salt::Commands::Bootstrap