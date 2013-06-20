module Salt
  module Commands
    class Upload < BaseCommand
      def run(args=[])
        require_master_server!
        vm = find name
        localpath   = config[:local] || "#{File.join(Dir.pwd, "deploy")}/"
        remotepath  = config[:remote] || "/srv"
        dsystem sudo_cmd(vm, "sudo mkdir -p #{remotepath} && sudo chown #{vm.user} #{remotepath}")
        dsystem rsync_cmd(vm, localpath, remotepath)
        salt_cmd vm, 'saltutil.sync_all' if config[:sync]
      end
      
      def self.additional_options(x)
        x.on("-l", "--local <directory>", "Local directory") {|n| config[:local] = n}
        x.on("-r", "--remote <directory>", "Remote directory") {|n| config[:remote] = n}
        x.on('-s', '--sync', "Sync after upload") { config[:sync] = true }
      end
      
    end
  end
end

Salt.register_command "upload", Salt::Commands::Upload