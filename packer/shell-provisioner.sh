# This script assumes running as 'root'

# Brightbox repo which hosts ruby packages
apt-get install -y software-properties-common
apt-add-repository -y ppa:brightbox/ruby-ng

# Update all packages
apt-get update -y

# Install ruby
apt-get install -y ruby1.8 ruby1.9.3 ruby2.2 ruby-switch
ruby-switch --set ruby2.2

# Install serverspec gem
gem install serverspec