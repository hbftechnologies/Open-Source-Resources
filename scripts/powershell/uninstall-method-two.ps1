$SoftwareUninstallPath = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\',
    'HKLM:\SOFTWARE\Wow6432node\Microsoft\Windows\CurrentVersion\Uninstall'
)
$records = $SoftwareUninstallPath | ForEach-Object {
    Get-ItemProperty ($_ + '\*')
}
$application = 'Quicktime*'
$matchedRecords = $records | Where-Object displayname -like $application
$matchedRecords | ForEach-Object {
    $log = Join-Path $env:systemroot "temp\$(($_.displayname).replace(' ','_'))_uninstall.log"
    $MsiArgs = @{
        FilePath = 'msiexec.exe'
        ArgumentList = "/x $($_.PSChildName) /qn /l `"$Log`""
        NoNewWindow = $true
        Wait = $false
        PassThru = $true
    }
    $p = Start-Process @MsiArgs
    $p.WaitForExit()
}