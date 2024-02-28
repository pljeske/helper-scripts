#!/bin/bash

# Set the namespace
if [ -z "$1" ]; then
  namespace="$(kubectl config view --minify | grep namespace | cut -d" " -f6)"
elif [ "$1" == "-n" ] || [ "$1" == "--namespace" ]; then
  namespace="$2"
else
  echo "Invalid argument: $1"
  echo "Usage: $0 [-n|--namespace NAMESPACE]"
  exit 1
fi

# Header for the table
printf "%-25s | %-20s | %-7s | %-7s | %-7s | %-7s\n" "Pod Name" "Container Name" "CPU Req" "CPU Lim" "Mem Req" "Mem Lim"
printf '%*s\n' $(( 73 + 18 - 1 )) | tr ' ' '-'

# Get all pods in the namespace and iterate over them
for pod in $(kubectl get pods -n "$namespace" -o jsonpath='{.items[*].metadata.name}'); do
    # For each pod, fetch container details
    resource_info=$(kubectl get pod "$pod" -n "$namespace" \
      -ojsonpath="{range .spec.containers[*]}{''}${pod}{'|'}{.name}{'|'}{.resources.requests.cpu}{'|'}{.resources.limits.cpu}{'|'}{.resources.requests.memory}{'|'}{.resources.limits.memory}{'\n'}{end}")
    echo "$resource_info" | while IFS='|' read pod_name container_name cpu_requests cpu_limits mem_requests mem_limits; do
      pod_name_trimmed=$(echo "$pod_name" | cut -c 1-25)
      container_name_trimmed=$(echo "$container_name" | cut -c 1-20)
      printf "%-25s | %-20s | %-7s | %-7s | %-7s | %-7s\n" \
        "$pod_name_trimmed" "$container_name_trimmed" "$cpu_requests" "$cpu_limits" "$mem_requests" "$mem_limits"
    done
done
