#!/bin/bash

set -e

echo "[1/5] Creating namespace: argocd"
kubectl create namespace argocd || echo "Namespace already exists"

echo "[2/5] Installing ArgoCD core components..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for ArgoCD server deployment to be ready..."
kubectl rollout status deployment argocd-server -n argocd --timeout=120s

echo "[3/5] Fetching default ArgoCD admin password..."
DEFAULT_PASSWORD=$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 --decode)

echo ""
echo "[4/5] Access ArgoCD UI:"
echo "    kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "    Then open https://localhost:8080 in your browser"
echo ""
echo "Login credentials:"
echo "    Username: admin"
echo "    Password: $DEFAULT_PASSWORD"
echo ""
echo "[5/5] Optionally log in via CLI:"
echo "    argocd login localhost:8080 --username admin --password $DEFAULT_PASSWORD --insecure"
