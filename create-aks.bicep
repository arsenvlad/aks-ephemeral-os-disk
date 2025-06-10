param location string
param aksName string
param subnetId string

resource managedClusters_avaks_centralus_name_resource 'Microsoft.ContainerService/managedClusters@2025-02-01' = {
  name: aksName
  location: location
  sku: {
    name: 'Base'
    tier: 'Free'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: '1.31'
    dnsPrefix: '${aksName}-${uniqueString(resourceGroup().id)}'
    agentPoolProfiles: [
      {
        name: 'system'
        count: 1
        vmSize: 'Standard_D4ds_v5'
        osDiskSizeGB: 150
        osDiskType: 'Ephemeral'
        kubeletDiskType: 'OS'
        vnetSubnetID: subnetId
        type: 'VirtualMachineScaleSets'
        orchestratorVersion: '1.31'
        mode: 'System'
        osType: 'Linux'
        osSKU: 'Ubuntu'
      }
      {
        name: 'd64dsv5'
        count: 1
        vmSize: 'Standard_D64ds_v5'
        osDiskSizeGB: 500
        osDiskType: 'Ephemeral'
        kubeletDiskType: 'Temporary'
        vnetSubnetID: subnetId
        type: 'VirtualMachineScaleSets'
        orchestratorVersion: '1.31'
        mode: 'User'
        osType: 'Linux'
        osSKU: 'Ubuntu'
      }
      {
        name: 'd64dsv6'
        count: 1
        vmSize: 'Standard_D64ds_v6'
        osDiskSizeGB: 1700
        osDiskType: 'Ephemeral'
        kubeletDiskType: 'OS'
        vnetSubnetID: subnetId
        type: 'VirtualMachineScaleSets'
        orchestratorVersion: '1.31'
        mode: 'User'
        osType: 'Linux'
        osSKU: 'Ubuntu'
      }
    ]
    linuxProfile: {
      adminUsername: 'azureuser'
      ssh: {
        publicKeys: [
          {
            keyData: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCdTVmzH7L9bZqeFZ/+GHh48Dq5NU2jEYby9BFM/xrex+31OjKu/r9EZhLT23UkZGcemPg4htvbwQ26oo5JFBT9YJDWKiE7n+jIpqrU7NKFhqv0O6CNqrLHorC6NqZYdNmlNUPYR5TVB1wNOaOgnXyTl32Pi9Tk0vuGXcMpa1ig8GLwzCcwws0PnvVNOUm4sJuWMhg8zCW3tfkjGMh9urBWw4fbibMoi5lBEBL5uD2/eec3AyCMIQUf4yACBfzFZWqeNjEzWkzEqenWmMS20gCrKGxKDkvKh9vSu0dwhHzzLXy7vYErM843R0IUWxNwqn9Si8+bNujCdetCGgRrMkuH'
          }
        ]
      }
    }
    enableRBAC: true
    networkProfile: {
      networkPlugin: 'azure'
      networkPluginMode: 'overlay'
      networkPolicy: 'cilium'
      networkDataplane: 'cilium'
      podCidr: '192.168.0.0/16'
      serviceCidr: '10.2.0.0/24'
      dnsServiceIP: '10.2.0.10'
    }
  }
}
