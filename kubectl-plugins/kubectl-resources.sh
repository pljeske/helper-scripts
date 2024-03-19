#!/bin/bash

function print_header() {
  # Header for the table
  printf "%-25s | %-20s | %-7s | %-7s | %-7s | %-7s\n" "Pod Name" "Container Name" "CPU Req" "CPU Lim" "Mem Req" "Mem Lim"
  printf '%*s\n' $((73 + 18 - 1)) | tr ' ' '-'
}

function trim() {
  local string="$1"
  local length="$2"
  echo "${string:0:length}"
}

function print_pod_resources() {
  local namespace="$1"
  # Get all pods in the namespace and iterate over them
  local pod
  local resource_info
  for pod in $(kubectl get pods -n "$namespace" -o jsonpath='{.items[*].metadata.name}'); do
    # For each pod, fetch container details
    resource_info=$(kubectl get pod "$pod" -n "$namespace" \
      -ojsonpath="{range .spec.containers[*]}{''}${pod}{'|'}{.name}{'|'}{.resources.requests.cpu}{'|'}{.resources.limits.cpu}{'|'}{.resources.requests.memory}{'|'}{.resources.limits.memory}{'\n'}{end}")
    echo "$resource_info" | while IFS='|' read pod_name container_name cpu_requests cpu_limits mem_requests mem_limits; do
      printf "%-25s | %-20s | %-7s | %-7s | %-7s | %-7s\n" \
        "$(trim "$pod_name" 25)" "$(trim "$container_name" 20)" "$cpu_requests" "$cpu_limits" "$mem_requests" "$mem_limits"
    done
  done
  # print footer
  printf '%*s\n' $((73 + 18 - 1)) | tr ' ' '-'
}

function main() {
  local namespace
  # Set the namespace
  if [ -z "$1" ]; then
    namespace="$(kubectl config view --minify | grep namespace | cut -d" " -f6)"
  elif [ "$1" == "-A" ] || [ "$1" == "--all-namespaces" ]; then
    namespace="ALL"
  elif [ "$1" == "-n" ] || [ "$1" == "--namespace" ]; then
    namespace="$2"
  else
    echo "Invalid argument: $1"
    echo "Usage: $0 [-n|--namespace NAMESPACE]"
    exit 1
  fi

  if [ "$namespace" == "ALL" ]; then
    # Get all namespaces
    for namespace in $(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}'); do
      local number_of_pods
      number_of_pods=$(kubectl get pods -n "$namespace" -ojsonpath='{.items[*].metadata.name}' | wc -w)
      if [ "$number_of_pods" -ne 0 ]; then
        echo "NAMESPACE: $namespace"
        print_header
        print_pod_resources "$namespace"
        echo
      else
        echo "NAMESPACE: $namespace"
        echo "(no pods)"
        echo
      fi
    done
  else
    print_header
    print_pod_resources "$namespace"
  fi
}

main "$@"
