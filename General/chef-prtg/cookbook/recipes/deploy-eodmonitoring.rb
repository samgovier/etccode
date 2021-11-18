#
# Cookbook:: eod_prtg
# Recipe:: deploy-eodmonitoring
# Copyright:: 2021, The Authors, All Rights Reserved.
# Description: 
# - Deploys Executables for EODMonitoring Folder


include_recipe 'chef-vault'
local_file = Chef::Config[:file_cache_path] + node['eod_prtg']['eodmonitoring']['eodmonitoring_file_download_name']

Accesskeys_vault = chef_vault_item('accesskeys', node['shared_artifacts']['storage_account'])
accesskey = Accesskeys_vault['key']

directory node['eod_prtg']['eodmonitoring']['eod_monitoring_folder_destination'] do
    rights      :full_control, 'Everyone'
    recursive   true
    action      :create
end


# Current Zip file used is set/configured in ../attributes/default.rb; remember to update checksum (sha256) as well.
# This will check for newer checksum and download zipped file from Azure Storage Blob
# - Then notify extract function if new file was downloaded
azure_file local_file do
    storage_account node['shared_artifacts']['storage_account']
    access_key accesskey
    container 'chef'
    remote_path node['eod_prtg']['eodmonitoring']['eodmonitoring_file_download_location']
    checksum node['eod_prtg']['eodmonitoring']['eodmonitoring_file_checksum']
    action :create
    # unzip immediately because some other cookbooks rely on it
    # otherwise first converge fails, meaning failed tests in kitchen
    notifies :extract, 'archive_file[extract_eodmonitoring]', :immediately
end


# Update EODMonitoring\Tools if:
# - notified that the folder is missing
# - new zip file is ready for deploy
# - contents of folder are different than expected
# - contents of folder are older than zipped file
archive_file 'extract_eodmonitoring' do
    path local_file
    destination node['eod_prtg']['eodmonitoring']['eod_monitoring_folder_destination']
    action :extract 
    # :auto the date stamp of files within the archive will be compared to those on disk and disk contents will be overwritten if they differ.
    overwrite :auto
    ignore_failure true
end

