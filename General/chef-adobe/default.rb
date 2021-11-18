include_recipe 'default'
include_recipe 'directories'
include_recipe 'prometheus'

majorVersion = node['platform_version'].split('.')[0].to_i
minorVersion = node['platform_version'].split('.')[2].to_i
if majorVersion >= 10 && minorVersion < 17763  
  include_recipe 'ie_11_settings'
  include_recipe 'acrobat_reader_dc_settings'
  if node['eod_edp_base']['restrict_office2k16']
    include_recipe 'office_2016_settings'
  end
end