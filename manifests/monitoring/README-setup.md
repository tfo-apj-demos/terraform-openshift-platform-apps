# Claude Code OpenTelemetry Setup Guide

This guide explains how to configure Claude Code to send telemetry to your OpenShift monitoring stack for visualization in Grafana.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Architecture Overview](#architecture-overview)
- [Configuration Methods](#configuration-methods)
- [Verifying Telemetry](#verifying-telemetry)
- [Troubleshooting](#troubleshooting)
- [Privacy Considerations](#privacy-considerations)

---

## Prerequisites

Before configuring Claude Code telemetry, ensure the following components are deployed in your OpenShift cluster:

### Required Infrastructure

1. **OpenTelemetry Collector** - Receives telemetry from Claude Code
   - Deployed in the `monitoring` namespace
   - Listening on port 4318 (HTTP/OTLP)
   - Configured to export metrics to Prometheus and logs to Loki

2. **Prometheus** - Stores time-series metrics
   - Must have OTLP receiver enabled: `--web.enable-otlp-receiver`
   - Feature flag required: `--enable-feature=otlp-deltatocumulative`

3. **Loki** - Stores structured event logs
   - Receives logs from OTEL collector
   - Used for tool execution events, errors, and API request logs

4. **Grafana** - Visualization and dashboards
   - Configured with Prometheus and Loki datasources
   - Claude Code dashboard imported (see `claude-code-dashboard.json`)

### Verify Infrastructure is Ready

```bash
# Check OTEL collector is running
oc get pods -n monitoring -l app=otel-collector

# Check Prometheus is running
oc get pods -n monitoring -l app=prometheus

# Check Loki is running
oc get pods -n monitoring -l app=loki

# Check Grafana is accessible
oc get route -n monitoring grafana
```

---

## Architecture Overview

```
+-------------------+     +------------------------+     +----------------+
|   Claude Code     |---->|  OpenTelemetry         |---->|  Prometheus    |
|   (Your Machine)  |     |  Collector             |     |  (Metrics)     |
+-------------------+     +------------------------+     +----------------+
                                    |                            |
                                    v                            v
                          +----------------+           +----------------+
                          |     Loki       |           |    Grafana     |
                          |   (Events)     |---------->|  (Dashboard)   |
                          +----------------+           +----------------+
```

**Data Flow:**
1. Claude Code emits telemetry via OTLP (HTTP/protobuf)
2. OTEL Collector receives, processes, and routes data
3. Metrics go to Prometheus for time-series storage
4. Event logs go to Loki for structured log storage
5. Grafana queries both sources to render the dashboard

---

## Configuration Methods

Choose one of the following methods to configure Claude Code telemetry:

### Method 1: Shell Environment (Recommended for Testing)

Source the environment configuration script before running Claude Code:

```bash
# Navigate to this directory
cd /path/to/manifests/monitoring

# Source the configuration
source ./claude-code-otel-env.sh

# Run Claude Code
claude
```

The script will print the active configuration for verification.

### Method 2: Claude Code Settings File (Recommended for Persistent Config)

Copy the `env` block from `claude-code-settings.json` to your Claude Code settings:

**Linux/macOS:**
```bash
# Edit or create settings file
mkdir -p ~/.config/claude-code
nano ~/.config/claude-code/settings.json
```

**Windows:**
```powershell
# Edit or create settings file
notepad %APPDATA%\claude-code\settings.json
```

Add or merge the `env` block:
```json
{
  "env": {
    "CLAUDE_CODE_ENABLE_TELEMETRY": "1",
    "OTEL_METRICS_EXPORTER": "otlp",
    "OTEL_LOGS_EXPORTER": "otlp",
    "OTEL_EXPORTER_OTLP_PROTOCOL": "http/protobuf",
    "OTEL_EXPORTER_OTLP_ENDPOINT": "http://localhost:4318",
    "OTEL_METRIC_EXPORT_INTERVAL": "10000",
    "OTEL_LOGS_EXPORT_INTERVAL": "5000",
    "OTEL_METRICS_INCLUDE_SESSION_ID": "true",
    "OTEL_METRICS_INCLUDE_ACCOUNT_UUID": "true",
    "OTEL_LOG_USER_PROMPTS": "0"
  }
}
```

### Method 3: Export Variables in Shell Profile

Add to `~/.bashrc`, `~/.zshrc`, or equivalent:

```bash
# Claude Code Telemetry
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export OTEL_METRICS_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318
export OTEL_METRIC_EXPORT_INTERVAL=10000
export OTEL_LOGS_EXPORT_INTERVAL=5000
export OTEL_METRICS_INCLUDE_SESSION_ID=true
export OTEL_METRICS_INCLUDE_ACCOUNT_UUID=true
```

---

## Connecting to the OTEL Collector

### Option A: Port Forward (Simplest)

Forward the OTEL collector port to your local machine:

```bash
# Start port-forward (keep this running in a separate terminal)
oc port-forward -n monitoring svc/otel-collector 4318:4318
```

Use endpoint: `http://localhost:4318`

### Option B: OpenShift Route (For External Access)

If you have an OTEL collector route exposed:

```bash
# Get the route URL
oc get route -n monitoring otel-collector -o jsonpath='{.spec.host}'
```

Use endpoint: `https://<route-host>` (note: HTTPS for routes)

### Option C: VPN/Direct Cluster Access

If you have direct access to the cluster network:

Use endpoint: `http://otel-collector.monitoring.svc.cluster.local:4318`

---

## Verifying Telemetry

### Step 1: Check Claude Code is Sending Data

Run a simple Claude Code session:

```bash
source ./claude-code-otel-env.sh
claude --help
# Or start an interactive session and make a few requests
```

### Step 2: Verify OTEL Collector Receives Data

Check collector logs for received data:

```bash
oc logs -n monitoring -l app=otel-collector --tail=50 | grep -i "claude\|otlp"
```

### Step 3: Query Prometheus for Metrics

Port-forward to Prometheus and query:

```bash
oc port-forward -n monitoring svc/prometheus 9090:9090
```

Open http://localhost:9090 and run:
```promql
{__name__=~"claude_code.*"}
```

You should see metrics like:
- `claude_code_token_usage_tokens_total`
- `claude_code_cost_usage_USD_total`
- `claude_code_session_count`

### Step 4: Query Loki for Events

In Grafana, go to Explore and select Loki, then run:

```logql
{service_name="claude-code"}
```

You should see event logs like:
- `tool_result` events
- `api_request` events
- `user_prompt` events (if enabled)

### Step 5: View the Dashboard

Access Grafana and open the "Claude Code Metrics Dashboard":

```bash
# Get Grafana route
oc get route -n monitoring grafana -o jsonpath='{.spec.host}'
```

Navigate to: `https://<grafana-host>/d/claude-code-metrics`

---

## Troubleshooting

### No Data in Grafana

**Check telemetry is enabled:**
```bash
echo $CLAUDE_CODE_ENABLE_TELEMETRY  # Should be "1"
```

**Check endpoint is reachable:**
```bash
curl -v $OTEL_EXPORTER_OTLP_ENDPOINT/v1/metrics
# Should return 405 Method Not Allowed (expected for GET)
```

**Verify port-forward is running:**
```bash
ps aux | grep "port-forward.*otel"
```

### Metrics Appear but Logs Don't

**Check Loki exporter in OTEL collector config:**
```bash
oc get configmap -n monitoring otel-collector-config -o yaml | grep -A10 "loki"
```

**Verify Loki is receiving data:**
```bash
oc logs -n monitoring -l app=loki-gateway --tail=20
```

### "Connection Refused" Errors

**Ensure OTEL collector is running:**
```bash
oc get pods -n monitoring -l app=otel-collector
```

**Check service exists:**
```bash
oc get svc -n monitoring otel-collector
```

### High Latency in Dashboard Updates

**Reduce export intervals:**
```bash
export OTEL_METRIC_EXPORT_INTERVAL=5000   # 5 seconds
export OTEL_LOGS_EXPORT_INTERVAL=2000     # 2 seconds
```

Note: Lower intervals increase network traffic.

### Certificate Errors (HTTPS Endpoints)

If using a route with self-signed certificates:
```bash
# Option 1: Trust the certificate
# Option 2: Use port-forward instead (avoids TLS)
# Option 3: Set insecure flag if supported
```

---

## Privacy Considerations

### What is Collected by Default

- Session metadata (ID, start time, terminal type)
- Token usage counts (input, output, cache)
- Cost estimates (by model)
- Tool execution results (name, success/failure, duration)
- Lines of code statistics (added/removed counts)
- Error messages (without sensitive content)

### What is NOT Collected

- API keys or credentials
- File contents
- Actual prompt text (unless explicitly enabled)
- Personal identification (unless session/account IDs enabled)

### Privacy Settings

**Disable session tracking** (aggregated metrics only):
```bash
export OTEL_METRICS_INCLUDE_SESSION_ID=false
export OTEL_METRICS_INCLUDE_ACCOUNT_UUID=false
```

**Enable prompt logging** (for debugging/analysis):
```bash
export OTEL_LOG_USER_PROMPTS=1
```

**WARNING:** Enabling prompt logging will send your actual prompts to the telemetry backend. Only enable this in controlled environments where prompt content can be safely stored.

---

## Useful Links

| Resource | URL |
|----------|-----|
| Grafana Dashboard | `https://<grafana-route>/d/claude-code-metrics` |
| Prometheus UI | `https://<prometheus-route>` |
| OTEL Collector Metrics | `http://localhost:8889/metrics` (after port-forward) |
| Loki Query | Grafana Explore > Loki datasource |

---

## Files in This Directory

| File | Purpose |
|------|---------|
| `claude-code-otel-env.sh` | Shell script to source for environment configuration |
| `claude-code-settings.json` | Settings file snippet for Claude Code configuration |
| `README-setup.md` | This setup guide |
| `claude-code-dashboard-specification.md` | Dashboard specification and panel definitions |
| `claude-code-dashboard.json` | Grafana dashboard JSON (if generated) |

---

## Support

If you encounter issues not covered in this guide:

1. Check the OTEL collector logs: `oc logs -n monitoring -l app=otel-collector`
2. Verify network connectivity between your machine and the cluster
3. Ensure all required environment variables are set correctly
4. Consult the dashboard specification for metric and query details
