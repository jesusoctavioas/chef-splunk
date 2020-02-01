# splunk CHANGELOG

This file is used to list changes made in each version of the splunk cookbook.

## 4.1.0 (TBD)
- Adds attribute `node['splunk']['shclustering']['app_dir']` to take the place of local ruby
  variable to set the search head clustering application directory.
- Uses the splunk CLI to add search head cluster members instead of the app server.conf file
  to ensure members are properly added. SH cluster members wait for the captain to converge.
- Search Head Captains will initialize as a search head cluster member and then bootstrap themselves
- Fixes issue [#137](https://github.com/chef-cookbooks/chef-splunk/issues/137)
    - Adds logic to skip any initialization or bootstrapping of search head cluster resources.
- Fixes issue [#138](https://github.com/chef-cookbooks/chef-splunk/issues/138)
    - Adds a new property to the `splunk_app` resource, called `template_variables`
- Fixes issue [#139](https://github.com/chef-cookbooks/chef-splunk/issues/139)
    - Adds `cookbook` property to the template declared in the `splunk_app` provider
- Fixes issue [#140](https://github.com/chef-cookbooks/chef-splunk/issues/140)
    - Adds back resource actions: :enable, :disable, :install, :remove
- Fixes issue [#141](https://github.com/chef-cookbooks/chef-splunk/issues/141)
    - `app_dir` property was added to the `splunk_app` resource
- Integrates a search head cluster to a single or multisite indexer cluster
- Adds helper method `#add_shcluster_member?` to indicate whether a search head cluster member needs to
  be added to the search head cluster
- Adds support for Hash when providing the `templates` property to the `splunk_app` resource
- Adds `:update` action to `splunk_app` resource

## 4.0.5 (2020-01-15)
- Adds a state file and a guard that ensures the `template[user-seed.conf]` resource is idempotent
- Fixes the shcluster-captain bootstrap command where `--servers_list` was provided a semi-colon separated
  list instead of a comma-separated list

## 4.0.4 (2020-01-14)
- Fixes [#134](https://github.com/chef-cookbooks/chef-splunk/issues/134)

## 4.0.3 (2020-01-02)
- Changes the chef-vault cookbook dependency to `~> 4.0`. This version of chef-vault skips the gem installation
  via the cookbook, because the gem is included out of the box in Chef Infra Client 13.4+.

## 4.0.2 (2020-01-02)
- Modifies the `chef-splunk::shclustering` to deploy a Splunk Search Head deployer
- Fixes a regression made by commit 26fa04d9: when `node['splunk']['runasroot']` is false,
  splunk isn't started with a non-root user or the startup scripts are not modified to allow
  for non-root splunk commands
- Properly stops and restarts the splunk daemon when the daemon needs to switch from running as root
  to a non-root user
- Sets the splunk user home directory to the appropriate path when `node['splunk']['is_server']` is true
- Stops the splunk service, if installed, before modifying the splunk user account settings
- ensures the splunk service resources are always starting the daemon
- Ensures the splunk daemon is always running as the correct user

## 4.0.1 (2019-12-19)
- Fixes [#130](https://github.com/chef-cookbooks/chef-splunk/issues/130)
  the `execute[update-splunk-mgmt-port]` resource passes splunk auth info to the `#current_mgmt_port` helper method
- cookstyle auto-correct
- deletes .foodcritic and .rubocop.yml files from the repo

## 4.0.0 (2019-12-16)

- Installs Enterprise Splunk 8.0.1
- Installs Splunk Universal Forwarder 8.0.1
- Removes unnecessary calls to `include_recipe 'chef-vault'`
- in `chef-splunk::client`, do not install the forwarder if the server config is being installed
  on a splunkd server
- adds helper method: `#server?` that will return true if the chef node is a splunkd server
- adds helper method: `#port_open?` that will return true if the local node has a specified port open
- logs a warning message if `node['splunk']['upgrade']['server_url']` or `node['splunk']['upgrade']['forwarder_url']` exist
- Splunk now generates its own scripts for boot starts; therefore this cookbook executes Splunk's `boot-start`
  command

## 3.1.1 (2019-12-05)

- Fixes [#125](https://github.com/chef-cookbooks/chef-splunk/issues/125) adds conditional expressions when `node['splunk']['setup_auth']`
is `false` to bypass the `chef-splunk::setup_auth` recipe.
- Fixes [#126](https://github.com/chef-cookbooks/chef-splunk/issues/126) creates `$SPLUNK_HOME/etc/system/local/user-seed.conf`

## 3.1.0 (2019-10-16)

- Fixes [#50](https://github.com/chef-cookbooks/chef-splunk/issues/50) `splunk_installer` now allows for installing the package bundle from OS package managers by specifying `package_name` and `version`

## 3.0.0 (2019-10-15)

- This release is brought to you by @haidangwa. Thanks!
- Added `upgrade` action to `splunk_installer` resource
- Fixed `chef-splunk::upgrade` recipe to actually upgrade splunk
- Fixed issue [#122](https://github.com/chef-cookbooks/chef-splunk/issues/122) removed `initial_captain` reference from comment
- `node['splunk']['accept_license']` is strictly enforced and documented that the value must be set to boolean `true`. Anything else will be considered not acceptig the license agreement.
- Ensures that the splunk directory has proper permissions and ownership set when splunk is run as a non-root user
- DRY chefspec examples
- cookstyle auto-corrects
- added Test Kitchen suites: `upgrade_server` and `uninstall_forwarder`
- Updated travis-ci config to include more test cases
- Fixed default upgrade URLs so they are not HTTP Redirect targets for debian platform family
- Accepted the license in startup scripts if accepted in attributes
- removed from Test Kitchen under dokken: debian 8
- added to Test Kitchen under dokken: debian 10 and ubuntu 18.04
- ensured that all recipes declare the service[splunk] resource consistently
- added helper methods: `#svc_command` and `#license_accepted?`
- Configure amazonlinux and fedora instances in kitchen-dokken and chefspec to run correctly.

## 2.0.0 (2019-10-01)

- Fixed issue [#58](https://github.com/chef-cookbooks/chef-splunk/issues/58) Converted the `splunk_installer` definition into a custom resource
- Fixed issue [#101](https://github.com/chef-cookbooks/chef-splunk/issues/101) Added sensitive true to the execute resources with commands containing splunk auth
- Fixed issue [#106](https://github.com/chef-cookbooks/chef-splunk/issues/106) splunk service runs as splunk user now
- Fixed issue [#118](https://github.com/chef-cookbooks/chef-splunk/issues/118) removed omnios platform tests
- bumped chef-vault dependency to `>= 3.1.1`
- moved content from files/default and templates/default in accordance with modern file specificity rules
  - Require Chef 13.11 or newer
- Removed (undocumented) support for Solaris (OmniOS) platform; omnios is not a platform
  that can currently be tested under ChefSpec and Test Kitchen.
- fixes to ensure splunk run as a non-root user
- added helper methods: `#splunk_runas_user` and `#splunk_service_provider`
- Fixed logic in setup_shcluster recipe and fixed the corresponding chefspec
- added `sensitive true` for SSL certificate private key and certificate resources
- ensured yum-centos repository is enabled in Test Kitchen for tests requiring centos or redhat

## 1.7.3 (2018-04-27)

- Set ownership of web.conf file using the splunk owner/group attributes

## 1.7.2 (2017-11-06)

- set the systemd unit file to 644

## 1.7.1 (2017-09-25)

- Enable amazon platform support for splunk forwarder
- Resolve deprecation warning in Chefspec and use the latest platforms in the specs

## v1.7.0 (2017-06-25)

- Fix CI and Kitchen Dokken
- Fix upgrade recipe
- Fix install on SUSE platform
- Add Splunk 6.6 URLs as default
- Add static list of indexers for client recipe
- Add multisite indexer clustering
- Add search head clustering
- Add ['splunk']['splunk_servers'] attribute as an alternative to using chef search functionality to discover splunk servers.

## v1.6.0 (2016-07-19)

- Updated the default version of the Splunk forwarder to 6.4
- Removed the scope section of the readme as this is no longer a Chef Ops maintained cookbook

## v1.5.0 (2016-03-14)

- Set the default version to 6.3.3 with working URLs
- Added integration testing in Travis CI with Kitchen Docker
- Added a scope to the readme to properly set expectations
- Added travis and cookbook version badges to the readme
- Removed Ubuntu 10.04 as a supported version and add 14.04
- Resolved all Rubocop warnings
- Pinned Gemfile to specific supported versions
- Added the Apache 2.0 license file
- Added maintainers.toml and maintainers.md files
- Replaced the testing.md file with a link to the docs repo
- Added long_description to the metadata
- Added source_url and issues_url for Supermarket to the metadata

## v1.4.0 (2015-09-13)

Also known as the "it's about time!" release

- support for splunk universal client running as a server
- update splunk install version to 6.2.1
- added attribute for rate limiting maxKBps throughput
- Add recipe to setup indexer cluster
- use `declare_resource` method to setup the right local-file package resource for `splunk_installer` definition
- lots of fixes for specs and tests

## v1.3.0 (2014-10-24)

- Implement dynamic inputs.conf and outputs.conf configuration based on attributes in client recipe.

## v1.2.2 (2014-08-25)

- Implement capability to run Splunk as a non-root user
- Allow web port to be specified

## v1.2.0 (2014-05-06)

- [COOK-4621] - upgrade to Splunk 6.0.3 (for heartbleed)
- add ubuntu 14.04 to test-kitchen

## v1.1.0 (2014-03-19)

- [COOK-4450] - upgrade to Splunk 6.0.2
- [COOK-4451] - unbreak test harness

## v1.0.4

- template sources should have .erb explicitly
- don't show the password in the execute resource name

## v1.0.2

- Splunk init script supports status, use it in `stop` action for upgrade.

## v1.0.0

- Initial release
