#
# Cookbook Name:: jenkins-wrapper
# Recipe:: default
#
# Copyright 2016 Huy Nguyen
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

include_recipe 'chef-client'
include_recipe 'chef-client::delete_validation'

# Install jenkins dependencies
package 'openjdk-7-jre'
include_recipe 'git'

# Set up one-node master
include_recipe 'jenkins::master'

# Install plugins
node['jenkins-wrapper']['plugins'].each do |plugin|
  jenkins_plugin plugin do
    notifies :restart, 'service[jenkins]'
  end
end

# Maintain perms on github private ssh key
file node['jenkins-wrapper']['github']['token_file'] do
  owner 'jenkins'
  group 'root'
  mode '0400'
end

# Create jenkins credential for github
jenkins_secret_text_credentials node['jenkins-wrapper']['github']['user'] do
  id node['jenkins-wrapper']['github']['credential_id']
  description "github.com/#{node['jenkins-wrapper']['github']['user']} token credential"
  secret File.read(node['jenkins-wrapper']['github']['token_file']).strip
  notifies :restart, 'service[jenkins]'
  notifies :run, 'execute[delete_github_secret]'
end

# Delete github_token secret
execute 'delete_github_secret' do
  command "rm -f #{node['jenkins-wrapper']['github']['token_file']}"
  only_if do ::File.exist?(node['jenkins-wrapper']['github']['token_file']) end
  action :nothing
end

# Create 'packer-build' job
directory File.join(node['jenkins']['master']['home'], 'jobs', 'packer-build') do
  owner node['jenkins']['master']['user']
  group node['jenkins']['master']['group']
end
template File.join(node['jenkins']['master']['home'], 'jobs', 'packer-build', 'config.xml') do
  source 'packer-build-config.xml.erb'
  owner node['jenkins']['master']['user']
  group node['jenkins']['master']['group']
  mode 0644
  variables(
    github_admins: node['jenkins-wrapper']['github']['admins'],
    github_repo: node['jenkins-wrapper']['github']['repo'],
    github_auth_id: node['jenkins-wrapper']['github']['github_auth_id']
  )
  notifies :restart, 'service[jenkins]'
end

# Create 'packer-promote' job
directory File.join(node['jenkins']['master']['home'], 'jobs', 'packer-promote') do
  owner node['jenkins']['master']['user']
  group node['jenkins']['master']['group']
end
template File.join(node['jenkins']['master']['home'], 'jobs', 'packer-promote', 'config.xml') do
  source 'packer-promote-config.xml.erb'
  owner node['jenkins']['master']['user']
  group node['jenkins']['master']['group']
  mode 0644
  variables(
    github_admins: node['jenkins-wrapper']['github']['admins'],
    github_repo: node['jenkins-wrapper']['github']['repo'],
    github_auth_id: node['jenkins-wrapper']['github']['github_auth_id']
  )
  notifies :restart, 'service[jenkins]'
end

# Settings for 'github pull request builder' plugin
template File.join(node['jenkins']['master']['home'], 'org.jenkinsci.plugins.ghprb.GhprbTrigger.xml') do
  source 'ghprb.xml.erb'
  owner node['jenkins']['master']['user']
  group node['jenkins']['master']['group']
  mode 0644
  variables(
    credential_id: node['jenkins-wrapper']['github']['credential_id'],
    github_auth_id: node['jenkins-wrapper']['github']['github_auth_id']
  )
end

# Make sure jenkins is started
service 'jenkins' do
  action :start
end

# Install Hashicorp Packer
remote_file "#{Chef::Config['file_cache_path']}/packer.zip" do
  source node['jenkins-wrapper']['packer']['source_url']
  checksum '7d51fc5db19d02bbf32278a8116830fae33a3f9bd4440a58d23ad7c863e92e28'
end
package 'unzip'
execute 'unpack packer' do
  command "unzip #{Chef::Config['file_cache_path']}/packer.zip -d /usr/bin"
  not_if do ::File.exist?('/usr/bin/packer') end
end
