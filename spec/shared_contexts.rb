shared_context 'command stubs' do
  before(:each) do
    stubs_for_resource('execute[initialize search head cluster member]') do |resource|
      allow(resource).to receive_shell_out('/opt/splunk/bin/splunk list shcluster-member-info -auth admin:notarealpassword')
    end
    stubs_for_resource('execute[add member to search head cluster]') do |resource|
      allow(resource).to receive_shell_out('/opt/splunk/bin/splunk list shcluster-member-info -auth admin:notarealpassword')
    end
    stubs_for_resource('execute[search head cluster integration with indexer cluster]') do |resource|
      allow(resource).to receive_shell_out('/opt/splunk/bin/splunk list search-server -auth admin:notarealpassword')
    end
    stubs_for_resource('service[splunk]') do |resource|
      allow(resource).to receive_shell_out("ps -ef|grep splunk|grep -v grep|awk '{print$1}'|uniq")
    end
  end
end
