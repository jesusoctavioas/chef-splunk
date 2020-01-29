#
# Author: Joshua Timberman <joshua@chef.io>
# Contributor: Dang H. Nguyen <dang.nguyen@disney.com>
# Copyright:: 2014-2020, Chef Software, Inc <legal@chef.io>
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
require 'pathname'
require 'chef/provider/lwrp_base'
require_relative './helpers.rb'
require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut

# Creates a provider for the splunk_app resource.
class Chef
  class Provider
    class SplunkApp < Chef::Provider::LWRPBase
      provides :splunk_app

      action :install do
        dir = app_dir # this grants chef resources access to the private `#app_dir`

        if app_installed?
         ::Chef::Log.debug "#{new_resource.app_name} is installed"
         return
       end

        splunk_service
        install_dependencies unless new_resource.app_dependencies.empty?
        if new_resource.cookbook_file
          app_package = local_file(new_resource.cookbook_file)
          cookbook_file app_package do
            source new_resource.cookbook_file
            cookbook new_resource.cookbook
            checksum new_resource.checksum
            owner splunk_runas_user
            group splunk_runas_user
            notifies :run, "execute[splunk-install-#{new_resource.app_name}]", :immediately
          end
        elsif new_resource.remote_file
          app_package = local_file(new_resource.remote_file)
          remote_file app_package do
            source new_resource.remote_file
            checksum new_resource.checksum
            owner splunk_runas_user
            group splunk_runas_user
            notifies :run, "execute[splunk-install-#{new_resource.app_name}]", :immediately
          end
        elsif new_resource.remote_directory
          remote_directory dir do
            source new_resource.remote_directory
            cookbook new_resource.cookbook
            owner splunk_runas_user
            group splunk_runas_user
            files_owner splunk_runas_user
            files_group splunk_runas_user
            notifies :restart, 'service[splunk]'
          end
        else
          raise "Could not find an installation source for splunk_app[#{new_resource.app_name}]"
        end

        execute "splunk-install-#{new_resource.app_name}" do
          sensitive false
          command "#{splunk_cmd} install app #{dir} -auth #{splunk_auth(new_resource.splunk_auth)}"
        end

        directory "#{dir}/local" do
          recursive true
          mode '755'
          owner splunk_runas_user
          group splunk_runas_user
        end

        case new_resource.templates.class
        when Hash
          # create the templates with destination paths relative to the target app_dir
          # Hash should be key/value where the key indicates a destination path (including file name),
          # and value is the name of the template source
          new_resource.templates.each do |destination, source|
            template "#{dir}/#{destination}" do
              source source
              cookbook new_resource.cookbook
              owner splunk_runas_user
              group splunk_runas_user
              mode '644'
              notifies :restart, 'service[splunk]'
            end
          end
        when Array
          new_resource.templates.each do |t|
            t = t.match?(/(\.erb)*/) ? ::File.basename(t, '.erb') : t
            template "#{dir}/local/#{t}" do
              source "#{new_resource.app_name}/#{t}.erb"
              cookbook new_resource.cookbook
              owner splunk_runas_user
              group splunk_runas_user
              mode '644'
              notifies :restart, 'service[splunk]'
            end
          end
        end
      end

      action :remove do
        dir = app_dir # this grants chef resources access to the private `#app_dir`

        splunk_service
        directory dir do
          action :delete
          recursive true
          notifies :restart, 'service[splunk]'
        end
      end

      action :enable do
        if app_enabled?
          ::Chef::Log.debug "#{new_resource.app_name} is enabled"
          return
        end

        splunk_service
        execute "splunk-enable-#{new_resource.app_name}" do
          sensitive false
          command "#{splunk_cmd} enable app #{new_resource.app_name} -auth #{splunk_auth(new_resource.splunk_auth)}"
          notifies :restart, 'service[splunk]'
        end
      end

      action :disable do
        return unless app_enabled?
        splunk_service
        execute "splunk-disable-#{new_resource.app_name}" do
          sensitive false
          command "#{splunk_cmd} disable app #{new_resource.app_name} -auth #{splunk_auth(new_resource.splunk_auth)}"
          not_if { ::File.exist?("#{splunk_dir}/etc/disabled-apps/#{new_resource.app_name}") }
          notifies :restart, 'service[splunk]'
        end
      end

      private

      def app_dir
        new_resource.app_dir || "#{splunk_dir}/etc/apps/#{new_resource.app_name}"
      end

      def local_file(source)
        "#{Chef::Config[:file_cache_path]}/#{Pathname(source).basename}"
      end

      def app_enabled?
        return true unless ::File.exist?("#{splunk_dir}/etc/disabled-apps/#{new_resource.app_name}")
        s = shell_out("#{splunk_cmd} display app #{new_resource.app_name} -auth #{splunk_auth(new_resource.splunk_auth)}")
        s.run_command
        if s.stdout.empty?
          false
        else
          s.stdout.split[2] == 'ENABLED'
        end
      end

      def app_installed?
        ::File.exist?("#{app_dir}/default/app.conf") || ::File.exist?("#{app_dir}/local/app.conf")
      end

      def splunk_service
        service 'splunk' do
          action :nothing
          supports status: true, restart: true
          provider Chef::Provider::Service::Init
        end
      end

      def install_dependencies
        package new_resource.app_dependencies
      end
    end
  end
end
