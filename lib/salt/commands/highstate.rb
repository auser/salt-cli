module Salt
  class Highstate < BaseCommand
    def run(args)
      if name != "master"
        cmd = "salt-call"
      else
        cmd = "salt '#{pattern}'"
      end
      cmd = ssh_cmd "sudo #{cmd} state.highstate"
      puts `#{cmd}`
    end
  end
end
