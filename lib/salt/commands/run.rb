module Salt
  module Commands
    class Run < BaseCommand

      def run(args=[])
        vm = find name
        cmd = sudo_cmd(vm, ["salt-run", command].join(" "))
        puts `#{cmd}`
      end

      def self.additional_options(x)
        x.on("-m", "--command <command>", "Command to run") {|n| config[:command] = n}
      end

    end
  end
end

Salt.register_command "run", Salt::Commands::Run
