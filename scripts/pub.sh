#!/usr/bin/env bash
# =============================================================================
# pub.sh - Publish a message to one of the demo topics.
#
# Usage:
#   ./scripts/pub.sh <short_topic> <message>
#
# short_topic is one of:
#   temperature  -> sensors/temperature
#   humidity     -> sensors/humidity
#   light        -> home/light
#   fire         -> alerts/fire
#
# Example:
#   ./scripts/pub.sh temperature 24.5
#   ./scripts/pub.sh fire "SMOKE DETECTED IN KITCHEN"
# =============================================================================

set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <temperature|humidity|light|fire> <message>"
  exit 1
fi

SHORT="$1"
shift
MESSAGE="$*"

# Map the short name to the real MQTT topic and the publisher container.
case "$SHORT" in
  temperature) TOPIC="sensors/temperature"; CONTAINER="pub_temperature" ;;
  humidity)    TOPIC="sensors/humidity";    CONTAINER="pub_humidity"    ;;
  light)       TOPIC="home/light";          CONTAINER="pub_light"       ;;
  fire)        TOPIC="alerts/fire";         CONTAINER="pub_fire"        ;;
  *)
    echo "Unknown topic '$SHORT'. Use: temperature | humidity | light | fire"
    exit 1
    ;;
esac

echo "[pub.sh] Publishing to topic '$TOPIC' via container '$CONTAINER'"
echo "[pub.sh] Payload: $MESSAGE"

# -h broker : reach broker via Docker network DNS
# -t <topic>: topic
# -m <msg>  : message payload
docker exec "$CONTAINER" mosquitto_pub -h broker -t "$TOPIC" -m "$MESSAGE"

echo "[pub.sh] Done."
