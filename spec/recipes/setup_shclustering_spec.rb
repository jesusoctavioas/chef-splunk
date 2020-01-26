require 'spec_helper'

describe 'chef-splunk::setup_shclustering' do
  let(:splunk_local_dir) { '/opt/splunk/etc/apps/0_autogen_shcluster_config/local' }
  let(:server_conf_file) { "#{splunk_local_dir}/server.conf" }

  let(:vault_item) do
    { 'auth' => 'admin:notarealpassword', 'secret' => 'notarealsecret' }
  end

  let(:deployer_node) do
    stub_node(platform: 'ubuntu', version: '16.04') do |node|
      node.automatic['fqdn'] = 'deploy.cluster.example.com'
      node.automatic['ipaddress'] = '192.168.0.10'
      node.force_default['dev_mode'] = true
      node.force_default['splunk']['is_server'] = true
      node.force_default['splunk']['shclustering']['enabled'] = true
      node.force_default['splunk']['accept_license'] = true
    end
  end

  context 'search head deployer' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new do |node|
        node.force_default['dev_mode'] = true
        node.force_default['splunk']['is_server'] = true
        node.force_default['splunk']['shclustering']['enabled'] = true
        node.force_default['splunk']['accept_license'] = true
        node.force_default['splunk']['shclustering']['mode'] = 'deployer'
      end.converge(described_recipe)
    end

    before do
      allow_any_instance_of(Chef::Recipe).to receive(:chef_vault_item).and_return(vault_item)
    end

    it_behaves_like 'common server.conf settings'
    !it_behaves_like 'a search head cluster member'
    !it_behaves_like 'a search head captain'
  end

  context 'search head cluster member settings' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new do |node|
        node.force_default['dev_mode'] = true
        node.force_default['splunk']['is_server'] = true
        node.force_default['splunk']['shclustering']['enabled'] = true
        node.force_default['splunk']['accept_license'] = true
        node.force_default['splunk']['shclustering']['deployer_url'] = "https://#{deployer_node['fqdn']}:8089"
        node.force_default['splunk']['shclustering']['mode'] = 'member'
        node.force_default['splunk']['shclustering']['mgmt_uri'] = "https://#{node['fqdn']}:8089"
        node.force_default['splunk']['shclustering']['shcluster_members'] = [
          'https://shcluster-member01:8089',
          'https://shcluster-member02:8089',
          'https://shcluster-member03:8089',
        ]
        allow_any_instance_of(::File).to receive(:exist?).and_call_original
        allow_any_instance_of(::File).to receive(:exist?)
          .with('/opt/splunk/etc/.setup_shcluster').and_return(false)
      end.converge(described_recipe)
    end

    before do
      allow_any_instance_of(Chef::Recipe).to receive(:chef_vault_item).and_return(vault_item)
    end

    !it_behaves_like 'common server.conf settings'
    it_behaves_like 'a search head cluster member'
    !it_behaves_like 'a search head captain'
  end

  context 'search head captain' do
    ChefSpec::ServerRunner.new do |node|
      node.force_default['dev_mode'] = true
      node.force_default['splunk']['is_server'] = true
      node.force_default['splunk']['shclustering']['enabled'] = true
      node.force_default['splunk']['accept_license'] = true
      node.force_default['splunk']['shclustering']['deployer_url'] = "https://#{deployer_node['fqdn']}:8089"
      node.force_default['splunk']['shclustering']['mgmt_uri'] = "https://#{node['fqdn']}:8089"
      node.force_default['splunk']['shclustering']['mode'] = 'captain'
      node.force_default['splunk']['shclustering']['shcluster_members'] = [
        'https://shcluster-member01:8089',
        'https://shcluster-member02:8089',
        'https://shcluster-member03:8089',
      ]
      allow_any_instance_of(::File).to receive(:exist?).and_call_original
      allow_any_instance_of(::File).to receive(:exist?)
        .with('/opt/splunk/etc/.setup_shcluster').and_return(false)
    end.converge(described_recipe)

    let(:shcluster_servers_list) do
      'https://shcluster-member01:8089,https://shcluster-member02:8089,https://shcluster-member03:8089'
    end

    !it_behaves_like 'common server.conf settings'
    !it_behaves_like 'a search head cluster member'
    it_behaves_like 'a search head captain'
  end
end
