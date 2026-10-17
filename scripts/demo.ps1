<#
.SYNOPSIS
  Fire one sample message to each of the four demo topics (PowerShell twin of demo.sh).

.EXAMPLE
  .\scripts\demo.ps1
#>
$ErrorActionPreference = 'Stop'
$pub = Join-Path $PSScriptRoot 'pub.ps1'

Write-Host "[demo.ps1] Publishing demo messages to all four topics..."
Write-Host

& $pub temperature '24.5';                     Start-Sleep -Seconds 1
& $pub humidity    '61%';                      Start-Sleep -Seconds 1
& $pub light       'ON';                       Start-Sleep -Seconds 1
& $pub fire        'SMOKE DETECTED IN KITCHEN'

Write-Host
Write-Host "[demo.ps1] Done. Check each subscriber's log to see the message land."
Write-Host "[demo.ps1] Example: docker logs sub_fire"
