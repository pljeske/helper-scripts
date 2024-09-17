#!/bin/bash

# Function to display help
function display_help() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -n, --namespace   Specify the namespace (defaults to current namespace)"
  echo "  -d, --deployment  Specify a deployment (if omitted, applies to all deployments)"
  echo "  -s, --statefulset Specify a statefulset (if omitted, applies to all statefulsets)"
  echo "  -m, --daemonset   Specify a daemonset (if omitted, applies to all daemonsets)"
  echo "  -h, --help        Show this help message"
  exit 0
}

# Parse arguments
namespace="$(kubectl config view --minify | grep namespace | cut -d" " -f6)"
deployment=""
statefulset=""
daemonset=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -n|--namespace)
      namespace="$2"
      shift 2
      ;;
    -d|--deployment)
      deployment="$2"
      shift 2
      ;;
    -s|--statefulset)
      statefulset="$2"
      shift 2
      ;;
    -m|--daemonset)
      daemonset="$2"
      shift 2
      ;;
    -h|--help)
      display_help
      ;;
    *)
      echo "Unknown option: $1"
      display_help
      ;;
  esac
done

# Function to create VPA
create_vpa() {
  local name=$1
  local kind=$2
  echo "Creating VPA for $kind: $name in namespace: $namespace"
  cat <<EOF | kubectl apply -f -
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: $name
  namespace: $namespace
  labels:
    app.kubernetes.io/instance: $name
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: $kind
    name: $name
  updatePolicy:
    updateMode: "Auto"
EOF
}

# Handle Deployments
if [[ -n "$deployment" ]]; then
  create_vpa "$deployment" "Deployment"
else
  deployments=$(kubectl get deploy -n "$namespace" -o jsonpath='{.items[*].metadata.name}')
  for deploy in $deployments; do
    create_vpa "$deploy" "Deployment"
  done
fi

# Handle StatefulSets
if [[ -n "$statefulset" ]]; then
  create_vpa "$statefulset" "StatefulSet"
else
  statefulsets=$(kubectl get statefulset -n "$namespace" -o jsonpath='{.items[*].metadata.name}')
  for sts in $statefulsets; do
    create_vpa "$sts" "StatefulSet"
  done
fi

# Handle DaemonSets
if [[ -n "$daemonset" ]]; then
  create_vpa "$daemonset" "DaemonSet"
else
  daemonsets=$(kubectl get daemonset -n "$namespace" -o jsonpath='{.items[*].metadata.name}')
  for ds in $daemonsets; do
    create_vpa "$ds" "DaemonSet"
  done
fi
