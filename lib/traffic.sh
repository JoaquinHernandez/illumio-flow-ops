#!/usr/bin/env bash

get_workload_traffic() {
  local workload_href="$1"
  local start_date="${2:-$(date -u -v-7d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%SZ)}"
  local end_date="${3:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"

  # Query PCE Explorer async query API
  local query_payload
  query_payload=$(jq -n \
    --arg src "$workload_href" \
    --arg start "$start_date" \
    --arg end "$end_date" \
    '{
      sources: {include: [[{workload: {href: $src}}]]},
      start_date: $start,
      end_date: $end,
      policy_decisions: ["blocked", "potentially_blocked", "allowed"]
    }')

  local res
  res=$(pce_request "POST" "/traffic_flows/async_queries" "$query_payload")
  local query_href
  query_href=$(echo "$res" | jq -r '.href')

  # Poll status until done
  local status="pending"
  while [[ "$status" != "completed" && "$status" != "failed" ]]; do
    sleep 2
    local poll_res
    poll_res=$(pce_request "GET" "$query_href")
    status=$(echo "$poll_res" | jq -r '.status')
  done

  pce_request "GET" "${query_href}/download" | gunzip -c 2>/dev/null || echo "$poll_res"
}
