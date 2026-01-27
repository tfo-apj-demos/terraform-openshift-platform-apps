# Claude Code Dashboard - Implementation Notes

This document captures the intricate details of setting up the Claude Code Grafana dashboard with Loki and Prometheus on OpenShift. Use this as context when making future enhancements.

---

## Architecture Overview

```
Claude Code CLI
    ↓ (OTLP)
OTEL Collector (transform processor)
    ↓ (promotes attributes to resource attributes)
    ├─→ Loki (logs, indexed labels)
    └─→ Prometheus (metrics via remote write)
    ↓
Grafana Dashboard
```

---

## Key Problem: Loki Label vs Structured Metadata

### The Issue
Grafana dashboard showed error: **"only label matchers are supported"** when loading Loki variable queries.

### Root Cause
Loki has two types of queryable fields:
1. **Labels** (indexed) - Used in stream selectors `{label="value"}` and for `sum by (label)`
2. **Structured Metadata** (not indexed) - Used in pipe filters `| field="value"`

Claude Code's OTLP logs originally had `tool_name`, `event_name`, `success`, `error` as **log attributes**, which Loki stored as structured metadata - NOT indexed labels.

### The Fix: OTEL Collector Transform Processor

**File:** `manifests/monitoring/otel-collector-configmap.yaml`

Added a transform processor to "promote" log attributes to resource attributes:

```yaml
processors:
  transform/logs:
    log_statements:
      - context: log
        statements:
          # Copy key attributes to resource for Loki label indexing
          - set(resource.attributes["tool_name"], attributes["tool_name"]) where attributes["tool_name"] != nil
          - set(resource.attributes["event_name"], attributes["event_name"]) where attributes["event_name"] != nil
          - set(resource.attributes["success"], attributes["success"]) where attributes["success"] != nil
          - set(resource.attributes["error"], attributes["error"]) where attributes["error"] != nil
```

Updated the logs pipeline to use the transform processor:

```yaml
pipelines:
  logs:
    receivers: [otlp]
    processors: [memory_limiter, transform/logs, batch]
    exporters: [otlphttp/loki, debug]
```

### Loki Configuration for Label Indexing

**File:** `templates/loki_helm_values.yaml.tpl`

Configure Loki to index the promoted resource attributes as labels:

```yaml
loki:
  distributor:
    otlp_config:
      default_resource_attributes_as_index_labels:
        - service.name
        - tool_name
        - event_name
        - success
        - error
```

---

## Dashboard Query Patterns

### Stream Selectors vs Pipe Filters

**WRONG** (uses pipe filter for indexed label):
```logql
{service_name="claude-code"} | event_name="tool_result" | tool_name=~"$tool"
```

**CORRECT** (uses stream selector for indexed labels):
```logql
{service_name="claude-code", event_name="tool_result", tool_name=~"$tool"}
```

### Aggregating by Labels

For `sum by (label)` to work, the label MUST be in the stream selector:

**WRONG:**
```logql
sum by (tool_name) (count_over_time({service_name="claude-code"} | success="false" [$__range]))
```

**CORRECT:**
```logql
sum by (tool_name) (count_over_time({service_name="claude-code", tool_name!=""} | success="false" [$__range]))
```

---

## Available Telemetry Data

### Prometheus Metrics

The following metrics are available (note some have double prefix due to OTEL collector):

| Metric | Description |
|--------|-------------|
| `claude_code_token_usage_tokens_total` | Token usage by model and type |
| `claude_code_cost_usage_USD_total` | Cost in USD |
| `claude_code_active_time_seconds_total` | Active session time |
| `claude_code_lines_of_code_count_total` | Lines of code modified |
| `claude_code_code_edit_tool_decision_total` | Edit tool decisions |

**Important Labels on Prometheus Metrics:**
- `session_id` - Unique session identifier
- `model` - Claude model used
- `type` - Token type (input, output, cacheCreation, cacheRead)
- `terminal_type` - vscode, terminal, etc.
- `user_email` - User email

**Non-existent Metrics (don't use these):**
- `claude_code_session_count` - Does NOT exist
- Use `claude_code_token_usage_tokens_total` and count unique `session_id` instead

### Loki Log Fields

**Indexed Labels** (after OTEL transform):
- `service_name` - Always "claude-code"
- `tool_name` - Bash, Read, Edit, Grep, Write, Task, etc.
- `event_name` - tool_result, api_error, user_prompt (may not be populated yet)
- `success` - "true" or "false"
- `error` - Error message when success="false"

**Structured Metadata** (available in logs but not indexed):
- `session_id`
- `duration_ms`
- `event_sequence`
- `tool_parameters`
- `user_email`
- `organization_id`

**Fields That DON'T EXIST** (dashboard originally assumed these):
- `subagent_type` - Claude Code doesn't emit which type of subagent was used
- `error_message` - The field is called `error`
- `status_code` - Not reliably emitted
- `attempt` - No retry tracking

---

## OpenShift-Specific Issues

### Loki Helm Chart SCC Problem

The Loki Helm chart creates a malformed `loki-minio` SecurityContextConstraint that breaks pod scheduling.

**Error:** `create Pod loki-backend-0 failed: MustRunAs requires a UID`

**Fix:** Delete the SCC after each Helm install:
```bash
oc delete scc loki-minio
```

**Prevention:** The Helm values disable SCC creation:
```yaml
minio:
  securityContextConstraints:
    enabled: false
```

### Helm Upgrade Stuck in pending-upgrade

Helm upgrades for Loki often get stuck. Quick fix:

```bash
# Uninstall and reinstall with --no-hooks
helm uninstall loki -n monitoring --no-hooks
helm install loki grafana/loki -n monitoring -f /tmp/loki-values.yaml --no-hooks
oc delete scc loki-minio 2>/dev/null
```

---

## Dashboard Panel Fixes Summary

| Original Panel | Issue | Fixed Panel |
|----------------|-------|-------------|
| Active Sessions | Used non-existent `claude_code_session_count` | Uses `claude_code_token_usage_tokens_total` |
| Subagent Type Distribution | Used non-existent `subagent_type` | **Subagent Success Distribution** - groups by `success` |
| Subagent Success Rate by Type | Grouped by `subagent_type` | **Subagent Success Rate** - overall rate |
| Subagent Chain Depth | Misleading name | **Max Subagents/Session** |
| Tool Execution Duration | `unwrap duration_ms` syntax error | Counts executions by tool |
| Retry Patterns | Used non-existent `attempt` field | **Errors Over Time** |
| Error Correlation Matrix | Heatmap with log data | **Total Errors** (stat panel) |
| Error Message Groups | Grouped by non-existent `error_message` | **Recent Errors** - shows actual logs |
| API Error Status Codes | Grouped by non-existent `status_code` | **Errors by Tool** |

---

## Commands Reference

### Apply OTEL Collector Config
```bash
oc apply -f manifests/monitoring/otel-collector-configmap.yaml
oc rollout restart deployment/otel-collector -n monitoring
```

### Deploy Loki
```bash
sed 's/${storage_class}/ocs-storagecluster-cephfs/g' templates/loki_helm_values.yaml.tpl > /tmp/loki-values.yaml
helm uninstall loki -n monitoring --no-hooks
helm install loki grafana/loki -n monitoring -f /tmp/loki-values.yaml --no-hooks
oc delete scc loki-minio 2>/dev/null
```

### Check Available Loki Labels
```bash
oc exec -n monitoring deploy/loki-gateway -- wget -qO- 'http://loki-read:3100/loki/api/v1/labels' | jq '.data'
```

### Check Label Values
```bash
oc exec -n monitoring deploy/loki-gateway -- wget -qO- 'http://loki-read:3100/loki/api/v1/label/tool_name/values' | jq '.data'
```

### Check Prometheus Metrics
```bash
oc exec -n monitoring deploy/prometheus-server -c prometheus-server -- \
  wget -qO- "http://localhost:9090/api/v1/label/__name__/values" | jq -r '.data[]' | grep claude
```

### Sample Loki Log Entry
```bash
oc exec -n monitoring deploy/loki-gateway -- wget -qO- \
  'http://loki-read:3100/loki/api/v1/query_range?query={service_name="claude-code"}&limit=1&start='$(date -v-1H +%s)000000000'&end='$(date +%s)000000000 | jq '.data.result[0]'
```

---

## Future Enhancements

### To Get More Detailed Subagent Analytics
Claude Code would need to emit `subagent_type` in its telemetry (e.g., "Explore", "Plan", "Bash agent", etc.)

### To Get Retry Tracking
Claude Code would need to emit `attempt` or `retry_count` fields

### To Correlate Subagents to Parent Calls
Claude Code would need to emit `parent_event_id` or similar field

### To Add More Indexed Labels
1. Add to OTEL transform processor in `otel-collector-configmap.yaml`
2. Add to `default_resource_attributes_as_index_labels` in `loki_helm_values.yaml.tpl`
3. Redeploy both components

---

## Files Modified

| File | Purpose |
|------|---------|
| `manifests/monitoring/otel-collector-configmap.yaml` | Transform processor config |
| `templates/loki_helm_values.yaml.tpl` | Loki OTLP label indexing |
| `manifests/monitoring/claude-code-dashboard.json` | Grafana dashboard |

---

*Last updated: 2026-01-25*
