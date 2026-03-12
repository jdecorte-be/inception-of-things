#!/bin/bash
set -euo pipefail
set -x

# Only install tools if kubectl is not found
if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl not found, running install tools..."
  bash ../confs/01-install-tools.sh
  exit 1
else
  echo "kubectl is already installed, skipping install tools."
fi

bash ../confs/02-create-cluster.sh ../confs/config.env
bash ../confs/03-install-argocd.sh ../confs/config.env
bash ../confs/04-deploy-app.sh ../confs/config.env
