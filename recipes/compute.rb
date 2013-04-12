#
# Cookbook Name:: ktc-nova
# Recipe:: compute
#

chef_gem "chef-rewind"
require 'chef/rewind'

# Define our own nova_conf provider and rewind nova_conf resource to use it
# to add quantum_default_private_network option into the nova.conf file.
include_recipe "ktc-nova::provider_nova_conf"
include_recipe "nova::compute"
rewind :nova_conf => "/etc/nova/nova.conf" do
  provider Chef::Provider::KtcNovaConf
  cookbook_name "ktc-nova"
end

# Rewind nova-compute.conf template to use the "lb" config source
if node["quantum"]["plugin"] == "lb"
  rewind :template => "/etc/nova/nova-compute.conf" do
    source "folsom/nova-compute.conf.erb"
    cookbook_name "ktc-nova"
  end
end

# apply fixes for Alpha-1: location based IP assignment
include_recipe "osops-utils"
template "/usr/share/pyshared/nova/network/quantumv2/api.py" do
  source "ktc-patches/api.py.2012.2.1+stable-20121212-a99a802e-0ubuntu1.4~cloud0"
  owner "root"
  group "root"
  mode "0644"
  notifies :restart, resources(:service => "nova-compute"), :immediately
  only_if { ::Chef::Recipe::Patch.check_package_version("nova-compute","2012.2.1+stable-20121212-a99a802e-0ubuntu1.4~cloud0",node) }
end
