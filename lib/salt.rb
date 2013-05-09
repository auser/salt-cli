$:.unshift(File.dirname(__FILE__))
require 'active_support/core_ext'
require 'fog'
require 'yaml'
require 'pp'
require 'optparse'

require "salt/version"
require 'salt/errors/unimplemented_error'
require 'salt/base_provider'
require 'salt/base_command'

environment = ENV['RAILS_ENV'] || ENV['RACK_ENV'] || ENV['NODE_ENV'] || 'development'

module Salt
  def self.get_command(cmd)
    Salt.const_get(cmd.classify)
  end
  def self.run_command(cmd, args)
    kls = get_command(cmd)
    kls.run_command(args)
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

  autoload :AddRole, 'salt/commands/add_role'
  autoload :Highstate, 'salt/commands/highstate'
  autoload :List, 'salt/commands/list'
end

