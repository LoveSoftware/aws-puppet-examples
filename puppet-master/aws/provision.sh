#!/bin/bash

# Compress apt indexes
cat <<EOF > /etc/apt/apt.conf.d/02compress-indexes
Acquire::GzipIndexes "true";
Acquire::CompressionTypes::Order:: "gz";
EOF

apt-get -y update
apt-get -y upgrade
apt-get -y install linux-headers-$(uname -r) build-essential
apt-get -y install zlib1g-dev libssl-dev libreadline-gplv2-dev libyaml-dev
apt-get -y install vim
apt-get -y install curl
apt-get -y install ruby rubygems ruby-dev augeas-tools libaugeas-dev libaugeas-ruby 

adduser --system --group --home /var/lib/puppet puppet

gem install puppet --no-ri --no-rdoc

apt-get clean
rm /var/lib/gems/1.9.1/cache/*

apt-get -y install ntp

echo '10.0.1.100 puppet' | cat - /etc/hosts > temp && sudo mv temp /etc/hosts