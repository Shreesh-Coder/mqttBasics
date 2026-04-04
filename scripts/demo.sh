#!/usr/bin/env bash
# =============================================================================
# demo.sh - Fire one sample message to each of the four demo topics in order.
#
# Run this while you have four terminal panes open, each tailing one of the
# subscribers (see README "Live demo" section). Each message should appear in
# its corresponding subscriber pane within a fraction of a second.
#
# Usage:
#   ./scripts/demo.sh
# =============================================================================

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
PUB="$HERE/pub.sh"

echo "[demo.sh] Publishing demo messages to all four topics..."
echo

"$PUB" temperature "24.5"
sleep 1

"$PUB" humidity "61%"
sleep 1

"$PUB" light "ON"
sleep 1

"$PUB" fire "SMOKE DETECTED IN KITCHEN"

echo
echo "[demo.sh] Done. Check each subscriber's log to see the message land."
echo "[demo.sh] Example: docker logs sub_fire"
