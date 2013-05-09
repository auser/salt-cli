require 'fog'

module Salt
  class List < BaseCommand
    def run(args)
      p [:args, args]
    end
  end
end

