# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'salt/version'

Gem::Specification.new do |spec|
  spec.name          = "salt-cli"
  spec.version       = Salt::VERSION
  spec.authors       = ["Ari Lerner"]
  spec.email         = ["arilerner@mac.com"]
  spec.description   = %q{A ruby gem for interacting with salt and a bunch of providers}
  spec.summary       = %q{A ruby gem for interacting with salt and providers, including vagrant and salt}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  #{spec}.add_development_dependency "bundler", "~> 1.3"
  #{spec}.add_development_dependency "rake"

  %w(bundler rake vagrant-hostmaster virtualbox sshkey).each do |gem|
    spec.add_development_dependency gem
  end

  %w(vagrant multi_json active_support highline trollop i18n fog).each do |gem|
    spec.add_dependency gem
  end
  
  spec.add_dependency "vagrant", "1.0.7"
  spec.add_dependency "net-scp", "~> 1.0.4"
  spec.add_dependency "net-ssh", "~> 2.2.2"

end
