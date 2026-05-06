# hng-stage4-swiftDeploy-B

> **SwiftDeploy** — a declarative, policy-driven deployment CLI.  
> `manifest.yaml` is the single source of truth.  
> OPA is the single source of policy decisions.  
> HTTPS served via Let's Encrypt. Metrics in Prometheus format.

📖 **Technical Blog Post:** [From Manifest to Production — Engineering a Policy-Driven Deployment Engine with SwiftDeploy](https://swiftdeploy-by-kachi-the-localman.hashnode.dev/from-manifest-to-production-engineering-a-policy-driven-deployment-engine-with-swiftdeploy)

🔗 **Stage 4A Repo:** [hng-stage4-swiftDeploy](https://github.com/kachi-cmd/hng-stage4-swiftDeploy)

---

## What This Project Does

SwiftDeploy is a CLI tool that:

1. Reads a single `manifest.yaml` and generates all infrastructure config files from templates
2. Enforces deployment safety through OPA (Open Policy Agent) policy checks before any deploy or promote
3. Exposes Prometheus-format metrics from the app service for real-time observability
4. Provides a live status dashboard that tracks metrics and policy compliance
5. Maintains an append-only audit trail and generates a structured Markdown report

---

## Project Structure
hng-stage4-swiftDeploy-B/
├── manifest.yaml                    # ← ONLY file you edit manually
├── swiftdeploy                      # CLI executable (Python, no frameworks)
├── Dockerfile                       # Builds the API service image
├── app/
│   └── main.py                      # Python HTTP service — stdlib only
├── templates/
│   ├── nginx.conf.j2                # Nginx config template (HTTPS)
│   └── docker-compose.yml.j2        # Compose template (app + nginx + OPA)
├── policies/
│   ├── infra.rego                   # Infrastructure policy (disk, CPU, mem)
│   ├── infra_data.json              # Infra thresholds (not hardcoded in Rego)
│   ├── canary.rego                  # Canary safety policy (error rate, P99)
│   └── canary_data.json             # Canary thresholds
├── certs/                           # Let's Encrypt certs (never committed)
│   ├── fullchain.pem
│   └── privkey.pem
├── history.jsonl                    # Append-only audit trail (runtime)
├── audit_report.md                  # Generated report (runtime)
└── README.md

Generated on first run — do not edit:
- `nginx.conf` — rendered from template
- `docker-compose.yml` — rendered from template

---

## Architecture
Internet
│
▼ :443 (HTTPS)
┌─────────────────────────────────────────────┐
│  Docker network (swiftdeploy-net)            │
│                                             │
│  ┌──────────┐    ┌──────────────────────┐  │
│  │  Nginx   │───▶│    App service       │  │
│  │  :443    │    │    :3000             │  │
│  └──────────┘    │  / /healthz /chaos   │  │
│                  │  /metrics  ← NEW     │  │
│                  └──────────────────────┘  │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │  OPA sidecar  :8181                  │  │
│  │  loads policies/*.rego               │  │
│  │  bound to 127.0.0.1 — localhost only │  │
│  └──────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
▲
│ queries OPA before deploy/promote
swiftdeploy CLI (runs on host)

**Key security properties:**
- App port (3000) never exposed to host — Nginx-only ingress
- OPA port (8181) bound to `127.0.0.1` — CLI-only, never public
- Nginx never proxies to OPA — policy API invisible to internet
- All containers run as non-root with dropped Linux capabilities

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
git clone https://github.com/kachi-cmd/hng-stage4-swiftDeploy-B.git
cd hng-stage4-swiftDeploy-B
```

### 2. Issue HTTPS certificate (first time only)

Make sure your domain points to your server's public IP:

```bash
sudo certbot certonly --standalone -d kchiii.duckdns.org \
  --email your@email.com --agree-tos --non-interactive
```

Copy certificates into the project:

```bash
mkdir -p certs
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

## Subcommand Reference

### `init` — Generate config files from manifest

```bash
./swiftdeploy init
```

Reads `manifest.yaml` and renders:
- `nginx.conf` — Nginx reverse proxy config with HTTPS
- `docker-compose.yml` — full stack: app + nginx + OPA sidecar

Nothing runs yet. Pure file generation.

---

### `validate` — Run 5 pre-flight checks

```bash
./swiftdeploy validate
```

| # | Check | Fails when |
|---|-------|-----------|
| 1 | manifest.yaml exists and is valid YAML | File missing or syntax error |
| 2 | All required fields present and non-empty | Any required field missing |
| 3 | Docker image exists locally | Image not built yet |
| 4 | HTTPS port 443 is free on host | Another process using 443 |
| 5 | nginx.conf is syntactically valid | Template rendered incorrectly |

Exits non-zero on any failure.

---

### `deploy` — OPA-gated stack deployment

```bash
./swiftdeploy deploy
```

**What happens:**
1. If OPA is already running — queries `policy/infra` with host stats (disk, CPU, mem)
2. Blocks if any infrastructure policy fails — prints human-readable reason
3. Runs `init` to regenerate configs
4. Brings up full stack: app + nginx + OPA
5. Waits for OPA to be healthy
6. Blocks until `/healthz` confirms the stack is up (60s timeout)

**Example policy block:**
POLICY VIOLATION — BLOCKED
• [policy/infra] Disk free 8.2GB is below minimum 10.0GB

---

### `promote` — OPA-gated mode switch

```bash
./swiftdeploy promote canary    # switch to canary mode
./swiftdeploy promote stable    # OPA-gated switch back to stable
```

**Promoting to stable triggers a canary safety check:**
1. Scrapes `/metrics` from the live app
2. Calculates error rate and P99 latency
3. Sends to OPA `policy/canary` for evaluation
4. Blocks if error rate > 1% or P99 > 500ms
5. On pass — patches manifest, regenerates compose, restarts app only
6. Confirms new mode via `/healthz`

**Example canary block:**
POLICY VIOLATION — BLOCKED
• [policy/canary] P99 latency 3200ms exceeds maximum 500ms

---

### `status` — Live metrics dashboard

```bash
./swiftdeploy status
```

Refreshes every 5 seconds. Displays:
- Current mode (stable/canary) and uptime
- Active chaos state
- Real-time req/s and P99 latency
- Error rate
- Host stats (disk, CPU, memory)
- Policy compliance — which rules are currently passing/failing

Appends every scrape to `history.jsonl` for the audit trail.

Press `Ctrl+C` to exit.

---

### `audit` — Generate audit report

```bash
./swiftdeploy audit
```

Reads `history.jsonl` and generates `audit_report.md` containing:

- **Summary** — total scrapes, time in each mode, avg/max P99, violation count
- **Timeline** — table of mode changes, chaos injections, chaos recoveries
- **Policy Violations** — every scrape where a policy check failed, with metrics
- **Recent Metrics** — last 5 scrapes in table format

Output renders correctly as GitHub Flavored Markdown.

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
| `GET` | `/metrics` | Prometheus-format metrics |
| `POST` | `/chaos` | Canary-only: simulate failure modes |

### Metrics exposed

| Metric | Type | Description |
|--------|------|-------------|
| `http_requests_total` | Counter | Total requests by method, path, status_code |
| `http_request_duration_seconds` | Histogram | Request duration with standard buckets |
| `app_uptime_seconds` | Gauge | Seconds since app started |
| `app_mode` | Gauge | 0=stable, 1=canary |
| `chaos_active` | Gauge | 0=none, 1=slow, 2=error |

### Chaos endpoint (canary mode only)

```bash
# Slow responses
curl -X POST https://kchiii.duckdns.org/chaos \
  -H "Content-Type: application/json" \
  -d '{"mode":"slow","duration":3}'

# Random 500 errors (~50% rate)
curl -X POST https://kchiii.duckdns.org/chaos \
  -H "Content-Type: application/json" \
  -d '{"mode":"error","rate":0.5}'

# Recover
curl -X POST https://kchiii.duckdns.org/chaos \
  -H "Content-Type: application/json" \
  -d '{"mode":"recover"}'
```

---

## OPA Policy Details

### Infrastructure Policy (`policies/infra.rego`)

Evaluated before every `deploy`. Queries `policy/infra`.

Input sent by CLI:
```json
{
  "disk_free_gb": 42.3,
  "cpu_load": 0.4,
  "mem_free_gb": 1.8
}
```

Thresholds in `policies/infra_data.json`:
```json
{
  "thresholds": {
    "min_disk_gb": 10.0,
    "max_cpu_load": 2.0,
    "min_mem_gb": 0.5
  }
}
```

### Canary Safety Policy (`policies/canary.rego`)

Evaluated before `promote stable`. Queries `policy/canary`.

Input sent by CLI (calculated from `/metrics`):
```json
{
  "error_rate": 0.003,
  "p99_latency_ms": 124,
  "sample_size": 450
}
```

Thresholds in `policies/canary_data.json`:
```json
{
  "thresholds": {
    "max_error_rate": 0.01,
    "max_p99_latency_ms": 500
  }
}
```

### The separation principle

Threshold values are never hardcoded inside `.rego` files. The Rego files contain only logic. The JSON files contain only values. Changing a threshold never requires touching policy logic — just update the JSON and OPA reloads automatically.

---

## Nginx

- Port 80 → redirects all HTTP to HTTPS (301)
- Port 443 → HTTPS with Let's Encrypt certificate
- TLS 1.2 and 1.3 only
- HSTS header — browsers remember HTTPS for one year
- JSON error bodies on 502, 503, 504
- Access log format: `$time_iso8601 | $status | ${request_time}s | $upstream_addr | $request`
- Adds `X-Deployed-By: swiftdeploy` to every response
- Forwards `X-Mode` header from upstream

---

## Security Hardening

| Property | Implementation |
|----------|---------------|
| Non-root containers | App runs as `appuser`, OPA uses `rootless` image |
| Dropped capabilities | `cap_drop: ALL`, only `NET_BIND_SERVICE` re-added |
| No privilege escalation | `no-new-privileges: true` on app container |
| App port not exposed | Only Nginx has host port mapping |
| OPA not public | Bound to `127.0.0.1:8181` — localhost only |
| Private keys | `certs/` in `.gitignore` — never committed |
| HTTPS enforced | HTTP redirects to HTTPS, HSTS header set |
| Small images | App image ~74MB (Alpine-based), well under 300MB limit |

---

## Policy Compliance Testing

### Test the infrastructure gate (disk check)

```bash
# Fill disk temporarily to trigger the policy
fallocate -l 35G /tmp/diskfill.img
./swiftdeploy deploy   # should be blocked with disk violation
rm /tmp/diskfill.img   # clean up
```

### Test the canary safety gate (latency check)

```bash
./swiftdeploy promote canary

# Inject slow chaos
curl -X POST https://kchiii.duckdns.org/chaos \
  -H "Content-Type: application/json" \
  -d '{"mode":"slow","duration":3}'

# Generate some traffic
for i in $(seq 1 20); do curl -s https://kchiii.duckdns.org/ > /dev/null; done

# Try to promote back to stable — should be blocked
./swiftdeploy promote stable
```

---

## Full End-to-End Test

```bash
# 1. Build image
docker build -t swift-deploy-1-node:latest .

# 2. Validate
./swiftdeploy validate

# 3. Deploy
./swiftdeploy deploy

# 4. Verify endpoints
curl -s https://kchiii.duckdns.org/ | python3 -m json.tool
curl -s https://kchiii.duckdns.org/healthz | python3 -m json.tool
curl -s https://kchiii.duckdns.org/metrics | head -30

# 5. Run status dashboard (Ctrl+C after 30s)
./swiftdeploy status

# 6. Promote to canary
./swiftdeploy promote canary

# 7. Verify canary headers
curl -s -D - https://kchiii.duckdns.org/ -o /dev/null | grep X-Mode

# 8. Inject chaos
curl -X POST https://kchiii.duckdns.org/chaos \
  -H "Content-Type: application/json" \
  -d '{"mode":"slow","duration":2}'

# 9. Generate traffic while status is running
for i in $(seq 1 30); do curl -s https://kchiii.duckdns.org/ > /dev/null; done

# 10. Recover chaos and promote back to stable
curl -X POST https://kchiii.duckdns.org/chaos \
  -H "Content-Type: application/json" \
  -d '{"mode":"recover"}'
./swiftdeploy promote stable

# 11. Generate audit report
./swiftdeploy audit
cat audit_report.md

# 12. Teardown when done
./swiftdeploy teardown
```
