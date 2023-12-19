Set-Location $PSScriptRoot
$Msi = (Get-Item '*.msi')[0]

Get-Process -ProcessName AppName -ErrorAction SilentlyContinue |
    Stop-Process -Force

$MsiArgs = @{
    FilePath = 'msiexec.exe'
    ArgumentList = "/i `"$($Msi.FullName)`" /qn /l*vx `"$env:SystemRoot\temp\appname_install.log`""
    NoNewWindow = $true
    PassThru = $true
    Wait = $false
}
$p = Start-Process @MsiArgs
$p.WaitForExit()
