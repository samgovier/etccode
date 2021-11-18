#
# Cookbook:: eod_prtg
# Recipe:: deploy-scripts
# Copyright:: 2021, The Authors, All Rights Reserved.
# Description: 
# - Deploys common PRTG Custom Sensors with perform advanced monitoring based on scripts

# loop through the folder to deploy
node["eod_prtg"]["scripts"].each do |script_type, folder_path|
  remote_directory folder_path do
    source script_type
    action :create
    recursive true
    purge false
    overwrite true
  end
end

# Path and file name pulled from node attributes
if node['eod_prtg']['edpasxx_restart_check']['is_enabled']

  maxdb_restart_creds    = chef_vault_item(node['eod_prtg']['edpasxx_restart_check']['vault_name'], node['eod_prtg']['edpasxx_restart_check']['bag_id'])
  maxdb_restart_user     = maxdb_restart_creds[node['eod_prtg']['edpasxx_restart_check']['database_name']]['username']
  maxdb_restart_password = maxdb_restart_creds[node['eod_prtg']['edpasxx_restart_check']['database_name']]['password'] 

  template "#{node['eod_prtg']['edpasxx_restart_check']['destination_file_path']}/#{node['eod_prtg']['edpasxx_restart_check']['destination_file_name']}" do
    source 'EXE/EDPASXX-RestartCheck.txt.erb'
    action :create
    variables(
      maxdb_restart_user: maxdb_restart_user,
      maxdb_restart_password: maxdb_restart_password
      )
  end
end
