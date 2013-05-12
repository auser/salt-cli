module Salt
  module Commands
    class Key < BaseCommand

      def run(args=[])
        master = master_server
        vm = find_machine! name
        if !delete && current_accepted_keys.include?(name) && !force
          puts "Already accepted..."
        else
          if force && current_accepted_keys.include?(name)
            delete_key!(vm)
          end
          
          if delete
            delete_key!(vm)
          else
            add_key!(vm)
          end
        end
      end
      
      def add_key!(vm)
        if current_accepted_keys.include?(name)
          puts `#{sudo_cmd master_server, "echo 'y' | sudo salt-key -d #{vm.name}"}`
        end
        
        unless currently_pending_keys.include?(name)
          puts `#{sudo_cmd vm, "restart salt-minion"}`
        end
        
        10.times {|i| print "."; sleep 1; }
        puts `#{sudo_cmd(master_server, "echo 'y' | sudo salt-key -a #{vm.name}")}`
      end
      
      def delete_key!(vm)
        `#{sudo_cmd(master_server, "echo 'y' | sudo salt-key -d #{vm.name}")}`
      end
      
      def current_accepted_keys
        @current_accepted_keys ||= `#{sudo_cmd(master_server, "salt-key -l accepted")}`.split("\n")[1..-1]
      end
      
      def currently_pending_keys
        currently_pending_keys ||= `#{sudo_cmd(master_server, "salt-key -l pre")}`.split("\n")[1..-1]
      end

      def self.additional_options(x)
        x.on('-f', "--force", "Force update key") {|n| config[:force] = true}
        x.on('--delete', "Delete the key") {|n| config[:delete] = true }
      end

    end
  end
end

Salt.register_command "key", Salt::Commands::Key