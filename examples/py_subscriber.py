"""
py_subscriber.py - Subscribe to one or more MQTT topic filters and print
every message. The Python twin of:

    docker logs -f sub_temperature        (or)
    mosquitto_sub -h broker -t "sensors/#" -v

Usage:
    python examples/py_subscriber.py                      # everything ("#")
    python examples/py_subscriber.py sensors/temperature  # one exact topic
    python examples/py_subscriber.py "sensors/#" alerts/+ # several filters

Connects to the broker's port published on THIS machine (127.0.0.1:1883),
so it runs from the host (Windows or WSL/Linux), not from inside Docker.
"""
import sys

import paho.mqtt.client as mqtt

BROKER_HOST = "127.0.0.1"
BROKER_PORT = 1883
FILTERS = sys.argv[1:] or ["#"]


def on_connect(client, userdata, flags, reason_code, properties):
    if reason_code.is_failure:
        sys.exit(f"[py_subscriber] connect failed: {reason_code}")
    print(f"[py_subscriber] connected; subscribing to {FILTERS}", flush=True)
    # Subscribing is a standing request: "send me anything matching these".
    client.subscribe([(f, 0) for f in FILTERS])  # (topic filter, QoS 0)


def on_message(client, userdata, msg):
    print(f"{msg.topic} {msg.payload.decode(errors='replace')}", flush=True)


client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
client.on_connect = on_connect
client.on_message = on_message
client.connect(BROKER_HOST, BROKER_PORT)

try:
    client.loop_forever()  # blocks; the library handles keep-alives/reconnects
except KeyboardInterrupt:
    print("\n[py_subscriber] bye")
