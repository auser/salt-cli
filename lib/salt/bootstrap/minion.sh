#!/bin/bash

LOC=${1:-vagrant}
HOSTNAME=${2:-minion}
SALT_MASTER=${3:-192.168.98.11}
ENV=${4:-development}

echo "------> Bootstrapping minion $HOSTNAME (master: $SALT_MASTER) for environment $ENV"

__apt_get_noinput() {
    apt-get install -y -o DPkg::Options::=--force-confold $@
}

apt-get update
__apt_get_noinput python-software-properties curl debconf-utils
apt-get update

# Set the hostname
echo """
127.0.0.1       localhost   $HOSTNAME
$SALT_MASTER    saltmaster

# The following lines are desirable for IPv6 capable hosts
::1 ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts

""" > /etc/hosts
echo "$HOSTNAME" > /etc/hostname
hostname `cat /etc/hostname`

# We're using the saltstack canonical bootstrap method here to stay with the
# latest open-source efforts
#
# Eventually, we can come to settle down on our own way of bootstrapping
\curl -L http://bootstrap.saltstack.org | sudo sh -s -- stable

# Set salt master location and start minion
echo """
master: saltmaster
id: $HOSTNAME
grains:
  environment: $ENV
  location: $LOC
""" > /etc/salt/minion

sudo /etc/init.d/salt-minion restart

echo "------> The minion is booted and waiting for approval
Log in to the master machine and accept the key"

