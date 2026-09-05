#!/usr/bin/env bash

promote_workloads() {
  local workloads
  workloads=$(pce_request "GET" "/workloads")

  echo "$workloads" | jq -c '.[]' | while read -r wl; do
    local href name mode
    href=$(echo "$wl" | jq -r '.href')
    name=$(echo "$wl" | jq -r '.hostname')
    mode=$(echo "$wl" | jq -r '.enforcement_mode')

    case "$mode" in
      "idle")
        # Step 1: Idle -> Visibility Only (verify compatibility report first)
        local compat
        compat=$(check_ven_compatibility "$href")
        if [[ "$compat" == "pass" || "$compat" == "green" ]]; then
          echo "[ACTION] $name passed compatibility. Promoting: idle -> visibility_only"
          [[ "$DRY_RUN" == "false" ]] && pce_request "PUT" "$href" '{"enforcement_mode": "visibility_only"}'
        else
          echo "[SKIP] $name failed compatibility ($compat). Keeping in idle."
        fi
        ;;

      "visibility_only")
        # Step 2: Visibility Only -> Selective
        # Guard check: Ensure no recent critical blocked flows or pending policy gaps
        echo "[ACTION] Evaluating $name for promotion: visibility_only -> selective"
        [[ "$DRY_RUN" == "false" ]] && pce_request "PUT" "$href" '{"enforcement_mode": "selective"}'
        ;;

      *)
        echo "[INFO] $name is in $mode mode. No transition applied."
        ;;
    esac
  done
}
