#!/usr/bin/env bash
# =============================================================================
# sub.sh - Tail a subscriber container's live log.
#
# Each subscriber container runs `mosquitto_sub -v` in the foreground, which
# means every received MQTT message is written to the container's stdout.
# `docker logs -f` therefore shows us a live feed of incoming messages.
#
# Usage:
#   ./scripts/sub.sh <short_topic>
#
# short_topic is one of:
#   temperature | humidity | light | fire
#
# Example:
#   ./scripts/sub.sh temperature
# =============================================================================

set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <temperature|humidity|light|fire>"
  exit 1
fi

SHORT="$1"

case "$SHORT" in
  temperature) CONTAINER="sub_temperature" ;;
  humidity)    CONTAINER="sub_humidity"    ;;
  light)       CONTAINER="sub_light"       ;;
  fire)        CONTAINER="sub_fire"        ;;
  *)
    echo "Unknown topic '$SHORT'. Use: temperature | humidity | light | fire"
    exit 1
    ;;
esac

echo "[sub.sh] Live feed for '$CONTAINER'. Press Ctrl+C to stop."
docker logs -f "$CONTAINER"
