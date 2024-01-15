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

  sleep 2
  kubectl exec -it "$pod_name" -- sh
  kubectl delete pod "$pod_name"
}

main "$@"
