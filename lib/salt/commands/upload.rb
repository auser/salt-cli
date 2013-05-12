module Salt
  class Upload < BaseCommand
    def run(args)
      vm = find_machine! name
      rsync_cmd
    end
  end
end
