#!/usr/bin/env bash

get_snow_ci_labels() {
  local hostname="$1"
  local url="https://${SNOW_INSTANCE}/api/now/table/cmdb_ci_server?sysparm_query=name=${hostname}&sysparm_fields=u_app_role,u_app_environment,u_application_id,u_location"

  curl -s -u "${SNOW_USER}:${SNOW_PASS}" \
    -H "Accept: application/json" "$url" | \
    jq -r '.result[0] // empty'
}

apply_workload_labels() {
  local workload_href="$1"
  local label_json="$2" # Array of hrefs: [{"href": "..."}, ...]

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[DRY-RUN] Would update $workload_href with labels: $label_json"
    return 0
  fi

  pce_request "PUT" "$workload_href" "{\"labels\": $label_json}"
}
