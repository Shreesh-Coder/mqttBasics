# Linux Setup Guide — mqttBasics
**Zero prerequisites assumed. Works on any modern Linux distro.**

> Gets you from a bare Linux machine to a fully running HiveMQ CE broker
> + 4 publishers + 4 subscribers in under 10 minutes.

---

## What this project runs

| Container | Image | Role |
|---|---|---|
| `broker` | `hivemq/hivemq-ce:latest` | MQTT broker, TCP port 1883 |
| `pub_temperature` | `eclipse-mosquitto:2` | Publishes to `sensors/temperature` |
| `pub_humidity` | `eclipse-mosquitto:2` | Publishes to `sensors/humidity` |
| `pub_light` | `eclipse-mosquitto:2` | Publishes to `home/light` |
| `pub_fire` | `eclipse-mosquitto:2` | Publishes to `alerts/fire` |
| `sub_temperature` | `eclipse-mosquitto:2` | Subscribes to `sensors/temperature` |
| `sub_humidity` | `eclipse-mosquitto:2` | Subscribes to `sensors/humidity` |
| `sub_light` | `eclipse-mosquitto:2` | Subscribes to `home/light` |
| `sub_fire` | `eclipse-mosquitto:2` | Subscribes to `alerts/fire` |

All 9 containers share a Docker bridge network called `mqtt_net`.
**Publishers** sit idle (`tail -f /dev/null`) — you trigger them via
`docker exec` or `./scripts/pub.sh`. **Subscribers** run `mosquitto_sub -v`
continuously — output appears in `docker logs sub_*`.

---

## Step 1 — Install Git

```bash
# Ubuntu / Debian / Linux Mint
sudo apt-get update && sudo apt-get install -y git

# Fedora / RHEL / CentOS Stream
sudo dnf install -y git

# Arch / Manjaro
sudo pacman -Sy --noconfirm git

# openSUSE
sudo zypper install -y git
```

Verify:
```bash
git --version
# git version 2.x.x
```

---

## Step 2 — Install Docker Engine

> ⚠️ Do **not** use `snap install docker` — it breaks volume mounts needed
> for `broker/config.xml`. Use the official method below.

### Ubuntu / Debian / Linux Mint

```bash
# Remove any old Docker packages
sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# Install dependencies
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg

# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the Docker apt repository
# Linux Mint users: replace VERSION_CODENAME with your Ubuntu base codename
# (e.g. "jammy" for Mint 21.x, "noble" for Mint 22.x)
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine + Compose plugin in one go
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin
```

### Fedora / RHEL / CentOS Stream

```bash
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo \
  https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin
```

### Arch / Manjaro

```bash
sudo pacman -Sy --noconfirm docker docker-compose
```

### Start Docker and enable on boot

```bash
sudo systemctl start docker
sudo systemctl enable docker
```

### Allow running Docker without sudo

```bash
sudo usermod -aG docker $USER
newgrp docker        # applies to the current terminal immediately
```

Verify everything works:
```bash
docker --version        # Docker version 26.x.x or newer
docker compose version  # Docker Compose version v2.x.x
docker run --rm hello-world
```

The last command should print `Hello from Docker!`.

---

## Step 3 — Clone the Repository

```bash
git clone https://github.com/Shreesh-Coder/mqttBasics.git
cd mqttBasics
```

Make the helper scripts executable (required on Linux after a fresh clone):
```bash
chmod +x scripts/*.sh
```

Confirm the project layout:
```
mqttBasics/
├── docker-compose.yml      ← broker + 8 clients
├── broker/
│   └── config.xml          ← minimal HiveMQ config (TCP 1883 only)
├── scripts/
│   ├── pub.sh              ← publish to any topic
│   ├── sub.sh              ← tail any subscriber's live log
│   └── demo.sh             ← publish one message to all 4 topics
└── README.md
```

---

## Step 4 — Start the Stack

```bash
docker compose up -d
```

On first run Docker pulls `hivemq/hivemq-ce:latest` and
`eclipse-mosquitto:2`. This takes **2–5 minutes** on a typical connection.
Every subsequent start is instant.

Check all 9 containers are running:
```bash
docker compose ps
```

Expected:
```
NAME              STATUS
broker            Up X seconds
pub_fire          Up X seconds
pub_humidity      Up X seconds
pub_light         Up X seconds
pub_temperature   Up X seconds
sub_fire          Up X seconds
sub_humidity      Up X seconds
sub_light         Up X seconds
sub_temperature   Up X seconds
```

Wait ~5 seconds, then confirm the broker is fully ready:
```bash
docker logs broker 2>&1 | grep -iE "started|listener"
```

Look for these two lines before you publish anything:
```
INFO  - Started TCP Listener on address 0.0.0.0 and on port 1883.
INFO  - Started HiveMQ in XXXX ms
```

---

## Step 5 — Publish Messages

### Using the helper script

```bash
./scripts/pub.sh temperature 24.5
./scripts/pub.sh humidity 61%
./scripts/pub.sh light ON
./scripts/pub.sh fire "SMOKE DETECTED IN KITCHEN"
```

Fire all four at once:
```bash
./scripts/demo.sh
```

### Using docker exec directly (what the script does under the hood)

```bash
docker exec pub_temperature \
  mosquitto_pub -h broker -t sensors/temperature -m "24.5"

docker exec pub_humidity \
  mosquitto_pub -h broker -t sensors/humidity -m "61%"

docker exec pub_light \
  mosquitto_pub -h broker -t home/light -m "ON"

docker exec pub_fire \
  mosquitto_pub -h broker -t alerts/fire -m "SMOKE DETECTED IN KITCHEN"
```

---

## Step 6 — Read the Subscriber Output

Each subscriber prints every received message in `topic payload` format.

```bash
docker logs sub_temperature
# sensors/temperature 24.5

docker logs sub_humidity
# sensors/humidity 61%

docker logs sub_light
# home/light ON

docker logs sub_fire
# alerts/fire SMOKE DETECTED IN KITCHEN
```

Live feed (stays open, prints new messages as they arrive):
```bash
docker logs -f sub_temperature
```

Or use the helper script:
```bash
./scripts/sub.sh temperature
```

---

## Step 7 — Live Demo (4 panes at once)

Open four terminals (or tmux/screen panes). Tail one subscriber per pane:

```bash
# Pane 1
./scripts/sub.sh temperature

# Pane 2
./scripts/sub.sh humidity

# Pane 3
./scripts/sub.sh light

# Pane 4
./scripts/sub.sh fire
```

In a **fifth pane**, publish and watch each matching pane update instantly:
```bash
./scripts/pub.sh temperature 24.5
./scripts/pub.sh humidity 61%
./scripts/pub.sh light ON
./scripts/pub.sh fire "SMOKE DETECTED IN KITCHEN"
```

---

## Step 8 — Prove the Broker Is in the Middle

HiveMQ CE writes connect/disconnect events to a dedicated event log inside
the container. Tail it while you publish:

```bash
docker exec broker sh -c \
  'tail -f /opt/hivemq/log/event.log | grep --line-buffered hmq_'
```

Every `pub.sh` call produces two lines — a **CONNECT** and a graceful
**DISCONNECT** — which is the broker's own receipt proving it received,
routed, and forwarded the message. Publisher and subscriber never spoke
directly; the broker handled every hop.

---

## Stop the Stack

```bash
# Stop and remove containers (images stay — next start is instant)
docker compose down

# Full clean slate (removes containers + volumes)
docker compose down -v
```

---

## Useful Commands Reference

| What you want | Command |
|---|---|
| Broker startup info | `docker logs -f broker` |
| Broker per-client events | `docker exec broker sh -c 'tail -f /opt/hivemq/log/event.log \| grep --line-buffered hmq_'` |
| One subscriber live | `docker logs -f sub_temperature` |
| All containers at once | `docker compose logs -f` |
| Only subscribers | `docker compose logs -f sub_temperature sub_humidity sub_light sub_fire` |
| Last 50 broker lines | `docker logs --tail 50 broker` |
| Subscribe to ALL topics (wildcard) | `docker run --rm -it --network mqttbasics_mqtt_net eclipse-mosquitto:2 mosquitto_sub -h broker -t "#" -v` |

> If the wildcard network name errors, check with: `docker network ls | grep mqtt`

---

## Troubleshooting

**Port 1883 already in use**
```bash
sudo lsof -i :1883            # find the process using it
sudo systemctl stop mosquitto # if it is the mosquitto service
```
Or change only the host-side port in `docker-compose.yml`
(containers are unaffected — they talk over `mqtt_net`, not the host port):
```yaml
ports:
  - "127.0.0.1:11883:1883"
```

**A container shows `Exited` in `docker compose ps`**
```bash
docker compose logs broker    # check broker for errors first
docker compose up -d          # restart anything that exited
```

**Subscriber shows nothing after publishing**

1. `docker compose ps` — confirm `sub_<topic>` is `running`, not `exited`
2. If it exited: `docker compose restart sub_temperature`
3. `docker logs broker` — check the broker received the publish
4. Topics are **case-sensitive** — confirm `pub.sh` and `sub`'s topic match exactly

**`permission denied` on docker commands**
```bash
sudo usermod -aG docker $USER
newgrp docker
```

**`chmod: cannot access 'scripts/*.sh'` on fresh clone**
```bash
ls scripts/   # confirm the files are there
chmod +x scripts/pub.sh scripts/sub.sh scripts/demo.sh
```

---

## Quick-Start Cheat Sheet

```bash
# 1. Install git + docker (run the commands for your distro above)

# 2. Clone & enter
git clone https://github.com/Shreesh-Coder/mqttBasics.git
cd mqttBasics
chmod +x scripts/*.sh

# 3. Start all 9 containers
docker compose up -d

# 4. Confirm broker is ready
docker logs broker 2>&1 | grep Started

# 5. Publish
./scripts/pub.sh temperature 24.5

# 6. Read
docker logs sub_temperature

# 7. Demo all 4 topics at once
./scripts/demo.sh

# 8. Stop
docker compose down
```
