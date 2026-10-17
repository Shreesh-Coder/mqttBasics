<#
.SYNOPSIS
  Tail a subscriber container's live log (PowerShell twin of sub.sh).

.EXAMPLE
  .\scripts\sub.ps1 temperature
#>
param(
  [Parameter(Mandatory = $true, Position = 0)]
  [ValidateSet('temperature', 'humidity', 'light', 'fire')]
  [string]$Topic
)

$container = "sub_$Topic"
Write-Host "[sub.ps1] Live feed for '$container'. Press Ctrl+C to stop."
docker logs -f $container
