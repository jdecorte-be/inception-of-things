#!/bin/bash
set -e

source "$1"
KUBECONFIG_PATH="$HOME/.kube/config"

echo "==> Creating k3d cluster: $CLUSTER_NAME"

k3d cluster create mycluster \
  --k3s-arg '--disable=traefik@server:*' \
  --port '80:80@loadbalancer' \
  --port '443:443@loadbalancer' \
  --k3s-node-label 'ingress-ready=true@server:*'

kubectl label node k3d-"$CLUSTER_NAME"-server-0 ingress-ready=true
export KUBECONFIG=$(k3d kubeconfig write "$CLUSTER_NAME")
mkdir -p "$(dirname "$KUBECONFIG_PATH")"
cp "$KUBECONFIG" "$KUBECONFIG_PATH"

until kubectl get nodes &> /dev/null; do
	sleep 1
done

kubectl create namespace $ARGOCD_NAMESPACE
kubectl create namespace $DEV_NAMESPACE

kubectl cluster-info
