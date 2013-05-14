module Salt
  module Commands
    class Upload < BaseCommand
      def run(args=[])
        vm = find name
        localpath   = local || File.join(Dir.pwd, "deploy", "salt")
        remotepath  = remote || "/srv/salt"
        system sudo_cmd(vm, "sudo mkdir -p #{remotepath} && sudo chown #{user} #{remotepath}")
        system rsync_cmd(vm, localpath, remotepath)
      end
      
      def self.additional_options(x)
        x.on("-l", "--local <directory>", "Local directory") {|n| config[:local] = n}
        x.on("-r", "--remote <directory>", "Remote directory") {|n| config[:remote] = n}
      end
      
    end
  end
end

Salt.register_command "upload", Salt::Commands::Upload