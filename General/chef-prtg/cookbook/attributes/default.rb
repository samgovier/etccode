# This is a Chef attributes file. It can be used to specify default and override
# attributes to be applied to nodes that run this cookbook.
# For further information, see the Chef documentation (https://docs.chef.io/essentials_cookbook_attribute_files.html).

default["eod_prtg"]["scripts"]["EXE"] = 'C:\\temp\\prtg\\EXE\\'
default["eod_prtg"]["scripts"]["EXEXML"] = 'C:\\temp\\prtg\\EXEXML\\'
default["eod_prtg"]["scripts"]["sql"] = 'C:\\temp\\prtg\\sql\\'


default["eod_prtg"]["prtg"]["probe_regkey"] = 'HKLM\SOFTWARE\WOW6432Node\Paessler\PRTG Network Monitor\Probe'
default["eod_prtg"]["prtg"]["server_port"] = '22856'

# defaults to false, but overwritten in kitchen.yml
default['eod_prtg']['dellsdk']['is_enabled_dellsdk'] = false
default['eod_prtg']['dellsdk']['dellsdk_folder_destination'] = 'C:\\temp\\prtg\\EXEXML\\EOD.Dell.Common\\'
default['eod_prtg']['dellsdk']['dellsdk_file_download_name'] = 'dellSdk.zip'
default['eod_prtg']['dellsdk']['dellsdk_file_download_location'] = 'EOD_PRTG/Generic/dellSdk.zip'
default['eod_prtg']['dellsdk']['dellsdk_file_checksum'] = ''

# Used to deploy templates for RubyException.  Current templates are for 2 and 5+
default['eod_prtg']['rubyexception']['elastic_version'] = '5'

# Deployes D:\EODMonitoring\Tools to the correct location
# defaults to false, but overwritten in kitchen.yml
default['eod_prtg']['eodmonitoring']['is_enabled_eodmonitoring'] = false
default['eod_prtg']['eodmonitoring']['eod_monitoring_folder_destination'] = 'C:\\EODMonitoring\\'
default['eod_prtg']['eodmonitoring']['eodmonitoring_file_download_name'] = 'EODMonitoring_C_Tools.zip'
default['eod_prtg']['eodmonitoring']['eodmonitoring_file_download_location'] = 'EOD_PRTG/Generic/EODMonitoring_C_Tools.zip'
default['eod_prtg']['eodmonitoring']['eodmonitoring_file_checksum'] = ''