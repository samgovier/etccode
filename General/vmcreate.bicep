// qa-rg
// command for deploy: az deployment group create -g qa-rg -f .\gissamanvm.bicep
// https://learn.microsoft.com/en-us/azure/templates/microsoft.compute/virtualmachines?pivots=deployment-language-bicep
// https://learn.microsoft.com/en-us/azure/virtual-machines/windows/quick-create-bicep

param adminUsername string

@secure()
param adminPassword string

resource pocsub 'Microsoft.Network/virtualNetworks/subnets@2024-01-01' existing = {
  name: 'qa-vnet/poc-subnet'
  scope: resourceGroup('qa-network-rg')
}

resource pocnic 'Microsoft.Network/networkInterfaces@2024-01-01' = {
  name: 'poc-qa-01-nic'
  location: 'westus'
  tags: {
    CreatedBy: 'sam.govier'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: pocsub.id
          }
        }
      }
    ]
  }
}

resource pocvm 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: 'poc-qa-01'
  location: 'westus'
  tags: {
    CreatedBy: 'sam.govier'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D4s_v3'
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: pocnic.id
        }
      ]
        }
    osProfile: {
      computerName: 'poc-qa-01'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          diskSizeGB: 512
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
  }
}
