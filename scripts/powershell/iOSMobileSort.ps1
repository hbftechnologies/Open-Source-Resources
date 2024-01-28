<#
iOS Mobile Device Sortation Script

Will sort through the device data locally provided with Intune to make sure that the devices are corporate owned and not personal devices.
You will need to provide the data for the mobile users and the corporate devices. The script will then compare the data and output a CSV.
You will need Microsoft.Graph.Intune and AzureAD modules installed. You will also need to connect to MSGraph and AzureAD before running the script.
The following users will need a valid UPN within Azure. The script will not work if the UPN is not valid.

Created By: Harley Frank
Created On: 01/28/2024
Last Modified: 01/28/2024

#>

# Imports
Import-Module -Name ImportExcel
Import-Module -Name Microsoft.Graph.Intune
Import-Module -Name AzureAD

# Variables
$mobileUsers = @()
$iOSDevices = @()
$companyRegisteredDevices = @()
$personalRegisteredDevices = @()
$companyObjectIDs = @()
$byodRegisteredDevices = @()
$destinationAzureData = @()
$azureADDevices = Get-AzureADDevice -All $true
$mobileUsers = Import-Excel -Path "$PSScriptRoot\data\mobileUsers.xlsx" -NoHeader | Select-Object -Skip 1
$corporateDevices = Import-Excel -Path "$PSScriptRoot\data\corpDevices.xlsx"

# Connect to MSGraph (only needed once)
Connect-MSGraph

# Grab Intune Data
$devices = Get-IntuneManagedDevice | Get-MSGraphAllPages
$iOSDevices = $devices | Where-Object {$_.operatingSystem -eq 'iOS'}
$iPhones = $iosDevices | Where-Object {$_.model -like 'iPhone*'}

# Sort the data based on selected parameters and output to spreadsheet
# checks iOS devices for corporate owned debices
foreach ($iPhone in $iPhones) {
    foreach ($user in $mobileUsers.P1) {
        if ($iPhone.userPrincipalName -contains $user) {
            if ($iPhone.managedDeviceOwnerType -eq "company") {
                $companyRegisteredDevices += [PSCustomObject]@{
                    DeviceID = $iPhone.azureADDeviceId
                }
            } else {
                $personalRegisteredDevices += [PSCustomObject]@{
                    User = $user
                    DeviceModel = $iPhone.model
                    DeviceID = $iPhone.azureADDeviceId
                    SerialNumber = $iPhone.serialNumber
                    IMEI = $iPhone.imei
                }
            }
        }
    }
}

# Connect to Azure AD (only needed once)
Connect-AzureAD

# Grab Azure AD Data
# grabs all the devices pulled from users and compares them to Azure AD Device that we have confirmed is corporate
# then outputs the ObjectID
foreach ($companyDevice in $companyRegisteredDevices) {
    $deviceID = $companyDevice.DeviceID
    $deviceObjectID = $azureADDevices | Where-Object {$_.DeviceID -eq "$deviceID"} | Select-Object -ExpandProperty ObjectID
    $companyObjectIDs += [PSCustomObject]@{
        ObjectID = $deviceObjectID
    }
    $destinationAzureData += [PSCustomObject]@{
        ObjectID = $deviceObjectID
    }
}

# Compare personal phone data and grab Object IDs
foreach ($personalDevice in $personalRegisteredDevices) {
    $deviceID = $personalDevice.DeviceID
    $imei = $personalDevice.IMEI
    
    foreach ($telecomDevice in $corporateDevices) {
        $imei2 = $telecomDevice.'IMEI Number'

        if ($imei -eq $imei2) {
            $byodObjectID = $azureADDevices | Where-Object {$_.DeviceID -eq "$deviceID"} | Select-Object -ExpandProperty ObjectID

            $byodRegisteredDevices += [PSCustomObject]@{
                DeviceID = $deviceID
                ObjectID = $byodObjectID
                IMEI = $imei
            }
            $destinationAzureData += [PSCustomObject]@{
                ObjectID = $byodObjectID
            }
        }
    }

}

$destinationAzureData | Export-CSV -Path 'data\mobielDeploymentDevices.csv' -NoTypeInformation
