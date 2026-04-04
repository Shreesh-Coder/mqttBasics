# MQTT Demo — A-to-Z Presentation Guide

A step-by-step script for demonstrating and explaining the MQTT
publish/subscribe pattern using this project. Every step has:

- **Do:** the exact command(s) to run
- **Say:** what to explain to your audience
- **Show:** where to point on screen

Work through it top-to-bottom and you will take an audience from
"what is MQTT?" to "I just watched a real message travel from one
container, through the broker, into another container" in ~10 minutes.

---

## Table of contents

0. [Pre-demo prep (10 min before)](#part-0--pre-demo-prep-10-min-before)
1. [Opening](#part-1--opening-1-min)
2. [Explain the architecture](#part-2--explain-the-architecture-2-min)
3. [Start the stack](#part-3--start-the-stack)
4. [Confirm the broker is listening](#part-4--confirm-the-broker-is-listening)
5. [Show the subscribers waiting](#part-5--show-the-subscribers-waiting)
6. [Confirm the broker sees its clients](#part-6--confirm-the-broker-sees-its-clients)
7. [First publish — the "aha" moment](#part-7--first-publish--the-aha-moment)
8. [Prove the broker actually routed it](#part-8--prove-the-broker-actually-routed-it)
9. [Fire all four topics](#part-9--fire-all-four-topics)
10. [Wildcards](#part-10--wildcards)
11. [Key takeaways](#part-11--key-takeaways-recap)
12. [Q&A prep](#part-12--qa-prep)
13. [Teardown](#part-13--teardown)
14. [Troubleshooting during the demo](#part-14--troubleshooting-during-the-demo)

---

## Part 0 — Pre-demo prep (10 min before)

**Do** — make sure the environment is ready:

```bash
# 1. Docker is installed and running
docker --version
docker compose version

# 2. You are in the project directory
cd mqttBasics   # the directory you cloned into
ls
# expected: README.md  PRESENTATION.md  broker/  docker-compose.yml  scripts/

# 3. Pre-pull images so the demo doesn't stall on network download
docker compose pull

# 4. Optional dry run (start, then stop) to warm everything up
docker compose up -d
docker compose ps        # should show 10 containers
docker compose down
```

**Terminal setup:** plan for **six panes** visible at the same time (tmux,
iTerm2 split panes, or six terminal windows side-by-side):

| Pane | Purpose |
|---|---|
| 1 | `sub_temperature` live log |
| 2 | `sub_humidity` live log |
| 3 | `sub_light` live log |
| 4 | `sub_fire` live log |
| 5 | publisher commands (you type here) |
| 6 | broker event log tail |

---

## Part 1 — Opening (1 min)

**Say:**

> "Today I'm going to show you how MQTT works. MQTT is the messaging
> protocol that powers most IoT systems — from smart homes to industrial
> sensors to connected vehicles. It's built on a pattern called
> publish/subscribe, and we're going to watch real messages travel
> through a real broker in front of you, with no mocks and no slides
> hiding anything."

**Establish three concepts on the whiteboard or a slide:**

1. **Broker** — a server in the middle. Like a post office.
2. **Publisher** — sends a message to a **topic** (e.g. `sensors/temperature`).
   Doesn't know who's listening.
3. **Subscriber** — tells the broker "I want messages on this topic".
   Doesn't know who's publishing.

> "That decoupling — publishers and subscribers never talking directly
> — is the whole point. It's why you can add a new sensor to an IoT
> system without reconfiguring anything else."

---

## Part 2 — Explain the architecture (2 min)

Open `README.md` or show the diagram:

```
   PUBLISHERS                  BROKER                   SUBSCRIBERS
 ┌───────────────┐                                    ┌───────────────┐
 │ pub_temperat. │──sensors/temperature─────────────▶ │ sub_temperat. │
 │ pub_humidity  │──sensors/humidity────────────────▶ │ sub_humidity  │
 │ pub_light     │──home/light──────────────────────▶ │ sub_light     │
 │ pub_fire      │──alerts/fire─────────────────────▶ │ sub_fire      │
 └───────────────┘             │                      └───────────────┘
                               ▼
                      ┌─────────────────┐
                      │    HiveMQ CE    │
                      │  broker :1883   │
                      └─────────────────┘
```

**Say:**

> "Here's what we'll run. One HiveMQ broker in the middle. Four
> publishers, each with its own topic. Four subscribers, each listening
> on one topic. Nine containers total, all started with one
> `docker compose up`. Inside the Docker network the broker is
> reachable as `broker:1883`, and from the host as `localhost:1883`."

---

## Part 3 — Start the stack

**Do** (in pane 5):

```bash
cd mqttBasics   # the directory you cloned into
docker compose up -d
```

**Say while it's starting:**

> "I'm spinning up ten containers in the background. In production you'd
> run the broker on a server and clients on devices; here we're
> compressing the whole system onto one machine so you can see
> everything at once."

**Do:**

```bash
docker compose ps
```

**Say, pointing at the output:**

> "Nine containers, all healthy. `broker` is HiveMQ. The four `sub_*`
> containers are running the `mosquitto_sub` command-line tool, already
> subscribed to their topics. The four `pub_*` containers are idle,
> waiting for me to tell them to publish."

---

## Part 4 — Confirm the broker is listening

**Do:**

```bash
docker logs broker 2>&1 | grep -iE "started|listener"
```

**Say:**

> "HiveMQ has started and opened its TCP listener on port 1883. The
> broker is ready to accept clients."

---

## Part 5 — Show the subscribers waiting

**Do** — in panes 1–4:

```bash
# pane 1
./scripts/sub.sh temperature
# pane 2
./scripts/sub.sh humidity
# pane 3
./scripts/sub.sh light
# pane 4
./scripts/sub.sh fire
```

**Show:** each pane is silent — a cursor, nothing else.

**Say:**

> "Each of these panes is the live log of one subscriber container.
> Each container is running `mosquitto_sub -v`, which connects to the
> broker and subscribes to exactly one topic. Right now they're all
> silent, because nobody has published anything yet. They're waiting."

---

## Part 6 — Confirm the broker sees its clients

HiveMQ Community Edition's **main log** (`docker logs broker`) records
broker startup, listener creation, and extensions — but **not** individual
CONNECT / SUBSCRIBE / PUBLISH events at the default INFO log level. Those
are recorded in HiveMQ's separate **event log** at
`/opt/hivemq/log/event.log` inside the broker container.

**Do** (in pane 6 — show the main log has the broker running):

```bash
docker logs broker 2>&1 | grep -iE "started|listener|extension"
```

**Say:**

> "Here's the main broker log. You can see HiveMQ started, loaded the
> Allow All extension (which lets any client connect — demo only),
> and opened the TCP listener on 1883 for our containers. That's the
> broker running."

Now show the **event log**, filtered to only the clients this demo
generates (mosquitto_pub auto-assigns client IDs starting with `hmq_`):

```bash
docker exec broker sh -c 'grep hmq_ /opt/hivemq/log/event.log | tail -n 20'
```

**Say:**

> "And this is HiveMQ's event log — a separate file that records every
> client connect and disconnect with client ID, IP, and session
> details. I'm filtering for `hmq_` because that's the prefix
> `mosquitto_pub` uses for its auto-generated client IDs. Each publish
> we make will add two more lines here, because `mosquitto_pub`
> connects, sends its message, and disconnects each time."

Start a live tail in pane 6 so the audience can watch events arrive:

```bash
docker exec broker sh -c 'tail -f /opt/hivemq/log/event.log | grep --line-buffered hmq_'
```

> "I'm leaving this tailing in pane 6 so you can watch clients come and
> go in real time as we publish messages."

---

## Part 7 — First publish — the "aha" moment

**Do** (in pane 5):

```bash
./scripts/pub.sh temperature 24.5
```

**Show:** pane 1 (`sub_temperature`) immediately prints:

```
sensors/temperature 24.5
```

**Say (the pivotal moment — take your time here):**

> "Watch pane 1 — the temperature subscriber. I'm about to tell the
> temperature publisher container to publish the value 24.5 to the
> topic `sensors/temperature`.
>
> [run command]
>
> There it is. That message just traveled from a publisher container,
> over TCP, into the HiveMQ broker, through the broker's routing table,
> back out over TCP, into the subscriber container, which printed it to
> its log. End to end, sub-millisecond. Publisher and subscriber never
> talked to each other — the broker handled it."

---

## Part 8 — Prove the broker actually routed it

**Show:** pane 6 — the live-tailed event log already printed two new
lines for the publish you just did: a CONNECT and a graceful DISCONNECT
from `pub_temperature`'s mosquitto_pub client.

If the event log tail pane isn't visible, run this explicitly:

```bash
docker exec broker sh -c 'grep hmq_ /opt/hivemq/log/event.log | tail -n 5'
```

**Say:**

> "And here's the broker's view of that same message. You can see
> `pub_temperature`'s `mosquitto_pub` client connecting, sending its
> PUBLISH, the broker
> receiving it, and the broker forwarding it to `sub_temperature`.
> Every MQTT message passes through the broker — this log is the
> receipt."

---

## Part 9 — Fire all four topics

**Do** (in pane 5):

```bash
./scripts/demo.sh
```

**Show:** all four subscriber panes light up in sequence over ~3
seconds — temperature, humidity, light, fire.

**Say:**

> "Let's do all four at once. [run script] — watch all four panes.
>
> Four independent streams, all multiplexed through the same broker.
> In a real IoT platform this pattern scales to thousands of devices
> and thousands of subscribers — every one of them just talks to the
> broker, and the broker handles the fan-out."

---

## Part 10 — Wildcards

**Do** (in a new pane — call it pane 7, or reuse an empty one):

```bash
docker run --rm -it --network mqttbasics_mqtt_net \
  eclipse-mosquitto:2 mosquitto_sub -h broker -t "sensors/#" -v
```

**Say:**

> "Topics are hierarchical strings separated by slashes. In real
> systems you might see `building/floor2/room7/temperature`. MQTT
> supports wildcards so you can subscribe to a slice of the tree. The
> `#` character means 'everything at and below this point'. I'm
> subscribing to `sensors/#`, which means every topic that starts
> with `sensors/`."

**Do** (in pane 5):

```bash
./scripts/pub.sh temperature 25.0
./scripts/pub.sh humidity 58%
./scripts/pub.sh light ON
```

**Show:** the new wildcard pane (pane 7) receives **`sensors/temperature`
25.0** and **`sensors/humidity` 58%**, but **not** `home/light ON`.

> Pane 3 (`sub_light`) **will** print `home/light ON` — that's its job,
> it's subscribed directly to `home/light`. The point of this exercise is
> not "nobody gets the light message"; the point is that the *wildcard*
> subscriber (pane 7) only got the two `sensors/*` messages. Point at
> pane 7 while saying this, not at pane 3.

**Say:**

> "Watch the new wildcard pane. Temperature landed. Humidity landed.
> Light did not — because `home/light` is not under `sensors/`. Yes,
> `sub_light` over in pane 3 got the light message, because that's its
> direct subscription — that's exactly the behaviour we'd want. But
> this wildcard subscriber is filtering by pattern, and `home/light`
> doesn't match `sensors/#`, so the broker doesn't forward it here.
> This is how real IoT systems organize devices: you name topics
> hierarchically, and each subscriber picks the slice it cares about.
> A dashboard might subscribe to `sensors/#`, an alert system to
> `alerts/#`, and a specific device to its own topic."

**Do:** Ctrl-C to stop the wildcard subscriber in pane 7.

---

## Part 11 — Key takeaways (recap)

**Say, one point at a time:**

1. **Pub/sub decouples producers from consumers.** Publishers and
   subscribers never know about each other. You can add, remove, or
   replace either side without touching the other.
2. **The broker is the beating heart.** Every message flows through it.
   We used HiveMQ Community Edition, which is free and production-grade.
3. **Topics are hierarchical strings with wildcards.** Design the
   hierarchy well and you get a flexible routing system for free.
4. **Every client speaks the same protocol.** `mosquitto_pub`,
   `mosquitto_sub`, and any library in any language all speak MQTT to
   the same broker — you can add a new client without touching the
   others.
5. **It runs anywhere with one command.** `docker compose up` and the
   whole system is live on Linux, macOS, or Windows.

---

## Part 12 — Q&A prep

Expect these and have an answer ready.

**Q: What happens if a subscriber is offline when a message is
published?**
A: With QoS 0 (what we demoed), the message is lost for that subscriber.
MQTT also supports QoS 1 (at-least-once) and QoS 2 (exactly-once), plus
*persistent sessions* where the broker queues messages for an offline
client until it reconnects, and *retained messages* where the broker
always keeps the last message on a topic for new subscribers.

**Q: How fast is MQTT?**
A: On localhost, sub-millisecond. Over LAN, single-digit milliseconds.
The protocol overhead per message is tiny (as little as 2 bytes of
header) — it was designed for constrained networks and battery-powered
devices.

**Q: Is it secure?**
A: This demo has zero security — intentional, for clarity. Production
MQTT supports username/password auth, TLS (usually on port 8883),
client-certificate mutual TLS, and topic-level access-control lists.

**Q: Can multiple publishers publish to the same topic?**
A: Yes, and it's the common case. A hundred temperature sensors all
publishing to `sensors/temperature` is normal — the broker forwards
them all to any matching subscribers.

**Q: Can multiple subscribers subscribe to the same topic?**
A: Yes. The broker fans out a copy to each subscriber. Unlike queues
(e.g. RabbitMQ work queues), MQTT subscribers each get their own copy
by default. MQTT 5 also adds *shared subscriptions* for worker-pool
patterns.

**Q: Why HiveMQ and not Mosquitto?**
A: Both are great MQTT brokers. HiveMQ has very readable logs which
makes it ideal for teaching demos. Mosquitto is lighter and popular on
edge devices. Production choice depends on scale and features.

**Q: What's the difference between HiveMQ Community and Enterprise?**
A: Community Edition is a full MQTT 3.1.1 + 5.0 broker, free, Apache 2.0
licensed. Enterprise adds clustering, the HiveMQ Control Center UI,
additional security extensions, persistent storage, and commercial
support. For this demo CE is plenty.

**Q: How does this compare to Kafka / RabbitMQ / WebSockets?**
A: Kafka is a durable log for high-throughput stream processing —
different use case. RabbitMQ is a more general message broker with
richer routing semantics. Plain WebSockets give you a socket, not a
broker. MQTT is optimized specifically for IoT: small footprint, pub/sub,
QoS levels, last-will messages, retained messages.

---

## Part 13 — Teardown

**Do** (in pane 5):

```bash
docker compose down
```

**Say:**

> "One command, every container stops and is removed. Zero state left
> on the machine. The entire demo is reproducible — anyone in this
> room can run this on their own laptop with two commands: clone the
> repo, `docker compose up`."

For a completely clean slate (removes volumes, networks too):

```bash
docker compose down -v
```

---

## Part 14 — Troubleshooting during the demo

Quick fixes if something breaks on stage.

**"docker compose ps shows some containers as exited"**

```bash
docker compose logs <container_name>
# most common cause: broker wasn't ready yet
docker compose restart <container_name>
```

**"Subscriber pane is empty after a publish"**

```bash
# 1. Is the subscriber actually running?
docker compose ps | grep sub_

# 2. Is the broker receiving the publish?
docker logs broker 2>&1 | tail -n 20

# 3. Restart the subscriber if it's in a bad state
docker compose restart sub_temperature
```

**"Port 1883 already in use"**

Something else on your machine is using that port. Either stop it, or
edit `docker-compose.yml` to change the *host side* of the port
mapping (e.g. `"127.0.0.1:11883:1883"`), then `docker compose up -d`
again.

**"I need a completely clean slate"**

```bash
docker compose down -v
docker compose up -d
```

**Nuclear option — if Docker itself is misbehaving**

```bash
docker compose down -v
docker system prune -f
docker compose pull
docker compose up -d
```

---

## Appendix — One-pager cheat sheet (copy this to a sticky note)

```
# START
cd mqttBasics   # the directory you cloned into
docker compose up -d
docker compose ps

# SUBSCRIBERS (4 panes)
./scripts/sub.sh temperature
./scripts/sub.sh humidity
./scripts/sub.sh light
./scripts/sub.sh fire

# BROKER EVENT LOG (1 pane - per-client connect/disconnect events)
# grep hmq_ filters to just mosquitto_pub clients generated by this demo
docker exec broker sh -c 'tail -f /opt/hivemq/log/event.log | grep --line-buffered hmq_'

# PUBLISH (1 pane)
./scripts/pub.sh temperature 24.5
./scripts/pub.sh humidity 61%
./scripts/pub.sh light ON
./scripts/pub.sh fire "SMOKE DETECTED"
./scripts/demo.sh                 # all four at once

# WILDCARD
docker run --rm -it --network mqttbasics_mqtt_net \
  eclipse-mosquitto:2 mosquitto_sub -h broker -t "sensors/#" -v

# STOP
docker compose down
```
