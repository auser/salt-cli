module Salt
  class AddRole < Base

    def run
      ssh_cmd "salt-call grains.setval role [#{roles}]"
    end

  end
end
