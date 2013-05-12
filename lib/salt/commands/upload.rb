module Salt
  module Commands
    class Upload < BaseCommand
      def run(args=[])
        vm = find_machine! name
        localpath   = local || "."
        remotepath  = remote || "/srv/salt"
        cmd = rsync_cmd vm, localpath, remotepath
        puts cmd
        puts `#{cmd}`
      end
      
      def self.additional_options(x)
        x.on("-l", "--local <directory>", "Local directory") {|n| config[:local] = n}
        x.on("-r", "--remote <directory>", "Remote directory") {|n| config[:remote] = n}
      end
      
    end
  end
end

Salt.register_command "upload", Salt::Commands::Upload