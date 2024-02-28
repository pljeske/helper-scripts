#!/bin/bash

function random_string() {
  echo $RANDOM > /dev/null
  echo $RANDOM | md5sum | head -c 5
}

function main() {
  local namespace=""
  local pod_name=""
  local tmp_pod_manifest=""
  if [[ "$1" == "-n" || "$1" == "--namespace" ]]; then
    namespace="$2"
  fi

  pod_name="pvc-debugger-$(random_string)"
  tmp_pod_manifest=$(mktemp)

  cat <<EOF > "$tmp_pod_manifest"
apiVersion: v1
kind: Pod
metadata:
  name: $pod_name
spec:
  securityContext:
    runAsUser: 1001
    runAsGroup: 1001
  containers:
  - name: debugger
    image: busybox
    command:
    - /bin/sh
    - -c
    - "trap : TERM INT; sleep 3600 & wait"
EOF
  if [[ -n "$namespace" ]]; then
    kubectl apply -f "$tmp_pod_manifest" -n "$namespace"
  else
    kubectl apply -f "$tmp_pod_manifest"
  fi
  sleep 1
  kubectl wait --for=condition=ready --timeout=180s pod "$pod_name" > /dev/null
  kubectl exec -it "$pod_name" -- sh
  kubectl delete pod "$pod_name"
}

main "$@"
