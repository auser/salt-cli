module Salt
  class AddRole < BaseCommand

    def run(args)
      raise "No roles given. Please pass roles to set" unless roles
      cmd = ssh_cmd "sudo salt '#{pattern}' grains.setval roles [#{roles}]"
      puts `#{cmd}`
    end

    def self.additional_options(x)
      x.on("-r", "--roles <roles>", "Roles") {|n| run_options[:roles] = n}
      x.on("-p", "--pattern <roles>", "Pattern to match") {|n| run_options[:pattern] = n}
    end

  end
end
