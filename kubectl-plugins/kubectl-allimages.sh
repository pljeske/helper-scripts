#!/bin/bash

namespace="-A"
if [ "$1" = "-n" ] || [ "$1" = "--namespace" ]; then
  namespace="-n $2"
fi

images=$(kubectl get pods $namespace -ojsonpath='{.items[*].spec.containers[*].image}' | tr ' ' '\n')
echo "$images" | sort | uniq