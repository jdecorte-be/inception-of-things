#!/bin/bash

# Create gitlab namespace if it doesn't exist
kubectl create namespace gitlab 2>/dev/null || echo "Namespace gitlab already exists"

kubectl config set-context --current --namespace=gitlab

# Check if ingress controller is already running (from p3 setup)
echo "Checking ingress controller..."
if kubectl get deployment ingress-nginx-controller -n ingress-nginx &>/dev/null; then
  echo "Ingress controller found, ensuring it's running..."
  kubectl scale deployment ingress-nginx-controller -n ingress-nginx --replicas=1 2>/dev/null || true
  kubectl wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=300s || echo "Timeout waiting for ingress controller, continuing..."
else
  echo "Ingress controller not found. Please run p3 setup first."
  exit 1
fi

# Add gitlab helm repo
helm repo add gitlab https://charts.gitlab.io 2>/dev/null || echo "GitLab repo already exists"
helm repo update

helm upgrade --install gitlab gitlab/gitlab \
  --timeout 600s \
  --namespace gitlab \
  --create-namespace \
  --set global.hosts.domain=localhost \
  --set global.hosts.externalIP=127.0.0.1 \
  --set certmanager-issuer.email=me@example.com \
  --set postgresql.image.tag=16.3.0 \
  --set livenessProbe.initialDelaySeconds=220 \
  --set readinessProbe.initialDelaySeconds=220 \
  --set nginx-ingress.enabled=false \
  --set global.ingress.configureCertmanager=false \
  --set global.ingress.tls.enabled=false \
  --set global.ingress.class=nginx

kubectl wait --for=condition=available --timeout=3600s deployment/gitlab-webservice-default -n gitlab

echo "Applying gitlab ingress..."
kubectl apply -f gitlab-ingress.yaml

# Create dev2 namespace if it doesn't exist
kubectl create namespace dev2 2>/dev/null || echo "Namespace dev2 already exists"

echo "Creating ArgoCD application..."
kubectl apply -f argocd-app.yaml

echo "Waiting for application to be ready..."
sleep 10
kubectl wait --for=condition=available --timeout=120s deployment -n dev2 --all 2>/dev/null || echo "Deployment may not be ready yet"

echo "Applying dev2 ingress..."
kubectl apply -f mgomes-d2-ingress.yaml

echo "Adding hostnames to /etc/hosts..."
grep -q "gitlab.localhost" /etc/hosts || echo "127.0.0.1 gitlab.localhost mgomesd.local2" | sudo tee -a /etc/hosts

echo "Deployment complete!"
echo "Access GitLab at: http://gitlab.localhost"
echo "Access your app at: http://mgomesd.local2"