#!/bin/bash
set -e
source "$1"

echo "==> Setting ArgoCD context"
argocd login argocd-server.local --username admin --password "$ARGOCD_PASSWORD" --grpc-web
kubectl config set-context --current --namespace="$ARGOCD_NAMESPACE"

echo "==> Creating ArgoCD app: $APP_NAME"
argocd app create "$APP_NAME" \
  --repo "$GIT_REPO_URL" \
  --path "$APP_PATH" \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace "$DEV_NAMESPACE"

argocd app set "$APP_NAME" --sync-policy automated
argocd app sync "$APP_NAME"

#echo "==> Port-forwarding deployed app on 8888"
echo "==> ingress-nginx"

#nohup kubectl wait --for=condition=Ready pods --all --timeout=6969s -n "$DEV_NAMESPACE" 2>&1 > "$HOME/dev-wait.log" 2>&1 & 
#nohup kubectl port-forward services/"$APP_NAME" 8888 -n "$DEV_NAMESPACE" --address="0.0.0.0" > "$HOME/dev-server.log" 2>&1 &
#kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.13.0/deploy/static/provider/cloud/deploy.yaml
#kubectl wait --namespace ingress-nginx \
#  --for=condition=Ready pods \
#  --all --timeout=90s
kubectl apply -f ../confs/mgomes-d-ingress.yaml
