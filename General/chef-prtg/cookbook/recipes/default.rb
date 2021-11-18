#
# Cookbook:: eod_prtg
# Recipe:: default
#

# PRTG Standard Setup Conditions
include_recipe 'eod_prtg::setup-prtg'

# Make sure Custom Sensors folders are created on the server
include_recipe 'eod_prtg::deploy-scripts'

# Deploy EODMonitoring Folder
include_recipe 'eod_prtg::deploy-eodmonitoring' if node['eod_prtg']['eodmonitoring']['is_enabled_eodmonitoring']