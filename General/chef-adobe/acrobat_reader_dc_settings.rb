# force set PDF default to be Adobe
execute 'assoc_pdf_adobe' do
  command 'assoc .pdf=AcroExch.Document.DC'
  not_if 'assoc .pdf | findstr "AcroExch.Document.DC"'
end

# Prevent licence popup
registry_key 'HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Adobe\Acrobat Reader\DC\AdobeViewer' do
  values [{
    name: 'EULA',
    type: :dword,
    data: 00000001,
  }]
  recursive true
  action :create
end

users = []
users << node.read('service_users','asadmin')
users << node.read('service_users','asconversion')

::Chef::Recipe.send(:include, Windows::RegistryHelper)

users.each do |user|
  user_sid = resolve_user_to_sid(user['name'])
  user_sid = user['sid'] if user_sid.nil?
  if registry_key_exists?("HKEY_USERS\\#{user_sid}", :machine)

    registry_key "HKEY_USERS\\#{user_sid}\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FileExts\\.pdf\\UserChoice" do
      recursive true
      values [
        # 2. Make sure that Windows has been configured to open PDF files with Acrobat Reader.
        { name: 'ProgId', type: :string, data: 'AcroExch.Document.DC' }
      ]
      action :create
    end
  else
    Chef::Log.warn("does not exist hive/sid for the '#{user}' : can't import registry keys")
  end 
end
