# Salt

Opinionated salt-stack deployment

## Installation

    $ gem install salt

## Usage

SaltCli is an opinionated salt stack deployment. If you don't like it, make one for yourself :).

SaltStack provides a developer the ability to write salt stack states once and deploy them to various cloud providers with the same workflow.

By defining a `salt-cloud.yml` file (or a Vagrantfile, for vagrant), you can easily launch instances in the "cloud" ready to be deployed and highstated. 

#### Current providers supported:

* aws
* vagrant

#### Available commands

* list
* launch
* bootstrap
* teardown
* ssh
* key
* role
* command
* run
* upload
* upgrade
* highstate

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
