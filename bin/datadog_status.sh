#!/bin/bash

# Discover all datadog pods and their namespaces
pod_entries=()
while IFS= read -r line; do
  [ -n "$line" ] && pod_entries+=("$line")
done < <(kubectl get pods -A --no-headers 2>/dev/null | awk '$2 ~ /^datadog-/ {print $1" "$2}')

if [ ${#pod_entries[@]} -eq 0 ]; then
  echo "No pods matching 'datadog-' were found in any namespace."
  exit 0
fi

echo "Found ${#pod_entries[@]} datadog pod(s)."

success_count=0
failed_count=0

# Loop over each <namespace pod>
for entry in "${pod_entries[@]}"; do
  namespace="${entry%% *}"
  pod="${entry#* }"

  echo "############################################################################################################"
  echo "Getting status for pod: $pod (namespace: $namespace)"
  echo "############################################################################################################"

  # Run 'agent status' command and capture the output
  if ! output=$(kubectl exec "$pod" -n "$namespace" -- agent status 2>&1); then
    if echo "$output" | grep -q 'exec: "agent": executable file not found'; then
      echo "Failed to get status for pod: $pod (namespace: $namespace)"
      echo "Reason: 'agent' binary not found in container"
      echo "$output"
      failed_count=$((failed_count + 1))
    else
      echo "Failed to get status for pod: $pod (namespace: $namespace)"
      echo "$output"
      failed_count=$((failed_count + 1))
    fi
    continue
  fi

  echo "$output"
  success_count=$((success_count + 1))
  # Extract the section for 'openmetrics'
  # echo "$output" | awk '/openmetrics \(4\.0\.0\)/,/-------------------/{flag=1;next} /orchestrator_pod/,/-------------------/{flag=0} flag'
done

echo "Summary: success=$success_count failed=$failed_count"
exit 0
