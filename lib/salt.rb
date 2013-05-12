$:.unshift(File.dirname(__FILE__))
require 'active_support/core_ext'
require 'fog'
require 'yaml'
require 'pp'
require 'optparse'

require "salt/version"
require 'salt/errors/unimplemented_error'
require 'salt/errors/invalid_arguments_error'

environment = ENV['RAILS_ENV'] || ENV['RACK_ENV'] || ENV['NODE_ENV'] || 'development'

module Salt
  def self.run_provider_command(provider, cmd, args)
    cmd = get_command(cmd)
    if cmd
      cmd.run_command(provider, args)
    else
      puts <<-EOE
Unknown command!

Available commands:
  #{Salt.all_commands.map {|k,_| k }.join("\n  ")}
      EOE
    end
  end
  def self.default_config
    @config ||= {
      pattern: '*',
      ip: ENV["SALTMASTER"],
      key: ENV["SALTKEY"],
      name: "master",
      provider: "AWS"
    }
  end
  def self.read_config(f, opts={})
    YAML.load(ERB.new(open(f).read).result(opts))
  end
  def self.root_dir
    @root_dir ||= File.expand_path(Dir.pwd)
  end
  def self.salt_dir
    @salt_dir ||= File.join(root_dir, "salt")
  end
  def self.bootstrap_dir
    @bootstrap_dir ||= File.join(salt_dir, "bootstrap")
  end
  def self.get_command(name)
    all_commands[name]
  end
  def self.register_command(name, kls)
    all_commands[name] = kls
  end
  def self.all_commands
    @all_commands ||= {}
  end
  def self.get_provider(name)
    all_providers[name]
  end
  def self.register_provider(name, kls)
    all_providers[name] = kls
  end
  def self.all_providers
    @all_providers ||= {}
  end
end

require 'salt/base_provider'
require 'salt/base_command'