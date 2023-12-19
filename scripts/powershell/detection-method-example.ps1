$SoftwareUninstallPath = @( 
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\', 
    'HKLM:\SOFTWARE\Wow6432node\Microsoft\Windows\CurrentVersion\Uninstall'
)
$software = $SoftwareUninstallPath | ForEach-Object {
    Get-ItemProperty ($_ + '\*')
}
$application = 'Microsoft Edge Webview2 Runtime*'
$records = $software | Where-Object displayname -like $application
[Version]$TargetVersion = '116.0.1938.54'

$records | ForEach-Object {
    [Version]$ExistingVersion = $_.DisplayVersion
    if ($ExistingVersion -ge $TargetVersion) {
        Write-Host "Installed"
    }
}