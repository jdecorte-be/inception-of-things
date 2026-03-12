#!/bin/bash
set -e
source "$1"

echo "installing nginx"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/kind/deploy.yaml

echo "==> Installing ArgoCD"
kubectl apply -n "$ARGOCD_NAMESPACE" -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

#kubectl patch svc argocd-server -n "$ARGOCD_NAMESPACE" -p '{"spec": {"type": "LoadBalancer"}}'
kubectl wait --for=condition=Ready pods --all --timeout=69420s -n "$ARGOCD_NAMESPACE"

echo "==> Installing ArgoCD CLI"
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

#echo "==> Port-forwarding ArgoCD"
#nohup kubectl port-forward svc/argocd-server -n "$ARGOCD_NAMESPACE" 8080:443 --address="0.0.0.0" > "$HOME/argocd-log.txt" 2>&1 &
echo "==> ingress ArgoCD"
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/component=controller --timeout=300s -n ingress-nginx
kubectl apply -f ../confs/ingress-argocd.yaml

echo "==> Waiting for ingress to be ready"
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/component=controller --timeout=300s -n ingress-nginx
# Wait for ingress to have an address assigned
while [ -z "$(kubectl get ingress argocd-server-ingress -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)" ] && [ -z "$(kubectl get ingress argocd-server-ingress -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)" ]; do
  echo "Waiting for ingress to get an address..."
  sleep 5
done
echo "Ingress is ready!"

init_pw=$(kubectl -n "$ARGOCD_NAMESPACE" get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo "==> Logging into ArgoCD"
argocd login argocd-server.local --username admin --password "$init_pw" --grpc-web --insecure
argocd account update-password --current-password "$init_pw" --new-password "$ARGOCD_PASSWORD"
