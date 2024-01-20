#!/bin/bash

function random_string() {
  echo $RANDOM > /dev/null
  echo $RANDOM | md5sum | head -c 5
}

function main() {
  local pvc="$1"

  if [ -z "$pvc" ]; then
    echo "Provide pvc name!"
    exit 1
  fi

  local pod_name="pvc-debugger-$(random_string)"

  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: $pod_name
spec:
  securityContext:
    runAsUser: 1001
    runAsGroup: 1001
  volumes:
  - name: pvc
    persistentVolumeClaim:
      claimName: $pvc
  containers:
  - name: debugger
    image: busybox
    command:
    - /bin/sh
    - -c
    - "trap : TERM INT; sleep 3600 & wait"
    volumeMounts:
    - mountPath: /pvc
      name: pvc
EOF

  sleep 1
  kubectl wait --for=condition=ready --timeout=180s pod "$pod_name"
  kubectl exec -it "$pod_name" -- sh
  kubectl delete pod "$pod_name"
}

main "$@"
