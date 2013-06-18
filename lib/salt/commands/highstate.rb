module Salt
  module Commands
    class Highstate < BaseCommand
      def run(args=[])
        require_master_server!
        Salt::Commands::Upload.new(provider, config.merge(name: "master")).run([])
        vm = find name
        salt_cmd vm, 'saltutil.sync_all'
        salt_cmd vm, 'mine.update'
        opts = {}
        opts.merge!({'b' => batch_size}) if batch_size
        salt_cmd vm, "state.highstate", opts
      end
      
      def self.additional_options(x)
        x.on("-b", "--batch <size>", "Batch size can be a number or percentage") {|n| config[:batch_size] = n}
      end
      
    end
  end
end

Salt.register_command "highstate", Salt::Commands::Highstate