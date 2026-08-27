#!/bin/bash
# 05-v2.0.0-install-remote-helm-charts.sh
# Helm Charts which need Secrets from AWS Secrets Manager
set -e

echo "============================================"
echo "Retail Store Sample App - Helm Installation"
echo "============================================"
echo

echo "--------------------------------------------"
echo "Adding Helm Repository..."
echo "--------------------------------------------"

# Add Helm repository
helm repo add stacksimplify https://stacksimplify.github.io/helm-charts
helm repo update

echo "✅ Helm repository added and updated"
sleep 3

echo
echo "============================================"
echo "Starting Helm Installations..."
echo "============================================"
echo

# Step 01 - Catalog Service
echo "--------------------------------------------"
echo "Step 1/5: Installing Catalog Service..."
echo "--------------------------------------------"
helm upgrade --install catalog stacksimplify/retail-store-sample-catalog-chart \
  --version 2.0.0 \
  -f values-catalog-v2.0.0.yaml \
  --wait \
  --timeout 5m

echo "✅ Catalog service installed successfully"
sleep 5

# Step 02 - Cart Service
echo
echo "--------------------------------------------"
echo "Step 2/5: Installing Cart Service..."
echo "--------------------------------------------"
helm upgrade --install carts stacksimplify/retail-store-sample-cart-chart \
  --version 1.0.0 \
  -f values-cart.yaml \
  --wait \
  --timeout 5m

echo "✅ Cart service installed successfully"
sleep 5

# Step 03 - Checkout Service
echo
echo "--------------------------------------------"
echo "Step 3/5: Installing Checkout Service..."
echo "--------------------------------------------"
helm upgrade --install checkout stacksimplify/retail-store-sample-checkout-chart \
  --version 1.0.0 \
  -f values-checkout.yaml \
  --wait \
  --timeout 5m

echo "✅ Checkout service installed successfully"
sleep 5

# Step 04 - Orders Service
echo
echo "--------------------------------------------"
echo "Step 4/5: Installing Orders Service..."
echo "--------------------------------------------"
helm upgrade --install orders stacksimplify/retail-store-sample-orders-chart \
  --version 2.0.0 \
  -f values-orders-v2.0.0.yaml \
  --wait \
  --timeout 5m

echo "✅ Orders service installed successfully"
sleep 5

# Step 05 - UI Service
echo "✅ UI service will be deployed using ArgoCD"
#echo
#echo "--------------------------------------------"
#echo "Step 5/5: Installing UI Service..."
#echo "--------------------------------------------"
#helm upgrade --install ui stacksimplify/retail-store-sample-ui-chart \
#  --version 1.0.0 \
#  -f values-ui.yaml \
#  --wait \
#  --timeout 5m

#echo "✅ UI service installed successfully"
#sleep 3

echo
echo "============================================"
echo "Installation Summary"
echo "============================================"

# Display installed releases
echo
echo "Installed Helm Releases:"
helm list

# Display Deployed releases
echo
echo "Deployed Pods:"
kubectl get pods -o wide

# Display Deployed Services
echo
echo "Services:"
kubectl get svc

# Display Service Accounts
echo
echo "Service Accounts:"
kubectl get sa

# Display ConfigMaps
echo
echo "ConfigMaps:"
kubectl get cm

# Display Ingress Service
echo
echo "Ingress Service:"
kubectl get ingress

# Display SecretProviderClass Service
echo
echo "List SecretProviderClass"
kubectl get secretproviderclass

echo
echo "============================================"
echo "✅ All services installed successfully!"
echo "============================================"
echo
echo "Next Steps:"
echo "1. Verify all pods are running: kubectl get pods"
echo "2. Check service endpoints: kubectl get svc"
echo "3. Access the Ingress service ADDRESS to test the application"
echo 