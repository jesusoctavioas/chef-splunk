#
# Cookbook:: splunk
# Recipe:: setup_shclustering
#
# Author: Ryan LeViseur <ryanlev@gmail.com>
# Copyright:: (c) 2014-2019, Chef Software, Inc <legal@chef.io>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
unless enable_shclustering?
  Chef::Log.debug('The chef-splunk::setup_shclustering recipe was added to the node,')
  Chef::Log.debug('but the attribute to enable search head clustering was not set.')
  return
end

# during an initial install, the start/restart commands must deal with accepting
# the license. So, we must ensure the service[splunk] resource
# properly deals with the license; hence, the use of `#svc_command` method calls here.
edit_resource(:service, 'splunk') do
  action node['init_package'] == 'systemd' ? %i(start enable) : :start
  supports status: true, restart: true
  stop_command svc_command('stop')
  start_command svc_command('start')
  restart_command svc_command('restart')
  status_command svc_command('status')
  provider splunk_service_provider
end

passwords = chef_vault_item(node['splunk']['data_bag'], "splunk_#{node.chef_environment}")
splunk_auth_info = passwords['auth']
shcluster_secret = passwords['secret']

# create app directories to house our server.conf with our shcluster configuration
shcluster_app_dir = "#{splunk_dir}/etc/apps/0_autogen_shcluster_config"

directory shcluster_app_dir do
  owner splunk_runas_user
  group splunk_runas_user
  mode '755'
end

directory "#{shcluster_app_dir}/local" do
  owner splunk_runas_user
  group splunk_runas_user
  mode '755'
end

template "#{shcluster_app_dir}/local/server.conf" do
  source 'shclustering/server.conf.erb'
  mode '600'
  owner splunk_runas_user
  group splunk_runas_user
  variables(
    shcluster_params: node['splunk']['shclustering'],
    shcluster_secret: shcluster_secret
  )
  sensitive true
  notifies :restart, 'service[splunk]', :immediately
end

# finish here if the server is the Splunk Search Head deployer; otherwise, continue on
return if node['splunk']['shclustering']['mode'] == 'deployer'

# bootstrap the shcluster and the node as a captain if shclustering mode is set to 'captain'
shcluster_servers_list = []

# search for the fqdn of the search head deployer and set that as the deployer_url
# if one is not given in the node attributes
if node['splunk']['shclustering']['deployer_url'].empty?
  search(
    :node,
    "\
    splunk_shclustering_enabled:true AND \
    splunk_shclustering_label:#{node['splunk']['shclustering']['label']} AND \
    splunk_shclustering_mode:deployer AND \
    chef_environment:#{node.chef_environment}",
    filter_result: { 'deployer_fqdn' => ['fqdn'] }
  ).each do |fqdn|
    node.default['splunk']['shclustering']['deployer_url'] = fqdn
  end
end

# unless shcluster members are staticly assigned via the node attribute,
# try to find the other shcluster members via Chef search
if node['splunk']['shclustering']['mode'] == 'captain' &&
   node['splunk']['shclustering']['shcluster_members'].empty?
  search(
    :node,
    "\
    splunk_shclustering_enabled:true AND \
    splunk_shclustering_label:#{node['splunk']['shclustering']['label']} AND \
    chef_environment:#{node.chef_environment}"
  ).each do |result|
    shcluster_servers_list << result['splunk']['shclustering']['mgmt_uri']
  end
else
  shcluster_servers_list = node['splunk']['shclustering']['shcluster_members']
end

execute 'bootstrap-shcluster' do
  command "#{splunk_cmd} bootstrap shcluster-captain -servers_list '#{shcluster_servers_list.join(',')}' -auth '#{splunk_auth_info}'"
  sensitive true
  not_if { ::File.exist?("#{splunk_dir}/etc/.setup_shcluster") }
  only_if { node['splunk']['shclustering']['mode'] == 'captain' }
  notifies :restart, 'service[splunk]'
end

file "#{splunk_dir}/etc/.setup_shcluster" do
  content "true\n"
  owner splunk_runas_user
  group splunk_runas_user
  mode '600'
end
