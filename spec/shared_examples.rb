shared_examples 'common server.conf settings' do
  let(:splunk_local_dir) { '/opt/splunk/etc/apps/0_autogen_shcluster_config/local' }
  let(:server_conf_file) { "#{splunk_local_dir}/server.conf" }

  it 'writes server.conf with a shclustering stanza' do
    expect(chef_run).to render_file(server_conf_file)
      .with_content('[shclustering]')
  end

  it 'writes server.conf with the shcluster label' do
    expect(chef_run).to render_file(server_conf_file)
      .with_content("shcluster_label = #{chef_run.node['splunk']['shclustering']['label']}")
  end

  it 'writes server.conf with the shcluster secret' do
    expect(chef_run).to render_file(server_conf_file)
      .with_content('pass4SymmKey = notarealsecret')
  end
end

shared_examples 'a search head cluster member' do
  it 'executes initialize shcluster member command' do
    expect(chef_run).to_not run_execute('initialize search head cluster member')
  end

  it 'creates /opt/splunk/etc/.setup_shcluster' do
    expect(chef_run).to_not create_file('/opt/splunk/etc/.setup_shcluster')
  end
end

shared_examples 'a search head captain' do
  it 'executes bootstrap sh-captain command' do
    expect(chef_run).to_not run_execute('bootstrap-shcluster-captain')
  end

  it 'creates /opt/splunk/etc/.setup_shcluster' do
    expect(chef_run).to_not create_file('/opt/splunk/etc/.setup_shcluster')
  end
end

shared_examples 'splunk daemon' do
  it 'created the service[splunk] resource' do
    expect(chef_run).to start_service('splunk')
    expect(chef_run).to enable_service('splunk')
  end
end
