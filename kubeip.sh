#!/bin/sh

################################################################################################
## Script to search for pods or services in a Kubernetes cluster by their cluster internal IP ##
################################################################################################

namespace=""
res_type=""
ip="$1"

if [ "$ip" = "" ]; then
  echo "Usage: kubeip <ip>"
  exit 1
fi

if [ "$2" != "" ]; then
  case "$2" in
    -n=*|--namespace=*)
      namespace="${2#*=}";;
    -n*|--namespace*)
      namespace="$3";;
    *)
      echo "Invalid parameter. Usage: kubeip <ip> [[--namespace <namespace>]|[-n <namespace>]"
      exit 1;;
  esac
fi

if [ "$namespace" = "" ]; then
  if kubectl auth can-i list pods --all-namespaces >/dev/null 2>&1; then
    pod_ns="-A"
  else
    echo "User doesn't have permission to list pods in all namespaces. Only searching namespace in current context."
    pod_ns=""
  fi
  if kubectl auth can-i list svc --all-namespaces >/dev/null 2>&1; then
    svc_ns="-A"
  else
    echo "User doesn't have permission to list services in all namespaces. Only searching namespace in current context."
    svc_ns=""
  fi
else
  pod_ns="-n $namespace"
  svc_ns="-n $namespace"
fi

svc=$(kubectl get svc $svc_ns -o jsonpath="{range .items[?(@.spec.clusterIP == \"$ip\")]}{@.metadata.name}{\" \"}{@.metadata.namespace}")
pod=$(kubectl get pods $pod_ns -o jsonpath="{range .items[?(@.status.podIP == \"$ip\")]}{.metadata.name}{\" \"}{.metadata.namespace}")

if ! echo "$svc" | grep -q '^[[:space:]]*$'; then
  res_type="Service"
  res_name=$(echo "$svc" | awk '{print $1}')
  res_namespace=$(echo "$svc" | awk '{print $2}')
elif ! echo "$pod" | grep -q '^[[:space:]]*$'; then
  res_type="Pod"
  res_name=$(echo "$pod" | awk '{print $1}')
  res_namespace=$(echo "$pod" | awk '{print $2}')
fi

if [ "$res_type" = "" ]; then
  if [ "$namespace" = "" ]; then
    echo "No resources found with a cluster internal IP of $ip"
  else
    echo "No resources found with a cluster internal IP of $ip in namespace $namespace"
  fi
else
  if [ "$res_type" = "Pod" ]; then
    kubectl get pod "$res_name" -n "$res_namespace" -ocustom-columns='KIND:.kind,NAME:.metadata.name,NAMESPACE:.metadata.namespace,IP:.status.podIP'
  else
    kubectl get svc "$res_name" -n "$res_namespace" -ocustom-columns='KIND:.kind,NAME:.metadata.name,NAMESPACE:.metadata.namespace,CLUSTER-IP:.spec.clusterIP'
  fi
fi