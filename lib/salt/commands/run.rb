module Salt
  module Commands
    class Run < BaseCommand

      def run(args=[])
        require_master_server!
        vm = find name
        cmd = sudo_cmd(vm, ["salt-run", command].join(" "))
        dsystem(cmd)
      end

      def self.additional_options(x)
        x.on("-m", "--command <command>", "Command to run") {|n| config[:command] = n}
      end

    end
  end
end

Salt.register_command "run", Salt::Commands::Run
