#!/bin/bash
# =============================================================================
# Claude Code OpenTelemetry Environment Configuration
# =============================================================================
#
# This script configures environment variables for Claude Code telemetry.
# Source this file before running Claude Code to enable metrics collection.
#
# Usage:
#   source ./claude-code-otel-env.sh
#   claude
#
# For OpenShift deployment, modify OTEL_EXPORTER_OTLP_ENDPOINT to point to
# your cluster's OTEL collector service.
#
# =============================================================================

# -----------------------------------------------------------------------------
# REQUIRED: Core Telemetry Settings
# -----------------------------------------------------------------------------

# Enable Claude Code telemetry (required for any metrics to be sent)
export CLAUDE_CODE_ENABLE_TELEMETRY=1

# Specify OTLP as the metrics exporter
# Options: otlp, console, none
export OTEL_METRICS_EXPORTER=otlp

# Specify OTLP as the logs exporter (for event logs to Loki)
# Options: otlp, console, none
export OTEL_LOGS_EXPORTER=otlp

# Use HTTP/protobuf protocol for OTLP export
# Options: http/protobuf, grpc
# Note: http/protobuf is recommended for better firewall compatibility
export OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf

# -----------------------------------------------------------------------------
# ENDPOINT CONFIGURATION
# -----------------------------------------------------------------------------
# Choose ONE of the following endpoint configurations:

# Option 1: OpenShift cluster via Route (default for this deployment)
export OTEL_EXPORTER_OTLP_ENDPOINT=https://otel-collector.apps.openshift-01.hashicorp.local

# TLS Certificate for self-signed OpenShift ingress
# Extract with: oc get secret router-certs-default -n openshift-ingress -o jsonpath='{.data.tls\.crt}' | base64 -d | awk '/-----BEGIN CERTIFICATE-----/{n++} n==2' > ~/.openshift-ingress-ca.crt
export OTEL_EXPORTER_OTLP_CERTIFICATE="${HOME}/.openshift-ingress-ca.crt"

# Node.js fallback for TLS certificate (Claude Code uses Node.js)
export NODE_EXTRA_CA_CERTS="${HOME}/.openshift-ingress-ca.crt"

# Option 2: Local development
# Use this when running the OTEL collector locally
# export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318

# Option 3: OpenShift cluster via port-forward
# First run: oc port-forward -n monitoring svc/otel-collector 4318:4318
# export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318

# Option 4: Direct cluster service (requires VPN or cluster network access)
# export OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector.monitoring.svc.cluster.local:4318

# -----------------------------------------------------------------------------
# EXPORT INTERVALS (Optimized for Real-Time Dashboards)
# -----------------------------------------------------------------------------

# Metrics export interval in milliseconds
# Lower values = more real-time data, but more network traffic
# Default: 60000 (60 seconds)
# Recommended for dashboards: 10000 (10 seconds)
export OTEL_METRIC_EXPORT_INTERVAL=10000

# Logs export interval in milliseconds
# Lower values = faster event visibility in Grafana
# Default: 30000 (30 seconds)
# Recommended for dashboards: 5000 (5 seconds)
export OTEL_LOGS_EXPORT_INTERVAL=5000

# -----------------------------------------------------------------------------
# SESSION & IDENTITY TRACKING
# -----------------------------------------------------------------------------

# Include session ID in metrics (enables per-session analysis)
# Set to false for enhanced privacy (aggregated metrics only)
export OTEL_METRICS_INCLUDE_SESSION_ID=true

# Include account UUID in metrics (enables per-user analysis)
# Set to false if you don't want user-level tracking
export OTEL_METRICS_INCLUDE_ACCOUNT_UUID=true

# -----------------------------------------------------------------------------
# PRIVACY SETTINGS
# -----------------------------------------------------------------------------

# Enable logging of user prompts to Loki
# WARNING: This logs the actual content of your prompts!
# - Set to 1 to enable prompt logging (useful for debugging/analysis)
# - Set to 0 or unset for privacy (only prompt length is logged)
# Default: disabled (0)
export OTEL_LOG_USER_PROMPTS=0

# To enable prompt logging, uncomment the line below:
# export OTEL_LOG_USER_PROMPTS=1

# -----------------------------------------------------------------------------
# OPTIONAL: Advanced Settings
# -----------------------------------------------------------------------------

# Service name for telemetry (used in Grafana queries)
# Default: claude-code
# export OTEL_SERVICE_NAME=claude-code

# Resource attributes (additional labels for all telemetry)
# Useful for multi-environment or multi-team deployments
# export OTEL_RESOURCE_ATTRIBUTES="environment=development,team=platform"

# Batch timeout for the exporter (milliseconds)
# How long to wait before sending a partial batch
# export OTEL_BSP_SCHEDULE_DELAY=5000

# -----------------------------------------------------------------------------
# VERIFICATION
# -----------------------------------------------------------------------------

echo "Claude Code OpenTelemetry Configuration Loaded"
echo "=============================================="
echo "Telemetry:       ${CLAUDE_CODE_ENABLE_TELEMETRY:-disabled}"
echo "Endpoint:        ${OTEL_EXPORTER_OTLP_ENDPOINT}"
echo "Protocol:        ${OTEL_EXPORTER_OTLP_PROTOCOL}"
echo "Metrics Export:  ${OTEL_METRIC_EXPORT_INTERVAL}ms"
echo "Logs Export:     ${OTEL_LOGS_EXPORT_INTERVAL}ms"
echo "Session ID:      ${OTEL_METRICS_INCLUDE_SESSION_ID}"
echo "Prompt Logging:  ${OTEL_LOG_USER_PROMPTS:-disabled}"
echo ""
echo "To verify telemetry is working, run 'claude' and check your Grafana dashboard."
