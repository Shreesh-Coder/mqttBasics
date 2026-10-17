<#
.SYNOPSIS
  Publish a message to one of the demo topics (PowerShell twin of pub.sh).

.EXAMPLE
  .\scripts\pub.ps1 temperature 24.5
  .\scripts\pub.ps1 fire "SMOKE DETECTED IN KITCHEN"
#>
param(
  [Parameter(Mandatory = $true, Position = 0)]
  [ValidateSet('temperature', 'humidity', 'light', 'fire')]
  [string]$Topic,

  [Parameter(Mandatory = $true, Position = 1, ValueFromRemainingArguments = $true)]
  [string[]]$Message
)

$ErrorActionPreference = 'Stop'

# Map the short name to the real MQTT topic and the publisher container.
$map = @{
  temperature = @{ Topic = 'sensors/temperature'; Container = 'pub_temperature' }
  humidity    = @{ Topic = 'sensors/humidity';    Container = 'pub_humidity'    }
  light       = @{ Topic = 'home/light';          Container = 'pub_light'       }
  fire        = @{ Topic = 'alerts/fire';         Container = 'pub_fire'        }
}
$mqttTopic = $map[$Topic].Topic
$container = $map[$Topic].Container
$payload   = $Message -join ' '

Write-Host "[pub.ps1] Publishing to topic '$mqttTopic' via container '$container'"
Write-Host "[pub.ps1] Payload: $payload"

docker exec $container mosquitto_pub -h broker -t $mqttTopic -m $payload
if ($LASTEXITCODE -ne 0) { throw "docker exec failed (is the stack up? try: docker compose up -d)" }

Write-Host "[pub.ps1] Done."
