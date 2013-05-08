#!/usr/bin/env ruby
require 'git-style-binary/command'

require 'salt'

GitStyleBinary.command do

  short_desc "Call highstate on a machine or on the cluster"
  banner <<-EOS
Usage: #{command.full_name} #{all_options_string} args
EOS
  opt :bootstrap,     "Bootstrap the machine", default: true
  opt :name,          "The name of the machine", default: ""
  opt :environment,   "The environment", default: "development"
  opt :role,          "Launch with the role", default: nil
  opt :debug,         "Set debugging on", default: false
  opt :command,       "Denote a command to run", default: nil

  run do |command|
    provider = Sin::Controller.all['joyent'].new
    provider.run! command.argv, command.opts
  end
end

