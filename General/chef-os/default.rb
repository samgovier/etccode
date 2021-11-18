#
# Cookbook:: eod_os
# Recipe:: default
#
if node['platform_family'] == 'rhel'
    case node['platform_version'].split('.')[0]
    when '6'
      include_recipe 'eod_rhel6x::default'
    when '7'
      include_recipe 'eod_rhel7x::default'
    when '8'
      include_recipe 'eod_rhel8x::default'
	  end

    include_recipe 'eod_os::setup_ansible_env'

elsif node['platform_family'] == 'windows'
  include_recipe 'eod_windows::default'
end

include_recipe 'eod_os::setup_environmental_variables'
