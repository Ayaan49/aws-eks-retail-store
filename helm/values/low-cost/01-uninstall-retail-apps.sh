#!/bin/bash

echo "Starting Helm uninstalls for Retail Store Sample App..."
echo

# Step 05 - UI Service
#echo "Uninstalling UI Service..."
#helm uninstall ui
#sleep 10

# Step 04 - Orders Service
echo "Uninstalling Orders Service..."
helm uninstall orders
sleep 10

# Step 03 - Checkout Service
echo "Uninstalling Checkout Service..."
helm uninstall checkout
sleep 10

# Step 02 - Cart Service
echo "Uninstalling Cart Service..."
helm uninstall carts
sleep 10

# Step 01 - Catalog Service
echo "Uninstalling Catalog Service..."
helm uninstall catalog
sleep 10

echo
echo "All Helm uninstalls completed!"

echo
echo "============================================"
echo "Uninstallation Summary"
echo "============================================"

# List Helm Releases
echo
echo "Should not see any Retail Store Helm Releases:"
helm list