# eod_prtg
============================

This Chef cookbook deploys configuration to PRTG.

__NOTE:__ This cookbook is configured to be used with Chef policies. Please also refer to the `chef_policies` repository.

## Supported OS

Windows 2016/2019

## Supported Chef

- Chef 15 (last tested on 16)

## Cookbook Dependencies

- `chef-vault`

## Recipes

- `eod_prtg::default` - Default recipe. Call the others.

- `eod_prtg::deployeodmonitoring` - Deploys EODMonitoring\Tools folder used by some PRTG Probes

- `eod_prtg::deploy-scripts` - Create folder and put all script in files\script type into its own folder.

- `eod_prtg::setup-prtg` - Configure the custom PRTG core connection port in the registry and sets PRTG Core Server IP Address

## Custom Resources

## Limitations / Known Issues

### __Manually Deploy PRTG Sensor__
Many parts of the PRTG installation process remain manual. Before running this cookbook, complete the following:

1. [Install PRTG Remote Probe](https://www.paessler.com/manuals/prtg/install_a_prtg_remote_probe)
    * [You can use command line parameters to install to a different location than the default.](https://kb.paessler.com/en/topic/2773-what-command-line-codes-and-exit-codes-can-i-use-with-paessler-setups)

2. Configure registry
    * Set the following key-value pair under `\HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Paessler\PRTG Network Monitor\Probe`:  
    '`ServerPort`' : '`22856`'
    * This is also managed via eod_prtg role, but may be necessary on initial install prior to adding the Policy File

5. Setup Dell Compellent monitoring configuration
    1. Run `.\Unblock-DellSdk.ps1` under `\Custom Sensors\EXEXML\EOD.Dell.Common\dellSdk\`
    2. Run `.\Set-PasswordForStorageDevice.ps1` under `\Custom Sensors\EXEXML\EOD.Dell.Common\` AS THE PRTG SERVICE ACCOUNT
        * Provide the Compellent hostname and admin password while the script is running

## Kitchen Tests

**NOTE** 

1. Before running any kitchen tests, ensure that you have downloaded and have the most recent databags and environments.
    1. For your databag, make sure your kitchen pantry databag has updated passwords (eg. `chef\kitchen-pantry\databags\passwords`)
    2. Make sure that the QA access keys are set-up in your kitchen pantry
2. Some features are disabled by default, but are enabled in the kitchen.yml with specific settings for testing purposes.
