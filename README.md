# MQTT Basics — A Dockerized Publish/Subscribe Demo

A tiny, beginner-friendly project that shows how MQTT works end to end:
one broker, four publishers, four subscribers, all running in Docker, on
**Windows (PowerShell), WSL, Linux and macOS**. You
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

## How to read the commands in this README

Every command is shown for both worlds. Copy the block that matches the
terminal you are sitting in:

| Label | Terminal | Script flavour |
|-------|----------|----------------|
| 🪟 **Windows** | PowerShell 5.1 or 7+ (Windows Terminal) | `.\scripts\*.ps1` |
| 🐧 **WSL / Linux / macOS** | Ubuntu (WSL), any Linux shell, macOS Terminal, or Git Bash | `./scripts/*.sh` |

When a command is identical in both, it is shown once and labelled
**Same everywhere** — `docker`, `git` and `docker compose` behave the same
in every shell. Only the helper scripts, the shell syntax (`sleep` vs
`Start-Sleep`, `grep` vs `Select-String`) and the install steps differ.

> Everything in this README was run end to end on Windows 11 (PowerShell 7)
> **and** Ubuntu 22.04 under WSL 2, both talking to Docker Desktop.

---

## Prerequisites

You need **Git** and **Docker** (with Compose v2). On Windows, **WSL** is
optional — only needed if you prefer a Linux shell.

### 1. Install the software

🪟 **Windows** — open **PowerShell as Administrator** (right-click Start →
*Terminal (Admin)*):

```powershell
# Git
winget install -e --id Git.Git

# Docker Desktop (includes Docker Engine + Compose v2)
winget install -e --id Docker.DockerDesktop

# OPTIONAL: WSL 2 + Ubuntu, if you want to run everything from a Linux shell
wsl --install -d Ubuntu
```

Then **restart Windows**, launch **Docker Desktop** from the Start menu, and
wait until it says *Engine running*. If you installed WSL, open
Docker Desktop → **Settings → Resources → WSL integration** and switch on
your Ubuntu distro so `docker` works inside WSL too.

🐧 **WSL (Ubuntu) / Debian / Linux Mint**

```bash
sudo apt-get update && sudo apt-get install -y git curl
```

Docker — pick **one** option:

```bash
# Option A (WSL, recommended): use Docker Desktop from Windows.
#   Nothing to install in Ubuntu — just enable WSL integration (see above).

# Option B (native Linux, or WSL without Docker Desktop): Docker Engine + Compose v2
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker "$USER"     # lets you run docker without sudo
newgrp docker                       # apply the group now (or log out/in)
```

> Option B inside WSL runs its *own* Docker engine, separate from Docker
> Desktop. Start it with `sudo service docker start` (WSL without systemd)
> or `sudo systemctl enable --now docker`. Don't run the stack in both
> engines at once — they would fight over port 1883.

🐧 **Other Linux distros / macOS**

```bash
# Fedora / RHEL / CentOS Stream
sudo dnf install -y git
curl -fsSL https://get.docker.com | sudo sh && sudo systemctl enable --now docker

# Arch / Manjaro
sudo pacman -Sy --noconfirm git docker docker-compose && sudo systemctl enable --now docker

# macOS (Homebrew)
brew install git && brew install --cask docker
```

### 2. Check your install

**Same everywhere:**

```bash
git --version
docker --version
docker compose version
docker run --rm hello-world
```

If `docker run --rm hello-world` prints *"Hello from Docker!"* you are ready.
(If it cannot connect to the daemon, see [Troubleshooting](#troubleshooting).)

---

## Project layout

```
mqttBasics/
├── docker-compose.yml     # broker + 4 publishers + 4 subscribers
├── .gitattributes         # forces LF in *.sh so they run in WSL/Linux after a Windows checkout
├── broker/
│   └── config.xml         # minimal HiveMQ CE config (TCP 1883 only)
├── scripts/
│   ├── pub.sh  / pub.ps1      # publish a message to any topic
│   ├── sub.sh  / sub.ps1      # open a live log feed for any subscriber
│   └── demo.sh / demo.ps1     # publish one sample message to all 4 topics
├── examples/
│   ├── py_publisher.py    # Python (paho-mqtt) publisher
│   ├── py_subscriber.py   # Python (paho-mqtt) subscriber, supports wildcards
│   └── requirements.txt
└── README.md
```

`*.sh` = Bash (WSL, Linux, macOS, Git Bash). `*.ps1` = PowerShell (Windows).
They do the same thing; use whichever matches your terminal.

---

## Quick start

**1. Clone the repository** — *same everywhere*:

```bash
git clone https://github.com/Shreesh-Coder/mqttBasics.git
cd mqttBasics
```

> **WSL tip:** clone into the Linux filesystem (`cd ~` first) rather than
> `/mnt/c/...` — it is much faster. Cloning on the Windows side and opening
> it from WSL under `/mnt/...` also works.

**2. Start the broker and all clients** — *same everywhere*:

```bash
docker compose up -d
```

**3. Verify all nine containers are running** — *same everywhere*:

```bash
docker compose ps
```

You should see nine containers: `broker`, the four `sub_*`, and the four
`pub_*`. Give the broker ~5 seconds to finish booting before you publish,
then check for the `Started HiveMQ` banner:

🪟 **Windows**

```powershell
Start-Sleep -Seconds 5
docker logs broker 2>&1 | Select-String "Started HiveMQ|listener"
```

🐧 **WSL / Linux / macOS**

```bash
sleep 5
docker logs broker 2>&1 | grep -iE "started hivemq|listener"
```

**4. When you are done** — *same everywhere*:

```bash
docker compose down
```

---

## Live demo (the main event)

You want four subscriber feeds visible at once, plus one place to publish.

**Option 1 — one window, all four feeds merged** (*same everywhere*, easiest):

```bash
docker compose logs -f sub_temperature sub_humidity sub_light sub_fire
```

**Option 2 — four panes, one subscriber each.** Windows Terminal: split with
`Alt+Shift+-` and `Alt+Shift++`. WSL/Linux: use `tmux` (`Ctrl+b` then `%` or
`"`). macOS: iTerm2 splits (`Cmd+D`). In each pane tail one subscriber:

🪟 **Windows**

```powershell
.\scripts\sub.ps1 temperature     # pane 1
.\scripts\sub.ps1 humidity        # pane 2
.\scripts\sub.ps1 light           # pane 3
.\scripts\sub.ps1 fire            # pane 4
```

🐧 **WSL / Linux / macOS**

```bash
./scripts/sub.sh temperature      # pane 1
./scripts/sub.sh humidity         # pane 2
./scripts/sub.sh light            # pane 3
./scripts/sub.sh fire             # pane 4
```

Each pane sits silently — the subscribers are waiting for messages.

Now open a **fifth pane** and publish:

🪟 **Windows**

```powershell
.\scripts\pub.ps1 temperature 24.5
```

🐧 **WSL / Linux / macOS**

```bash
./scripts/pub.sh temperature 24.5
```

The `sub_temperature` pane immediately prints:

```
sensors/temperature 24.5
```

Do the other three:

🪟 **Windows**

```powershell
.\scripts\pub.ps1 humidity 61%
.\scripts\pub.ps1 light ON
.\scripts\pub.ps1 fire "SMOKE DETECTED IN KITCHEN"
```

🐧 **WSL / Linux / macOS**

```bash
./scripts/pub.sh humidity 61%
./scripts/pub.sh light ON
./scripts/pub.sh fire "SMOKE DETECTED IN KITCHEN"
```

Each subscriber receives exactly its own topic's message (check any of
them with `docker logs sub_<topic>`):

```console
$ docker logs sub_temperature
sensors/temperature 24.5
$ docker logs sub_humidity
sensors/humidity 61%
$ docker logs sub_light
home/light ON
$ docker logs sub_fire
alerts/fire SMOKE DETECTED IN KITCHEN
```

Or fire all four at once:

🪟 **Windows**: `.\scripts\demo.ps1`  
🐧 **WSL / Linux / macOS**: `./scripts/demo.sh`

### Prove the broker is really in the middle

HiveMQ CE's main log records startup and listener info, but per-client
CONNECT / DISCONNECT events are written to a separate event log inside
the broker container. Tail it (*same everywhere*):

```bash
docker exec broker sh -c 'tail -f /opt/hivemq/log/event.log | grep --line-buffered hmq_'
```

`grep hmq_` filters to just the auto-generated client IDs that
`mosquitto_pub` uses. Every time you publish, two new lines appear here —
a CONNECT and a graceful DISCONNECT — which is the broker's own record of
the publisher connecting, sending its PUBLISH, and disconnecting. That is
proof the broker is in the middle. (`Ctrl+C` stops the tail.)

Sample output from a real run — each publish is a `connected` →
`disconnected` pair, and publisher and subscriber never talk to each other
directly:

```console
Client ID: hmq_PFN6Y_5_af7493..., IP: 172.20.0.8, Clean Start: true connected.
Client ID: hmq_PFN6Y_5_af7493..., IP: 172.20.0.8 disconnected gracefully.
Client ID: hmq_PFN6Y_6_502155..., IP: 172.20.0.9, Clean Start: true connected.
Client ID: hmq_PFN6Y_6_502155..., IP: 172.20.0.9 disconnected gracefully.
```

---

## Doing it the "raw" way (no scripts)

The scripts are just sugar. Every command in them is a plain `docker exec`
or `docker logs`, and these are **identical in PowerShell, WSL, Linux and
macOS** — so this is the most portable way to learn.

**Publish a message**

```bash
docker exec pub_temperature mosquitto_pub -h broker -t sensors/temperature -m "24.5"
```

**Watch a subscriber's live feed**

```bash
docker logs -f sub_temperature
```

**Subscribe to ALL topics from a one-off container** (great for showing
wildcards):

```bash
docker run --rm -it --network mqttbasics_mqtt_net eclipse-mosquitto:2 mosquitto_sub -h broker -t "#" -v
```

> The compose file pins the project name to `mqttbasics`, so the network is
> always `mqttbasics_mqtt_net`, whatever folder you cloned into. Stop with
> `Ctrl+C`. In **Git Bash** on Windows put `winpty` in front of `docker run -it`.

---

## Wildcards (subscribing to many topics at once)

A subscriber can use a **topic filter** instead of an exact topic name. The
broker does the matching, so publishers never need to know who is listening.

| Wildcard | Meaning | Rule |
|----------|---------|------|
| `+` | exactly **one** topic level | can appear at any level, e.g. `sensors/+/outdoor` |
| `#` | **everything** from this level down | must be the **last** character, e.g. `sensors/#` |

Wildcards are for **subscribing only** — you always publish to one exact topic.

Using this demo's four topics, here is what each filter receives:

| Filter | `sensors/temperature` | `sensors/humidity` | `home/light` | `alerts/fire` |
|--------|:---:|:---:|:---:|:---:|
| `sensors/temperature` (exact) | ✅ | | | |
| `sensors/+` | ✅ | ✅ | | |
| `+/light` | | | ✅ | |
| `home/#` | | | ✅ | |
| `sensors/#` | ✅ | ✅ | | |
| `#` (everything) | ✅ | ✅ | ✅ | ✅ |

Try them. Run **one** of these in a pane (*same everywhere*), `Ctrl+C` to stop:

```bash
docker run --rm -it --network mqttbasics_mqtt_net eclipse-mosquitto:2 mosquitto_sub -h broker -t "sensors/+" -v
docker run --rm -it --network mqttbasics_mqtt_net eclipse-mosquitto:2 mosquitto_sub -h broker -t "+/light" -v
docker run --rm -it --network mqttbasics_mqtt_net eclipse-mosquitto:2 mosquitto_sub -h broker -t "home/#" -v
docker run --rm -it --network mqttbasics_mqtt_net eclipse-mosquitto:2 mosquitto_sub -h broker -t "#" -v
```

Then fire the demo from another pane and compare with the table:

🪟 **Windows**: `.\scripts\demo.ps1`  
🐧 **WSL / Linux / macOS**: `./scripts/demo.sh`

You can also pass **several filters at once**:

```bash
docker run --rm -it --network mqttbasics_mqtt_net eclipse-mosquitto:2 mosquitto_sub -h broker -t "sensors/#" -t "alerts/+" -v
```

(That one receives temperature, humidity and fire — but not `home/light`.)

---

## How a real system uses this

This demo has four toy topics. A real deployment has thousands of devices,
but the pattern is identical: **devices publish, services subscribe, the
broker routes, and neither side knows about the other.**

**Scenario: a smart building.** Every room has a temperature sensor, a
smoke detector and a smart light. Several independent services care about
different slices of that data.

```
   DEVICES (publish)                     BROKER                  SERVICES (subscribe)

 ┌──────────────────┐                                       ┌───────────────────────┐
 │ room204 sensor   │ acme/b1/f2/r204/temperature           │ Dashboard (web UI)    │
 │ room205 sensor   │ acme/b1/f2/r205/temperature  ┌──────┐ │  sub: acme/b1/#       │
 │ ... 500 more     │─────────────────────────────▶│      │▶└───────────────────────┘
 └──────────────────┘                              │      │ ┌───────────────────────┐
 ┌──────────────────┐                              │ MQTT │▶│ Time-series DB        │
 │ smoke detectors  │ acme/b1/alerts/fire          │broker│ │  sub: acme/#          │
 │                  │─────────────────────────────▶│      │ │  (stores history)     │
 └──────────────────┘                              │      │ └───────────────────────┘
 ┌──────────────────┐                              │      │ ┌───────────────────────┐
 │ smart lights     │◀─ acme/b1/f2/r204/light/set ─│      │▶│ Alert service         │
 │ (also subscribe) │── acme/b1/f2/r204/light ────▶│      │ │  sub: acme/+/alerts/# │
 └──────────────────┘                              └──────┘ │  → SMS / pager        │
                                                      ▲     └───────────────────────┘
 ┌──────────────────┐   acme/b1/f2/r204/light/set     │     ┌───────────────────────┐
 │ Mobile app       │─────────────────────────────────┘     │ Analytics / ML job    │
 │ (user taps "ON") │                                       │  sub: acme/b1/+/+/temperature
 └──────────────────┘                                       └───────────────────────┘
```

**Topic design.** Treat topics like a folder path, general → specific:

```
acme/<building>/<floor>/<room>/<metric>      e.g. acme/b1/f2/r204/temperature
acme/<building>/alerts/<type>                e.g. acme/b1/alerts/fire
```

**Who subscribes to what** (this is where wildcards earn their keep):

| Service | Filter | Why |
|---------|--------|-----|
| Dashboard for the whole building | `acme/b1/#` | everything in building 1 |
| Dashboard for one room | `acme/b1/f2/r204/#` | one room only |
| Average-temperature job | `acme/b1/+/+/temperature` | every room's temperature, nothing else |
| Alert service | `acme/+/alerts/#` | alerts from **every** building |
| Database archiver | `acme/#` | store everything |

**What this gives you:**

- **Decoupling.** Add a new service (say, an energy-saving app) by just
  subscribing — no change to any sensor or other service.
- **Fan-out.** One temperature reading is delivered to the dashboard, the
  database and the analytics job at once; the sensor sends it **once**.
- **Two-way control.** Devices can subscribe too: the mobile app publishes
  `ON` to `.../light/set` and the light, subscribed to that topic, obeys.
- **Cheap on bandwidth and battery.** MQTT headers are tiny and the
  connection stays open, which is why it dominates IoT.

**What a production setup adds on top of this demo** (all supported by
MQTT/HiveMQ, none enabled here):

- **TLS + authentication** (port 8883, usernames or client certificates)
  and per-client **ACLs** so a sensor can publish only to its own topic.
- **QoS 1 / 2** for messages that must not be lost (alerts), QoS 0 for
  high-volume telemetry.
- **Retained messages** so a new dashboard instantly sees each room's *last*
  temperature instead of waiting for the next reading.
- **Last Will** messages so the broker announces a device that dropped
  offline unexpectedly.
- A **clustered broker** (e.g. HiveMQ Enterprise, EMQX, or a cloud service
  like AWS IoT Core) for high availability. HiveMQ **Community** Edition, used
  here, is a single node.

---

## Doing it from Python (programmatically)

Everything the Docker containers do with `mosquitto_pub` / `mosquitto_sub`
you can do from code. The examples use
[`paho-mqtt`](https://pypi.org/project/paho-mqtt/), the standard Python MQTT
client, and connect to the broker's published port `127.0.0.1:1883` — so
they run **on your machine** (Windows or WSL), not inside Docker. Make sure
the stack is up first (`docker compose up -d`).

| File | What it does | Docker equivalent |
|------|--------------|-------------------|
| [`examples/py_subscriber.py`](examples/py_subscriber.py) | subscribe to one or more topic filters and print messages | `mosquitto_sub -t <filter> -v` |
| [`examples/py_publisher.py`](examples/py_publisher.py) | publish one message, or `--demo` for all four topics | `mosquitto_pub -t <topic> -m <msg>` |

### 1. One-time setup

Use a **separate** virtual environment per OS (a Windows venv does not work
inside WSL and vice versa).

🪟 **Windows** (PowerShell, from the repo folder)

```powershell
python -m venv .venv-win
.\.venv-win\Scripts\Activate.ps1
pip install -r examples\requirements.txt
```

> No `python`? `winget install -e --id Python.Python.3.12`, then reopen
> PowerShell. If activation is blocked, see the *running scripts is
> disabled* fix in [Troubleshooting](#troubleshooting).

🐧 **WSL / Linux / macOS** (from the repo folder)

```bash
sudo apt-get update && sudo apt-get install -y python3 python3-venv python3-pip   # Debian/Ubuntu/WSL
python3 -m venv .venv-wsl
source .venv-wsl/bin/activate
pip install -r examples/requirements.txt
```

### 2. Subscribe (pane 1)

🪟 **Windows**

```powershell
python examples\py_subscriber.py "sensors/#" "alerts/+"
```

🐧 **WSL / Linux / macOS**

```bash
python examples/py_subscriber.py "sensors/#" "alerts/+"
```

With no arguments it subscribes to `#` (everything). Leave it running.

### 3. Publish (pane 2, venv activated there too)

🪟 **Windows**

```powershell
python examples\py_publisher.py --demo
python examples\py_publisher.py home/garage OPEN
```

🐧 **WSL / Linux / macOS**

```bash
python examples/py_publisher.py --demo
python examples/py_publisher.py home/garage OPEN
```

Pane 1 prints (note `home/light` and `home/garage` are filtered out — they
match neither `sensors/#` nor `alerts/+`):

```
[py_subscriber] connected; subscribing to ['sensors/#', 'alerts/+']
sensors/temperature 24.5
sensors/humidity 61%
alerts/fire SMOKE DETECTED IN KITCHEN
```

And because it is the same broker, the **Docker** subscribers see the
Python publisher's messages too — `docker logs sub_fire` shows
`alerts/fire SMOKE DETECTED IN KITCHEN`. Python and Docker clients are
interchangeable.

### How the code maps to MQTT

```python
client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
client.connect("127.0.0.1", 1883)           # TCP connect + MQTT CONNECT
client.subscribe([("sensors/#", 0)])        # SUBSCRIBE: standing request to the broker
client.on_message = on_message              # called for every PUBLISH the broker pushes
client.loop_forever()                       # keep the connection open and listen

client.publish("sensors/temperature", "24.5", qos=1)   # PUBLISH
```

---

## Inspecting logs

All of these are *same everywhere*.

| What you want to see                        | Command |
|---------------------------------------------|---------|
| Broker startup / listener / extension info  | `docker logs -f broker` |
| Broker per-client connect/disconnect events | `docker exec broker sh -c 'tail -f /opt/hivemq/log/event.log \| grep --line-buffered hmq_'` |
| Messages received by one subscriber         | `docker logs -f sub_temperature` |
| Last 50 broker log lines                    | `docker logs --tail 50 broker` |
| Everything from every container             | `docker compose logs -f` |
| Just the subscribers                        | `docker compose logs -f sub_temperature sub_humidity sub_light sub_fire` |

---

## Testing / sanity checks

**1. Is the broker accepting connections?** (*same everywhere*)

```bash
docker exec pub_temperature mosquitto_pub -h broker -t test/ping -m "hello"
```

No error output = success. (MQTT publish with default QoS 0 is fire-and-forget;
silence is good.)

**2. Does the subscriber actually receive what the publisher sends?**

Pane A (*same everywhere*):

```bash
docker logs -f sub_light
```

Pane B:

🪟 **Windows**: `.\scripts\pub.ps1 light ON`  
🐧 **WSL / Linux / macOS**: `./scripts/pub.sh light ON`

Pane A should immediately print `home/light ON`.

**3. Do wildcards work?** Run a one-off subscriber on `sensors/#` (*same
everywhere*) and watch temperature and humidity land in the same feed — but
not `home/light`:

```bash
docker run --rm -it --network mqttbasics_mqtt_net eclipse-mosquitto:2 mosquitto_sub -h broker -t "sensors/#" -v
```

Then in another pane:

🪟 **Windows**

```powershell
.\scripts\pub.ps1 temperature 25.1
.\scripts\pub.ps1 humidity 55%
.\scripts\pub.ps1 light OFF
```

🐧 **WSL / Linux / macOS**

```bash
./scripts/pub.sh temperature 25.1
./scripts/pub.sh humidity 55%
./scripts/pub.sh light OFF
```

---

## Troubleshooting

**`Cannot connect to the Docker daemon` / `open //./pipe/dockerDesktopLinuxEngine: The system cannot find the file specified`.**
Docker isn't running. Start it:

🪟 **Windows**

```powershell
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
docker info     # repeat until it prints server details instead of an error
```

🐧 **Linux / WSL with native Docker Engine**

```bash
sudo systemctl start docker        # Linux with systemd
sudo service docker start          # WSL without systemd
```

**`docker: command not found` inside WSL.**
Docker Desktop → Settings → Resources → **WSL integration** → enable your
distro → Apply. Or install Docker Engine inside WSL (Prerequisites, Option B).

**`permission denied ... /var/run/docker.sock` on Linux/WSL.**

```bash
sudo usermod -aG docker "$USER" && newgrp docker
```

**`/usr/bin/env: 'bash\r': Permission denied` (or `No such file or directory`) when running `./scripts/*.sh` in WSL/Linux.**
The scripts were checked out with Windows (CRLF) line endings. The repo now
ships a `.gitattributes` that prevents this; if you cloned an older version,
`git pull` and convert once:

```bash
sed -i 's/\r$//' scripts/*.sh && chmod +x scripts/*.sh
```

On Windows you can skip all of this and use the `.ps1` scripts.

**`cannot be loaded because running scripts is disabled on this system` (PowerShell).**
Allow local scripts for your user, or bypass for a single run:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
# or, one-off:
powershell -ExecutionPolicy Bypass -File .\scripts\pub.ps1 temperature 24.5
```

**Port 1883 is already in use.**
Another MQTT broker is running on your machine. Find it:

🪟 **Windows**: `netstat -ano | findstr :1883`  
🐧 **WSL / Linux**: `sudo ss -ltnp | grep 1883` (macOS: `lsof -i :1883`)

Then stop it, or change the host side of the port mapping in
`docker-compose.yml`:

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
   received it but is not forwarding — check that the topic you published to
   matches the topic the subscriber is listening on.

**I want a clean slate** (*same everywhere*).

```bash
docker compose down -v
docker compose up -d
```

**Wrong network name in the one-off subscriber command.**
List networks and use the actual name:

🪟 **Windows**: `docker network ls | Select-String mqtt`  
🐧 **WSL / Linux / macOS**: `docker network ls | grep mqtt`

---

## How to extend

Add a new topic in four steps. Say you want `garage/door`:

1. In `docker-compose.yml`, copy an existing `sub_*` block and change:
   - `container_name: sub_garage`
   - the topic in the `command:` line → `garage/door`

2. Copy an existing `pub_*` block and change:
   - `container_name: pub_garage`

3. Teach the helper scripts about it:
   - **Bash:** in `scripts/pub.sh` and `scripts/sub.sh`, add a `garage)` branch to the `case`.
   - **PowerShell:** in `scripts/pub.ps1` add `garage` to `ValidateSet` and to the `$map` table; in `scripts/sub.ps1` add `garage` to `ValidateSet`.

4. Restart the stack (*same everywhere*):

```bash
docker compose up -d
```

Then publish:

🪟 **Windows**: `.\scripts\pub.ps1 garage OPEN`  
🐧 **WSL / Linux / macOS**: `./scripts/pub.sh garage OPEN`

---

## More guides

- [`LINUX_SETUP.md`](LINUX_SETUP.md) — bare-Linux walkthrough
- [`mqtt_windows_full_setup (1).md`](<mqtt_windows_full_setup (1).md>) — Windows + WSL from scratch
- [`PRESENTATION.md`](PRESENTATION.md) — talking points for presenting the demo

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
