#!/usr/bin/env bash

get_workload_ven_status() {
  local hostname_filter="${1:-}"
  local payload
  payload=$(pce_request "GET" "/workloads")

  if [[ -n "$hostname_filter" ]]; then
    echo "$payload" | jq --arg host "$hostname_filter" \
      '.[] | select(.hostname == $host) | {
        hostname: .hostname,
        href: .href,
        status: .ven.status,
        online: .online,
        enforcement_mode: .enforcement_mode,
        labels: [.labels[] | {key: .key, value: .value}]
      }'
  else
    echo "$payload" | jq -r '.[] | [
      .hostname,
      .ven.status,
      .enforcement_mode,
      (.labels | map(.value) | join(","))
    ] | @tsv'
  fi
}

check_ven_compatibility() {
  local workload_href="$1"
  # Fetch compatibility report attached to workload
  local report
  report=$(pce_request "GET" "${workload_href}/compatibility_report")
  
  local overall_status
  overall_status=$(echo "$report" | jq -r '.qualify_status // "unknown"')
  
  echo "$overall_status"
}
