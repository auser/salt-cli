module Salt
  module Commands
    class Overstate < BaseCommand
      def run(args=[])
        require_master_server!
        Salt::Commands::Upload.new(provider, config.merge(name: "master")).run([])
        vm = find name
        salt_cmd vm, 'mine.update'
        opts = {}
        cmds = [
          "salt-run",
          "state.over"
        ]
        cmds << config[:run_env] if config.has_key?(:run_env)
        cmds << "/srv/salt/overstate.sls"
        dsystem("#{sudo_cmd master_server, cmds.join(" ")}")
      end
      
      def self.additional_options(x)
        x.on('-r', '--run <environment>', "Run this environment") {|n| config[:run_env] = n}
      end
      
    end
  end
end

Salt.register_command "overstate", Salt::Commands::Overstate