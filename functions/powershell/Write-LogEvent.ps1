<#
.SYNOPSIS
    Write Log Event
.DESCRIPTION
    This uses the built in functions for PowerShell to create and wrtie to an event log.
.NOTES
    Event ID Uses
    - 09 = Script Information
    - 10 = Script Success
    - 11 = Script Error
    - 12 = Script Warning
.LINK
    Not Available
.EXAMPLE
    Write-EventLog -logMessage "This is an error message." -logSeverity "Error" -logEventID "1000"
    Write-EventLog -logMessage "This is an information message." -logSeverity "Information" -logEventID "1000"
    Write-EventLog -logMessage "This is a warning message." -logSeverity "Warning" -logEventID "1000"
#>

function Write-LogEvent {
    [CmdletBinding()]
    param (
        $logMessage,
        $logSeverity,
        $logEventID
    )

    $logExists = Get-EventLog -list | Where-Object {$_.logdisplayname -eq "Log Name"} 
    if (! $logExists) {
        New-EventLog -LogName "Log Name" -Source "Powershell Name Module"
        Limit-EventLog -LogName "Log Name" -MaximumSize 512MB -OverflowAction OverwriteOlder -RetentionDays 120
    }

    Write-EventLog -LogName "Log Name" -Source "Powershell Name Module" -EventID $logEventID -Message $logMessage -EntryType $logSeverity
}