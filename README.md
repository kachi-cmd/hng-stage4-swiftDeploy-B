# hng-stage4-swiftDeploy

> Declarative deployment CLI — `manifest.yaml` is the single source of truth.
> Serves traffic over HTTPS using Let's Encrypt certificates.

## Project Structure
hng-stage4-swiftDeploy/
├── manifest.yaml               # ← ONLY file you edit
├── swiftdeploy                 # CLI executable (Python)
├── Dockerfile                  # Builds the API service image
├── app/
│   └── main.py                 # Python HTTP service (stdlib only)
├── templates/
│   ├── nginx.conf.j2           # Nginx config template
│   └── docker-compose.yml.j2  # Compose config template
├── certs/
│   ├── fullchain.pem           # Let's Encrypt certificate
│   └── privkey.pem             # Let's Encrypt private key
└── README.md

Generated on first run (do not edit):
- `nginx.conf` — rendered from template
- `docker-compose.yml` — rendered from template

---

## Prerequisites

| Tool | Version |
|------|---------|
| Docker | ≥ 24 |
| Docker Compose | v2 |
| Python | ≥ 3.9 |
| PyYAML | `pip3 install pyyaml` |
| Jinja2 | `pip3 install jinja2` |
| certbot | For issuing Let's Encrypt certificates |

---

## Setup Instructions

### 1. Clone the repository

```bash
git clone https://github.com/YOUR_USERNAME/hng-stage4-swiftDeploy.git
cd hng-stage4-swiftDeploy
```

### 2. Issue HTTPS certificate (first time only)

Make sure your domain points to your server's public IP, then:

```bash
sudo certbot certonly --standalone -d kchiii.duckdns.org \
  --email your@email.com --agree-tos --non-interactive
```

Copy certificates into the project:

```bash
sudo cp /etc/letsencrypt/archive/kchiii.duckdns.org/fullchain1.pem certs/fullchain.pem
sudo cp /etc/letsencrypt/archive/kchiii.duckdns.org/privkey1.pem certs/privkey.pem
sudo chown $USER:$USER certs/*.pem
```

### 3. Build the Docker image

```bash
docker build -t swift-deploy-1-node:latest .
```

### 4. Install Python dependencies

```bash
pip3 install pyyaml jinja2 --break-system-packages
```

---

## Subcommand Walkthrough

### `init` — Generate config files from manifest

```bash
./swiftdeploy init
```

Reads `manifest.yaml` and renders:
- `nginx.conf` — Nginx reverse proxy config with HTTPS
- `docker-compose.yml` — full stack definition

Nothing runs yet. This is purely file generation.

---

### `validate` — Run 5 pre-flight checks

```bash
./swiftdeploy validate
```

Checks in order:

| # | Check | Fails when |
|---|-------|-----------|
| 1 | manifest.yaml exists and is valid YAML | File missing or syntax error |
| 2 | All required fields present and non-empty | Any field is missing |
| 3 | Docker image exists locally | Image not built yet |
| 4 | HTTPS port 443 is free on host | Another process is using 443 |
| 5 | nginx.conf is syntactically valid | Template rendered incorrectly |

Exits non-zero on any failure. Safe to run before every deploy.

---

### `deploy` — Bring up the full stack

```bash
./swiftdeploy deploy
```

Runs `init`, then starts all containers with `docker compose up -d`.
Blocks until `https://kchiii.duckdns.org/healthz` returns healthy
or times out after 60 seconds.

On success:
✔  Stack is healthy! mode=stable uptime=3.2s
Deploy complete ✔
HTTPS URL   : https://kchiii.duckdns.org/
Health URL  : https://kchiii.duckdns.org/healthz

---

### `promote` — Switch deployment mode

```bash
./swiftdeploy promote canary
./swiftdeploy promote stable
```

What happens internally:
1. Patches `mode:` field in `manifest.yaml` in-place
2. Regenerates `docker-compose.yml` with new `MODE` env var
3. Restarts the `app` container only — Nginx stays up, no downtime
4. Polls `/healthz` until the new mode is confirmed

---

### `teardown` — Stop and clean up

```bash
./swiftdeploy teardown           # remove containers, networks, volumes
./swiftdeploy teardown --clean   # also delete nginx.conf + docker-compose.yml
```

---

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/` | Welcome message with mode, version, timestamp |
| `GET` | `/healthz` | Returns `status` and `uptime_seconds` |
| `POST` | `/chaos` | Canary-only: simulate failure modes |

### Chaos endpoint (canary mode only)

```bash
# Slow responses
curl -X POST https://kchiii.duckdns.org/chaos \
  -H "Content-Type: application/json" \
  -d '{"mode":"slow","duration":3}'

# Random errors (~50% rate)
curl -X POST https://kchiii.duckdns.org/chaos \
  -H "Content-Type: application/json" \
  -d '{"mode":"error","rate":0.5}'

# Recover to normal
curl -X POST https://kchiii.duckdns.org/chaos \
  -H "Content-Type: application/json" \
  -d '{"mode":"recover"}'
```

---

## Nginx

- Port 80 → redirects all HTTP to HTTPS permanently (301)
- Port 443 → serves HTTPS with Let's Encrypt certificate
- TLS 1.2 and 1.3 only — older insecure versions disabled
- HSTS header — browsers remember to always use HTTPS
- JSON error bodies on 502, 503, 504
- Access log format: `$time_iso8601 | $status | ${request_time}s | $upstream_addr | $request`
- Adds `X-Deployed-By: swiftdeploy` to every response
- Forwards `X-Mode` header from upstream

---

## Security

- Service runs as non-root (`nobody` user)
- All Linux capabilities dropped — only `NET_BIND_SERVICE` re-added
- `no-new-privileges` security option set
- App port (3000) never exposed to host — Nginx-only ingress
- HTTPS enforced with real Let's Encrypt certificate
- HSTS prevents protocol downgrade attacks
- Images based on Alpine — well under 300MB limit
