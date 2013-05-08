require "salt/version"

require 'fog'
require 'yaml'
require 'pp'

environment = ENV['RAILS_ENV'] || ENV['RACK_ENV'] || ENV['NODE_ENV'] || 'development'

module Salt
  def self.root_dir
    @root_dir ||= File.expand_path(Dir.pwd)
  end
  def self.salt_dir
    @salt_dir ||= File.join(root_dir, "salt")
  end
  def self.bootstrap_dir
    @bootstrap_dir ||= File.join(salt_dir, "bootstrap")
  end
end

