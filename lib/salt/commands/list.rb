require 'fog'

module Salt
  module Commands
    class List < BaseCommand
      def run(args=[])
        str = provider.list.map do |m|
          "---- #{m.name} ----
      Host: #{m.public_ips}
      User: #{m.user}
      Key: #{m.key}
      State: #{m.state}"
        end
        puts str
      end
    end
  end
end

Salt.register_command "list", Salt::Commands::List