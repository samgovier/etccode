#
# Cookbook:: eod_prtg
# Recipe:: deploy-prtg
# Copyright:: 2021, The Authors, All Rights Reserved.
# Description: 
# - Updates PRTG to use Esker specific custom port for communication back to the core server

registry_key node["eod_prtg"]["prtg"]["probe_regkey"]  do
    values [{
        :name => 'ServerPort',
        :type => :string,
        :data => node["eod_prtg"]["prtg"]["server_port"]
        }]
    recursive true
    action :create
end 


registry_key node["eod_prtg"]["prtg"]["probe_regkey"]  do
    values [{
        :name => 'Server',
        :type => :string,
        :data => node["eod_prtg"]["prtg"]["server_dns_ip"]
        }]
    recursive true
    action :create
end 