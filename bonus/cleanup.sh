#!/bin/bash

echo "Cleaning up all resources..."

# Delete ArgoCD applications
echo "Deleting ArgoCD applications..."
kubectl delete application argocd-mgomes-d2 -n argocd 2>/dev/null || true

# Delete namespaces
echo "Deleting namespaces..."
kubectl delete namespace gitlab --timeout=60s 2>/dev/null || true
kubectl delete namespace dev2 --timeout=60s 2>/dev/null || true

# Uninstall helm releases
echo "Removing helm releases..."
helm uninstall gitlab -n gitlab 2>/dev/null || true

# Remove ArgoCD repository
echo "Removing ArgoCD repository..."
argocd repo rm https://gitlab.com/mgomes-d/argocd-mgomes-d_bonus.git 2>/dev/null || true

# Delete all evicted and completed pods
echo "Cleaning up evicted and completed pods..."
kubectl get pods --all-namespaces --field-selector=status.phase=Failed -o json | \
  jq -r '.items[] | "\(.metadata.namespace) \(.metadata.name)"' | \
  xargs -n2 sh -c 'kubectl delete pod $1 -n $0 2>/dev/null' || true

kubectl get pods --all-namespaces | grep -E 'Evicted|Completed|Error' | awk '{print $1, $2}' | \
  xargs -n2 sh -c 'kubectl delete pod $1 -n $0 2>/dev/null' || true

# Scale down and delete ingress controller
echo "Cleaning up ingress controller..."
kubectl scale deployment ingress-nginx-controller -n ingress-nginx --replicas=0 2>/dev/null || true
kubectl delete pods --all -n ingress-nginx --force --grace-period=0 2>/dev/null || true

# Delete ingress admission webhook to avoid validation errors
echo "Removing ingress admission webhook..."
kubectl delete validatingwebhookconfiguration ingress-nginx-admission 2>/dev/null || true

# Clean up docker resources to free disk space
echo "Cleaning up docker resources..."
docker system prune -af --volumes 2>/dev/null || true

# Clean journal logs to free space
echo "Cleaning old journal logs..."
sudo journalctl --vacuum-time=3d 2>/dev/null || true

# Remove disk pressure taint from node
echo "Removing disk pressure taint..."
kubectl taint nodes --all node.kubernetes.io/disk-pressure:NoSchedule- 2>/dev/null || true

echo "Cleanup complete!"
