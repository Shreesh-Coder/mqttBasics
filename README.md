# MQTT Basics — A Dockerized Publish/Subscribe Demo

A tiny, beginner-friendly project that shows how MQTT works end to end:
one broker, four publishers, four subscribers, all running in Docker. You
will watch messages travel from a publisher, through the broker, into a
subscriber — live, from your terminal.

---

## What you will see

- A real MQTT broker (**HiveMQ Community Edition**) running in Docker.
- Four independent publisher containers, one per topic.
- Four independent subscriber containers, one per topic.
- Every message a subscriber receives is printed to its container log, so
  `docker logs` is your live message feed.
- HiveMQ's event log records every client connect/disconnect so you can
  prove the broker is actually in the middle.

### Topic map

| Publisher container | Topic                  | Subscriber container |
|---------------------|------------------------|----------------------|
| `pub_temperature`   | `sensors/temperature`  | `sub_temperature`    |
| `pub_humidity`      | `sensors/humidity`     | `sub_humidity`       |
| `pub_light`         | `home/light`           | `sub_light`          |
| `pub_fire`          | `alerts/fire`          | `sub_fire`           |

### Architecture

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

All nine containers live on one Docker bridge network called `mqtt_net`.
Inside that network the broker is reachable at `broker:1883`. From your
host it is reachable at `127.0.0.1:1883`.

---

## Prerequisites

- **Docker** (Desktop on macOS/Windows, or Engine on Linux)
- **Docker Compose v2** (included with Docker Desktop; on Linux install
  `docker-compose-plugin`)
- A terminal — Bash/Zsh on macOS/Linux, Git Bash or WSL on Windows

Check your install:

```bash
docker --version
docker compose version
```

---

## Project layout

```
mqttBasics/
├── docker-compose.yml     # broker + 4 publishers + 4 subscribers
├── broker/
│   └── config.xml         # minimal HiveMQ CE config (TCP 1883 only)
├── scripts/
│   ├── pub.sh             # publish a message to any topic
│   ├── sub.sh             # open a live log feed for any subscriber
│   └── demo.sh            # publish one sample message to all 4 topics
└── README.md
```

---

## Quick start

```bash
# 1. Clone the repository
git clone https://github.com/Shreesh-Coder/mqttBasics.git
cd mqttBasics

# 2. Make the helper scripts executable (only needed on Linux/macOS after a fresh clone)
chmod +x scripts/*.sh

# 3. Start the broker and all clients in the background
docker compose up -d

# 4. Verify every container is running
docker compose ps
```

You should see nine containers: `broker`, the four `sub_*`, and the four
`pub_*`. Give the broker ~5 seconds to finish booting before you publish
anything.

Check the broker is ready by looking for the "Started HiveMQ" banner:

```bash
docker logs broker | tail -n 20
```

When you are done:

```bash
docker compose down
```

---

## Live demo (the main event)

Open **four terminal windows / tmux panes / iTerm2 splits**. In each one,
tail a different subscriber so your audience can see all four topics at
once:

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

Each pane will sit silently — the subscribers are waiting for messages.

Now open a **fifth pane** and publish:

```bash
./scripts/pub.sh temperature 24.5
```

The `sub_temperature` pane will immediately print:

```
sensors/temperature 24.5
```

Do the other three:

```bash
./scripts/pub.sh humidity 61%
./scripts/pub.sh light ON
./scripts/pub.sh fire "SMOKE DETECTED IN KITCHEN"
```

Or fire all four at once:

```bash
./scripts/demo.sh
```

### Prove the broker is really in the middle

HiveMQ CE's main log records startup and listener info, but per-client
CONNECT / DISCONNECT events are written to a separate event log inside
the broker container. Tail it like this:

```bash
docker exec broker sh -c 'tail -f /opt/hivemq/log/event.log | grep --line-buffered hmq_'
```

`grep hmq_` filters to just the auto-generated client IDs that
`mosquitto_pub` uses. Every time you run `./scripts/pub.sh ...`, two new
lines appear here — a CONNECT and a graceful DISCONNECT — which is the
broker's own record of the publisher client connecting, sending its
PUBLISH, and disconnecting. That is proof the broker is in the middle.

---

## Doing it the "raw" way (no scripts)

The scripts are just sugar. Every command in them is a plain `docker exec`
or `docker logs`. Here is what actually runs:

**Publish a message**

```bash
docker exec pub_temperature \
  mosquitto_pub -h broker -t sensors/temperature -m "24.5"
```

**Watch a subscriber's live feed**

```bash
docker logs -f sub_temperature
```

**Subscribe to ALL topics from a one-off container** (great for showing
wildcards):

```bash
docker run --rm -it --network mqttbasics_mqtt_net \
  eclipse-mosquitto:2 mosquitto_sub -h broker -t "#" -v
```

> The network name follows the pattern `<project>_<network>`. If
> `docker network ls` shows a different name, use that one.

---

## Inspecting logs

| What you want to see                      | Command                              |
|-------------------------------------------|--------------------------------------|
| Broker startup / listener / extension info | `docker logs -f broker`             |
| Broker per-client connect/disconnect events | `docker exec broker sh -c 'tail -f /opt/hivemq/log/event.log \| grep --line-buffered hmq_'` |
| Messages received by one subscriber       | `docker logs -f sub_temperature`     |
| Last 50 broker log lines                  | `docker logs --tail 50 broker`       |
| Everything from every container           | `docker compose logs -f`             |
| Just the subscribers                      | `docker compose logs -f sub_temperature sub_humidity sub_light sub_fire` |

---

## Testing / sanity checks

**1. Is the broker accepting connections?**

```bash
docker exec pub_temperature mosquitto_pub -h broker -t test/ping -m "hello"
```

No error output = success. (MQTT publish with default QoS 0 is fire-and-forget;
silence is good.)

**2. Does the subscriber actually receive what the publisher sends?**

```bash
# Pane A
docker logs -f sub_light

# Pane B
./scripts/pub.sh light ON
```

Pane A should immediately print `home/light ON`.

**3. Do wildcards work?** Run a one-off subscriber on `sensors/#` and watch
both temperature and humidity publishes land in the same feed:

```bash
docker run --rm -it --network mqttbasics_mqtt_net \
  eclipse-mosquitto:2 mosquitto_sub -h broker -t "sensors/#" -v
```

Then in another pane:

```bash
./scripts/pub.sh temperature 25.1
./scripts/pub.sh humidity 55%
```

---

## Troubleshooting

**Port 1883 is already in use.**
Another MQTT broker is running on your machine. Either stop it, or change
the host side of the port mapping in `docker-compose.yml`:

```yaml
ports:
  - "127.0.0.1:11883:1883"   # change the host port only; container port stays 1883
```

Containers inside the compose network are unaffected; only host-side
clients need to use the new port.

**`docker exec` says "No such container".**
The stack is not up. Run `docker compose ps` — if it is empty, run
`docker compose up -d`.

**Subscriber pane shows nothing when I publish.**
Check three things in order:

1. `docker compose ps` — is `sub_<topic>` in state `running`? If it
   `exited`, the broker probably was not ready when it started. Run
   `docker compose restart sub_<topic>`.
2. `docker logs sub_<topic>` — any error from `mosquitto_sub`?
3. `docker logs broker` — does it show your publish? If yes, the broker
   received it but is not forwarding — check that the topic in `pub.sh`
   matches the topic the subscriber is listening on.

**I want a clean slate.**

```bash
docker compose down -v
docker compose up -d
```

**Wrong network name in the one-off subscriber command.**
List networks and use the actual name:

```bash
docker network ls | grep mqtt
```

---

## How to extend

Add a new topic in three steps. Say you want `garage/door`:

1. In `docker-compose.yml`, copy an existing `sub_*` block and change:
   - `container_name: sub_garage`
   - the topic in the `command:` line → `garage/door`

2. Copy an existing `pub_*` block and change:
   - `container_name: pub_garage`

3. In `scripts/pub.sh` and `scripts/sub.sh`, add a new `case` branch for
   `garage`.

Restart the stack: `docker compose up -d`. Publish with
`./scripts/pub.sh garage OPEN`.

---

## A note on security

This demo intentionally has **no authentication and no TLS**. The broker
accepts anonymous clients on plain TCP. That keeps the demo simple and the
logs uncluttered. **Do not use this configuration in production.** In a
real deployment you would enable:

- username/password or client-certificate authentication
- TLS on port 8883
- an access-control list (ACL) restricting which clients can publish or
  subscribe to which topics
