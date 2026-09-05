#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config/illumio.conf"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Error: Configuration file not found at $CONFIG_FILE" >&2
  exit 1
fi

source "$CONFIG_FILE"
source "${SCRIPT_DIR}/lib/api.sh"
source "${SCRIPT_DIR}/lib/workloads.sh"
source "${SCRIPT_DIR}/lib/traffic.sh"
source "${SCRIPT_DIR}/lib/snow.sh"
source "${SCRIPT_DIR}/lib/lifecycle.sh"

usage() {
  cat <<EOF
Usage: illumio-ops <command> [arguments]

Commands:
  ven-audit              Scan all workloads and display VEN status, compatibility, and modes
  traffic <hostname>     Pull last 7 days of flow data for a target workload
  sync-cmdb <hostname>   Reconcile and assign PCE labels using ServiceNow CMDB metadata
  promote                Execute stage gating (idle -> visibility_only -> selective)
EOF
  exit 1
}

main() {
  local cmd="${1:-}"
  shift || true

  case "$cmd" in
    ven-audit)
      get_workload_ven_status
      ;;
    traffic)
      [[ -z "${1:-}" ]] && { echo "Error: Missing hostname"; exit 1; }
      local href
      href=$(get_workload_ven_status "$1" | jq -r '.href')
      get_workload_traffic "$href"
      ;;
    sync-cmdb)
      [[ -z "${1:-}" ]] && { echo "Error: Missing hostname"; exit 1; }
      local host="$1"
      local href cmdb_data
      href=$(get_workload_ven_status "$host" | jq -r '.href')
      cmdb_data=$(get_snow_ci_labels "$host")
      echo "Synced CMDB data for $host: $cmdb_data"
      ;;
    promote)
      promote_workloads
      ;;
    *)
      usage
      ;;
  esac
}

main "$@"
