$SoftwareUninstallPath = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\',
    'HKLM:\SOFTWARE\Wow6432node\Microsoft\Windows\CurrentVersion\Uninstall'
)

$records = $SoftwareUninstallPath | ForEach-Object {
    Get-ItemProperty ($_ + '\*')
}

$matchedRecords = $records | Where-Object { $_.displayname -EQ 'exact program name' }

if ($matchedRecords){
    $matchedRecords | ForEach-Object {
        cmd /c $_.UninstallString --force-uninstall
    }
}