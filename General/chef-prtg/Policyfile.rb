# Policyfile.rb - Describe how you want Chef Infra Client to build your system.
#
# For more information on the Policyfile feature, visit
# https://docs.chef.io/policyfile.html

# A name that describes what the system you're building with Chef does.
name 'prtg'

require 'json'

# Get policy group name from environment (set by azure devops group variables when running pipelines)
policy_group = ENV['policy_group'].to_s

# Load settings linked to our policy group from the settings folder
# This is where the chef_server_url is defined
settings = JSON.parse(File.read("../../settings/#{policy_group}.json"))

# Where to find external cookbooks:
default_source :chef_server, settings['chef_server_url']

# List other policies you want to include.
# Their run_list will be added before the one in this policy.
include_policy 'poise-hoist', server: settings['chef_server_url'], policy_group: policy_group

# run_list: chef-client will run these recipes in the order specified.
# %w() is the idiomatic ruby way to create an array of words
computed_run_list = %w(eod_os eod_prtg)


run_list computed_run_list

# Specify attributes by policy group
require_relative '../../AttributeLoader/AttributeLoader'

default[policy_group] = AttributeLoader.load_attributes(policy_group)