require 'fog'

module Salt
  module Commands
    class List < BaseCommand
      def run(args)
        str = provider.list.map do |env|
          "---- #{env.name} ----
      Host: #{env.config.ssh.host}
      Port: #{env.config.ssh.port}
      Key: #{env.env.default_private_key_path}
      State: #{env.state}"
        end
        puts str
      end
    end
  end
end

Salt.register_command "list", Salt::Commands::List