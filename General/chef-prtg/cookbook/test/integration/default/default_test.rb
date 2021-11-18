# # encoding: utf-8

# Inspec test for recipe eod_adfs::default

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/



describe directory('C:\\temp\\prtg\\EXE\\') do
  it { should exist }
end

describe directory('C:\\temp\\prtg\\EXEXML\\') do
  it { should exist }
end

describe directory('C:\\temp\\prtg\\EXEXML\\EOD.Dell.Common\\') do
  it { should exist }
end

describe registry_key('HKLM\SOFTWARE\WOW6432Node\Paessler\PRTG Network Monitor\Probe') do
  its('serverport') { should eq '22856' }
end