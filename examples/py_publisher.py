"""
py_publisher.py - Publish messages to the broker. The Python twin of:

    docker exec pub_temperature mosquitto_pub -h broker -t sensors/temperature -m 24.5

Usage:
    python examples/py_publisher.py sensors/temperature 24.5   # one message
    python examples/py_publisher.py --demo                     # all 4 demo topics
"""
import sys

import paho.mqtt.client as mqtt

BROKER_HOST = "127.0.0.1"
BROKER_PORT = 1883

DEMO = [
    ("sensors/temperature", "24.5"),
    ("sensors/humidity", "61%"),
    ("home/light", "ON"),
    ("alerts/fire", "SMOKE DETECTED IN KITCHEN"),
]

if sys.argv[1:] == ["--demo"]:
    messages = DEMO
elif len(sys.argv) >= 3:
    messages = [(sys.argv[1], " ".join(sys.argv[2:]))]
else:
    sys.exit(__doc__)

client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
client.connect(BROKER_HOST, BROKER_PORT)
client.loop_start()  # background network thread so publishes actually get sent

for topic, payload in messages:
    info = client.publish(topic, payload, qos=1)  # QoS 1 = broker acknowledges
    info.wait_for_publish()
    print(f"[py_publisher] {topic} <- {payload}")

client.loop_stop()
client.disconnect()
