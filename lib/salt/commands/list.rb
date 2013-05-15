require 'fog'

module Salt
  module Commands
    class List < BaseCommand
      def run(args=[])
        provider.list.select do |m|
          all ? true : m.running?
        end.each do |m|
          puts machine_string(m)
        end
      end
      
      def machine_string(m)
        "---- #{m.name} ----
              Host: #{m.public_ips}
              User: #{m.user}
              Key: #{m.key}
              State: #{m.state}"
      end
      
      def self.additional_options(x)
        x.on("-a", "--all", "List all") {config[:all] = true}
      end
    end
  end
end

Salt.register_command "list", Salt::Commands::List