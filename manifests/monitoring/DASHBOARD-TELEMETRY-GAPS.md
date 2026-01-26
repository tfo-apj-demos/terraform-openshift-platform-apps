# Claude Code Dashboard - Telemetry Gaps Analysis

**Analysis Date:** 2026-01-26 20:00 AEDT
**Test Window:** Last 3 hours (~19:57 AEDT test session)
**Purpose:** Document gaps between dashboard expectations and actual telemetry data

---

## Executive Summary

Three critical gaps identified in Claude Code telemetry that limit dashboard usefulness:

| Issue | Impact | Severity |
|-------|--------|----------|
| **Generic error messages** | "Recent Errors" table shows "Shell command failed" not actual error | HIGH |
| **No subagent_type in telemetry** | Cannot distinguish Explore/Plan/custom subagents | HIGH |
| **No Task description/prompt** | "Slowest Operations" shows Task but not what it was doing | MEDIUM |

---

## Issue 1: Generic Error Messages

### Observed Behavior

The "Recent Errors" panel shows errors like:
```
Tool: Bash | Error: "Shell command failed"
```

### Actual Data from Loki

```json
{
  "tool_name": "Bash",
  "success": "false",
  "error": "Shell command failed",
  "error_extracted": "Shell command failed",
  "tool_parameters": {
    "bash_command": "curl",
    "full_command": "curl -s -k -X POST ...",
    "description": "Save and view Task events raw"
  }
}
```

### Root Cause

Claude Code's telemetry only logs a **generic error category**, not the actual error output (stderr, exit code, or exception message). The `tool_parameters` field contains the command that was run, but the `error` field is always a generic string like:
- "Shell command failed" (for Bash)
- "File not found" (for Read)
- "Permission denied" (for Write)

### What's Missing

| Field | Available? | What We Get | What We Need |
|-------|------------|-------------|--------------|
| `error` | Yes | "Shell command failed" | Actual stderr output |
| `exit_code` | No | N/A | e.g., 1, 2, 127 |
| `stderr` | No | N/A | Actual error text |
| `tool_parameters.full_command` | Yes (Bash only) | Full command string | (already useful) |

### Workaround

For Bash errors, we CAN show the `tool_parameters.description` field which contains the human-readable description. Update the dashboard query:

```logql
{service_name="claude-code", success="false"}
| json
| line_format "{{.tool_name}}: {{.tool_parameters}}"
```

This will at least show WHAT was being attempted when it failed.

---

## Issue 2: No Subagent Type in Telemetry

### Observed Behavior

The "Subagent Success Distribution" and "Subagents per Conversation" panels query:
```logql
{service_name="claude-code", tool_name="Task"}
```

This treats ALL Task calls equally, but Tasks can be:
- **Explore** (fast codebase search with Haiku)
- **Plan** (planning mode research)
- **general-purpose** (full capability agent)
- **Custom subagents** (user-defined)

### Actual Data from Loki (Task tool_result)

```json
{
  "tool_name": "Task",
  "success": "true",
  "duration_ms": "93218",
  "cost_usd": "0.2142525",
  "model": "claude-opus-4-5-20251101",
  "tool_result_size_bytes": "11744"
}
```

### What's Missing

| Field | Available? | What We Need |
|-------|------------|--------------|
| `tool_name` | Yes | "Task" |
| `subagent_type` | **NO** | "Explore", "Plan", "general-purpose", "custom-agent-name" |
| `description` | **NO** | "Explore monitoring data flow" (the 3-5 word summary) |
| `prompt` | **NO** | The full prompt sent to the subagent |
| `model` | Yes | Which model the subagent used |

### Documentation Confirmation

From [Claude Code Monitoring Docs](https://code.claude.com/docs/en/monitoring-usage):

> **tool_result event** attributes:
> - `tool_name`: Name of the tool
> - `success`: "true" or "false"
> - `duration_ms`: Execution time in milliseconds
> - `error`: Error message (if failed)
> - `tool_parameters`: JSON string containing tool-specific parameters
>   - **For Bash tool**: includes `bash_command`, `full_command`, `timeout`, `description`, `sandbox`

**Note:** `tool_parameters` is only documented for Bash tool. Task tool parameters (subagent_type, description, prompt) are NOT included in telemetry.

### Impact on Dashboard

| Panel | Current Query | Problem |
|-------|--------------|---------|
| Subagent Success Distribution | `tool_name="Task"` | All subagents lumped together |
| Subagent Success Rate | Same | Can't calculate per-type success rate |
| Subagents per Conversation | Same | Can't see which types are used |
| Slowest Operations | Shows "Task" | No context on what the Task was doing |

### Feature Request

Claude Code should emit these fields for Task tool_result events:
```json
{
  "tool_name": "Task",
  "subagent_type": "Explore",
  "subagent_description": "Find error handling patterns",
  "subagent_model": "haiku"
}
```

---

## Issue 3: No Context for Slowest Operations

### Observed Behavior

The "Slowest Operations" table shows:
```
Tool: Task | Duration: 93218ms | Session: xxx
```

But we don't know WHAT that Task was doing.

### What We Have

```json
{
  "tool_name": "Task",
  "duration_ms": "93218",
  "session_id": "82c3f15b-86b7-48fa-bd3d-fed21e6e8be6"
}
```

### What We Need

```json
{
  "tool_name": "Task",
  "duration_ms": "93218",
  "session_id": "...",
  "description": "Explore monitoring data flow",
  "subagent_type": "Explore"
}
```

### Workaround (Partial)

For Bash tool, we CAN extract the description from `tool_parameters`:
```logql
{service_name="claude-code", duration_ms=~"[0-9]{5,}"}
| json
| line_format "{{.tool_name}}: {{.tool_parameters}}"
```

This doesn't help for Task, Read, Edit, etc.

---

## Tool Parameter Availability by Tool

| Tool | `tool_parameters` Available? | Fields Included |
|------|------------------------------|-----------------|
| Bash | Yes | `bash_command`, `full_command`, `timeout`, `description`, `sandbox` |
| Task | **NO** | Nothing - just `tool_name` |
| Read | **NO** | Nothing - no file path |
| Edit | **NO** | Nothing - no file path or changes |
| Write | **NO** | Nothing - no file path |
| Grep | **NO** | Nothing - no pattern or path |
| Glob | **NO** | Nothing - no pattern |
| WebFetch | **NO** | Nothing - no URL |

---

## Recommendations

### Short-term Dashboard Improvements

1. **For errors:** Show `tool_parameters` where available (helps for Bash)
2. **For Task panels:** Rename to "Task Tool Calls" not "Subagent" (more accurate)
3. **For slowest ops:** Add model column to help identify heavy operations

### Feature Requests to Anthropic

1. **Add `subagent_type` to Task tool_result events**
   - Values: "Explore", "Plan", "general-purpose", "Bash", or custom name

2. **Add `description` to Task tool_result events**
   - The 3-5 word summary passed when invoking the Task tool

3. **Add actual error details to error field**
   - For Bash: include stderr or exit code
   - For Read: include "file not found" path
   - For Write: include permission error details

4. **Add tool_parameters for all tools**
   - Read: `{file_path: "/path/to/file"}`
   - Grep: `{pattern: "foo", path: "/dir"}`
   - Task: `{subagent_type: "Explore", description: "Find X"}`

---

## API Queries Used for Analysis

### Get errors with full details
```bash
curl -s -k "https://grafana.../api/datasources/proxy/uid/loki/loki/api/v1/query_range" \
  -G --data-urlencode 'query={service_name="claude-code", success="false"}' \
  --data-urlencode 'limit=10'
```

### Get Task tool events
```bash
curl -s -k "https://grafana.../api/datasources/proxy/uid/loki/loki/api/v1/query_range" \
  -G --data-urlencode 'query={service_name="claude-code", tool_name="Task"}' \
  --data-urlencode 'limit=5'
```

### Get tool distribution (3h)
```logql
sum by (tool_name) (count_over_time({service_name="claude-code"} [3h]))
```

---

## Data Sample from Test Session

### Tool Distribution (Last 3h)
| Tool | Count |
|------|-------|
| Bash | 227 |
| (no tool_name - api events) | 205 |
| Read | 134 |
| Edit | 88 |
| TodoWrite | 79 |
| **Task** | **72** |
| Glob | 37 |
| mcp__terraform__search_providers | 26 |
| Write | 26 |
| WebFetch | 14 |
| AskUserQuestion | 6 |
| mcp__terraform__get_provider_details | 5 |
| Skill | 4 |

### Sample Task Event (Actual Telemetry)
```json
{
  "tool_name": "Task",
  "success": "true",
  "duration_ms": "93218",
  "cost_usd": "0.2142525",
  "model": "claude-opus-4-5-20251101",
  "tool_result_size_bytes": "11744",
  "session_id": "82c3f15b-86b7-48fa-bd3d-fed21e6e8be6"
}
```

**What's missing:** No `subagent_type`, no `description`, no `prompt`.

### Sample Error Event (Actual Telemetry)
```json
{
  "tool_name": "Bash",
  "success": "false",
  "error": "Shell command failed",
  "duration_ms": "132",
  "tool_parameters": {
    "bash_command": "curl",
    "full_command": "curl -s -k -X POST ...",
    "description": "Save and view Task events raw"
  }
}
```

**What's missing:** Actual stderr output, exit code.

---

## Next Steps

1. Update dashboard to use available workarounds
2. Rename "Subagent" panels to "Task Tool" for accuracy
3. Consider filing feature request with Anthropic
4. Document limitations in dashboard README

---

*Document will be updated as more findings emerge*
