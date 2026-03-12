#!/bin/bash
set -e

echo "==> Deleting ArgoCD application and namespaces"
kubectl delete application.argoproj.io --all --all-namespaces || true
kubectl delete ns argocd dev ingress-nginx || true

echo "==> Deleting k3d cluster"
k3d cluster delete mycluster || true

echo "==> Removing kubectl"
sudo rm -f /usr/local/bin/kubectl

echo "==> Removing ArgoCD CLI"
sudo rm -f /usr/local/bin/argocd

echo "==> Uninstalling k3d"
sudo rm -f /usr/local/bin/k3d

echo "==> Stopping and removing Docker"
sudo systemctl stop docker
sudo apt-get purge -y docker-ce docker-ce-cli containerd.io
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
sudo rm -rf /etc/docker
sudo rm -rf /etc/apt/keyrings/docker.gpg
sudo rm -f /etc/apt/sources.list.d/docker.list

echo "==> Removing ArgoCD logs and configs"
rm -f ~/argocd-log.txt
rm -rf ~/.kube
rm -rf ~/.config/argocd

echo "==> Cleaning up remaining packages"
sudo apt-get autoremove -y
sudo apt-get clean

echo "✅ All tools, clusters, and configurations have been removed."

