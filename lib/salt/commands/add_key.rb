module Salt
  module Commands
    class AddKey < BaseCommand

      def run(args)
        master = master_server
        vm = find_machine! name
        if current_accepted_keys.include?(name) && !force
          puts "Already accepted..."
        else
          if force && current_accepted_keys.include?(name)
            puts "Removing key..."
            `#{sudo_cmd(master_server, "salt-key --yes -d #{name}")}`
          end
          
          unless currently_pending_keys.include?(name)
            `#{sudo_cmd vm, "restart salt-minion"}`
          end
          
          sudo_cmd(master_server, "salt-key --yes -a #{name}")
          sleep 2
          sudo_cmd master_server, "salt-key --yes -a #{name}"
        end
      end
      
      def current_accepted_keys
        @current_accepted_keys ||= `#{sudo_cmd(master_server, "salt-key -l accepted")}`.split("\n")[1..-1]
      end
      
      def currently_pending_keys
        currently_pending_keys ||= `#{sudo_cmd(master_server, "salt-key -l pre")}`.split("\n")[1..-1]
      end

      def self.additional_options(x)
        x.on('-f', "--force", "Force update key") {|n| config[:force] = true}
      end

    end
  end
end

Salt.register_command "add_key", Salt::Commands::AddKey