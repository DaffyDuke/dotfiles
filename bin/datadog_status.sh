#!/bin/bash

# Get all pods starting with 'datadog-'
pods=$(kubectl get pods -n decathlon-system -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep '^datadog-')

# Loop over each pod
for pod in $pods; do
  echo "############################################################################################################"
  echo "Getting status for pod: $pod"
  echo "############################################################################################################"

  # Run 'agent status' command and capture the output
  output=$(kubectl exec -it $pod -n decathlon-system -- agent status)

  echo "$output"
  # Extract the section for 'openmetrics'
  # echo "$output" | awk '/openmetrics \(4\.0\.0\)/,/-------------------/{flag=1;next} /orchestrator_pod/,/-------------------/{flag=0} flag'
done
