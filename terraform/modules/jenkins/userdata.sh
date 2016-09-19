#!/bin/bash -v
apt-get update -y

# Install awscli
curl -O https://bootstrap.pypa.io/get-pip.py
python get-pip.py
pip install awscli

# Github private token
mkdir -p /var/lib/jenkins
/usr/local/bin/aws s3 cp --sse aws:kms s3://huy-chef/github_token /var/lib/jenkins/github_token

# Prep chef run
/usr/local/bin/aws s3 cp --sse aws:kms s3://huy-chef/devops-melbourne-validator.pem /etc/chef/
/usr/local/bin/aws s3 cp s3://huy-chef/client.rb /etc/chef/
curl -L https://omnitruck.chef.io/install.sh | sudo bash

# Execute chef with runlist to set up jenkins
chef-client -r "recipe[chef-client]"
chef-client -r "recipe[jenkins-wrapper]"
# Ran this cookbook a 2nd time because Jenkins cred can only be created after 1st restart
chef-client -r "recipe[jenkins-wrapper]" 