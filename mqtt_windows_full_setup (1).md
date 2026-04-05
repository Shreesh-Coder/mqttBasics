# MQTT Docker Project — Full Setup Guide (Windows A → Z)

This guide assumes:
- ❌ Nothing is installed
- ✅ Fresh Windows machine

---

# 🚀 OVERVIEW

You will install:

- WSL (Windows Subsystem for Linux)
- Ubuntu (Linux environment)
- Docker Desktop
- Git
- MQTT project

---

# 🧱 PART 1 — Install WSL + Ubuntu (Command Only)

## Step 1: Open PowerShell as Administrator

Right-click Start → **Windows Terminal (Admin)**

## Step 2: Install WSL + Ubuntu

```powershell
wsl --install -d Ubuntu
```

## Step 3: Restart your system

---

# 🐧 PART 2 — Setup Ubuntu

## Step 1: Open Ubuntu

Search: Ubuntu → Open

## Step 2: Create user

You will see:

```
Enter new UNIX username:
Enter new UNIX password:
```

Create any username/password.

## Step 3: Update system

```bash
sudo apt update
sudo apt upgrade -y
```

---

# 🐳 PART 3 — Install Docker Desktop

## Step 1: Download Docker Desktop

Go to: https://www.docker.com/products/docker-desktop/

Install it.

## Step 2: Open Docker Desktop

Wait until:

```
Docker Desktop is running
```

---

# 🔗 PART 4 — Enable Docker in Ubuntu

1. Open Docker Desktop
2. Go to:

```
Settings → Resources → WSL Integration
```

3. Enable:

```
✔ Ubuntu
```

4. Click:

```
Apply & Restart
```

---

# ✅ PART 5 — Verify Docker

Open Ubuntu terminal:

```bash
docker version
```

Expected:

```
Client: OK
Server: OK
```

---

# 📦 PART 6 — Install Git

```bash
sudo apt install -y git
```

---

# 📥 PART 7 — Clone Project

```bash
git clone https://github.com/Shreesh-Coder/mqttBasics.git
cd mqttBasics
```

---

# 🔧 PART 8 — Fix Script Permissions

```bash
chmod +x scripts/*.sh
```

---

# ▶️ PART 9 — Start MQTT System

```bash
docker compose up -d
```

Wait 5–10 seconds.

---

# 📊 PART 10 — Verify Containers

```bash
docker compose ps
```

Expected containers:

- `broker`
- `pub_temperature`
- `sub_temperature`
- etc.

---

# 📜 PART 11 — Check Broker Logs

```bash
docker logs broker --tail 20
```

---

# 📡 PART 12 — Publish Message

```bash
./scripts/pub.sh temperature 24.5
```

---

# 📥 PART 13 — Check Subscriber Output

```bash
docker logs sub_temperature
```

Expected:

```
sensors/temperature 24.5
```

---

# 🎬 PART 14 — Live Demo (Optional)

Open multiple terminals:

**Terminal 1**
```bash
./scripts/sub.sh temperature
```

**Terminal 2**
```bash
./scripts/sub.sh humidity
```

**Terminal 3**
```bash
./scripts/sub.sh light
```

**Terminal 4**
```bash
./scripts/sub.sh fire
```

**Terminal 5**
```bash
./scripts/demo.sh
```

---

# ⛔ PART 15 — Stop System

```bash
docker compose down
```

---

# 🛠 TROUBLESHOOTING

## Docker not working

- Open Docker Desktop
- Ensure it is running

## Docker not found in Ubuntu

- Enable WSL Integration in Docker Desktop

## Permission denied

```bash
chmod +x scripts/*.sh
```

## Containers not starting

```bash
docker compose down -v
docker compose up -d
```

## Wrong environment

❌ DO NOT use:

```
docker-desktop
```

✅ USE:

```
Ubuntu
```

---

# 🧠 IMPORTANT CONCEPTS

- WSL provides Linux inside Windows
- Docker runs Linux containers using WSL
- MQTT broker handles message routing

---

# ✅ FINAL RESULT

You now have:

- MQTT broker running
- Publishers sending messages
- Subscribers receiving messages
- Full Docker-based system working

---

# ⚡ QUICK TEST

```bash
docker exec pub_temperature mosquitto_pub -h broker -t sensors/temperature -m "99"
docker logs sub_temperature
```

If you see `99`, everything is working perfectly 🚀
