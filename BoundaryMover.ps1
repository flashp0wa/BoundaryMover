<#
.SYNOPSIS

.DESCRIPTION
    You can use the script to move boundaries from one boundary group to another. At the end the script will ask You if You wish to remove boundaries from source boundary group.

.NOTES
    Author: flashp0wa
    Last Edit: 11/15/2020
    Version 1.0

#>
param(
    [Parameter(Mandatory=$true)]
    [string]$SourceBoundaryGroup,
    [Parameter(Mandatory=$true)]
    [string]$TargetBoundaryGroup
    )

#Create Tracelog
$global:LOGFILE = "C:\Windows\BoundaryMover.log"
$global:bVerbose = $True


function Write-TraceLog
{                                       
    [CmdletBinding()]
    PARAM(
     [Parameter(Mandatory=$True)]                     
	    [String]$Message,                     
	    [String]$LogPath = $LOGFILE, 
     [validateset('Info','Error','Warn')]   
	    [string]$severity,                     
	    [string]$component = $((Get-Variable MyInvocation -Scope 1).Value.MyCommand.Name),
        [long]$logsize = 5 * 1024 * 1024,
        [switch]$Info
	)                

    $Verbose = [bool]($PSCmdlet.MyInvocation.BoundParameters['Verbose'])
    Switch ($severity)
    {
        'Error' {$sev = 3}
        'Warn'  {$sev = 2}
        default {$sev = 1}
    }

    If (($Verbose -and $bVerbose) -or ($Verbose -eq $false)) {
	    $TimeZoneBias = Get-WmiObject -Query "Select Bias from Win32_TimeZone"                     
	    $WhatTimeItIs= Get-Date -Format "HH:mm:ss.fff"                     
	    $Dizzate= Get-Date -Format "MM-dd-yyyy"                     
	
	    "<![LOG[$Message]LOG]!><time=$([char]34)$WhatTimeItIs$($TimeZoneBias.bias)$([char]34) date=$([char]34)$Dizzate$([char]34) component=$([char]34)$component$([char]34) context=$([char]34)$([char]34) type=$([char]34)$sev$([char]34) thread=$([char]34)$([char]34) file=$([char]34)$([char]34)>"| Out-File -FilePath $LogPath -Append -NoClobber -Encoding default
    }

    If ($bVerbose) {write-host $Message}

    $LogPath = $LogPath.ToUpper()
    $i = Get-Item -Path $LogPath
    #$i.Length
    #$i.Length
    If ($i.Length -gt $logsize)
    {
        $backuplog = $LogPath.Replace(".LOG", ".LO_")
        If (Test-Path $backuplog)
        {
            Remove-Item $backuplog
        }
        Move-Item -Path $LogPath -Destination $backuplog
    } 

}

Write-TraceLog -Message "Starting script" -severity Info -component "BoundaryMover"

Import-Module 'E:\Program Files\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1'
Set-Location CAS:

$sbgID = (Get-CMBoundaryGroup -Name $SourceBoundaryGroup).GroupID 
$sbValues = Get-CMBoundary -BoundaryGroupID $sbgID

foreach ($value in $sbValues) {
    $BoundaryID = $value.BoundaryID
    $BoundaryDescription = $value.BoundaryDescription

    Add-CMBoundaryToGroup -BoundaryId $BoundaryID -BoundaryGroupName $TargetBoundaryGroup
    Write-TraceLog -Message "Moving boundary $BoundaryDescription from $SourceBoundaryGroup to $TargetBoundaryGroup" -severity Info -component "BoundaryMover"
}

Write-TraceLog -Message "Boundaries have been successfully moved" -severity Info -component "BoundaryMover"


$DeleteBoundary = read-host -Prompt "Do You want to remove boundaries from source boundary group? (Type Y/N)"

if ($DeleteBoundary -eq "Y") {
    
    foreach ($value in $sbValues) {
        $BoundaryID = $value.BoundaryID
        $BoundaryDescription = $value.DisplayName
    
        Remove-CMBoundaryFromGroup -BoundaryId $BoundaryID -BoundaryGroupName $SourceBoundaryGroup
        Write-TraceLog -Message "Removing boundary $BoundaryDescription from $SourceBoundaryGroup" -severity Info -component "BoundaryMover"
    }

Write-TraceLog -Message "Boundaries have been successfully deleted" -severity Info -component "BoundaryMover"
Write-TraceLog -Message "Script finished" -severity Info -component "BoundaryMover"
}

else {
    Write-TraceLog -Message "Script finished" -severity Info -component "BoundaryMover"  
}
