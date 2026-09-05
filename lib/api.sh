#!/usr/bin/env bash

pce_request() {
  local method="$1"
  local endpoint="$2"
  local data="${3:-}"

  local auth_header
  auth_header=$(printf "%s:%s" "$PCE_API_KEY" "$PCE_API_SECRET" | base64)

  local url="https://${PCE_FQDN}:${PCE_PORT}/api/v2/orgs/${PCE_ORG_ID}${endpoint}"

  if [[ -n "$data" ]]; then
    curl -s -k -X "$method" "$url" \
      -H "Authorization: Basic ${auth_header}" \
      -H "Content-Type: application/json" \
      -d "$data"
  else
    curl -s -k -X "$method" "$url" \
      -H "Authorization: Basic ${auth_header}" \
      -H "Content-Type: application/json"
  fi
}
