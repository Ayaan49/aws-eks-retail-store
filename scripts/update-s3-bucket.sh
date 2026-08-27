#!/bin/bash

#############################################
# Script: update-s3-bucket.sh
# Purpose: Update S3 bucket name in all Terraform files
# Usage: ./update-s3-bucket.sh YOUR-BUCKET-NAME
# 
# IMPORTANT: Create your S3 bucket FIRST before running this script!
#############################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Old bucket name to replace
OLD_BUCKET="tfstate-dev-us-east-1-jpjtof"

echo ""
echo "============================================="
echo "  S3 Bucket Name Update Script"
echo "============================================="
echo ""

# Check if new bucket name is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: Please provide your S3 bucket name${NC}"
    echo ""
    echo "Usage: ./update-s3-bucket.sh YOUR-BUCKET-NAME"
    echo ""
    echo "============================================="
    echo -e "${YELLOW}  STEP 1: Create Your S3 Bucket FIRST${NC}"
    echo "============================================="
    echo ""
    echo "Before running this script, create your S3 bucket:"
    echo ""
    echo -e "${CYAN}# Create bucket (use a unique name)${NC}"
    echo "aws s3 mb s3://tfstate-dev-us-east-1-YOUR-UNIQUE-ID --region us-east-1"
    echo ""
    echo -e "${CYAN}# Enable versioning (recommended)${NC}"
    echo "aws s3api put-bucket-versioning --bucket tfstate-dev-us-east-1-YOUR-UNIQUE-ID --versioning-configuration Status=Enabled"
    echo ""
    echo -e "${CYAN}# Verify bucket exists${NC}"
    echo "aws s3 ls | grep tfstate-dev-us-east-1-YOUR-UNIQUE-ID"
    echo ""
    echo "============================================="
    echo -e "${YELLOW}  STEP 2: Run This Script${NC}"
    echo "============================================="
    echo ""
    echo "After bucket is created successfully, run:"
    echo ""
    echo "./update-s3-bucket.sh tfstate-dev-us-east-1-YOUR-UNIQUE-ID"
    echo ""
    exit 1
fi

NEW_BUCKET=$1

echo -e "Old bucket: ${RED}$OLD_BUCKET${NC}"
echo -e "New bucket: ${GREEN}$NEW_BUCKET${NC}"
echo ""

echo "============================================="
echo "  Verifying S3 Bucket Exists..."
echo "============================================="
echo ""

# Check if AWS CLI is configured
if ! command -v aws &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not installed or not in PATH${NC}"
    echo "Please install AWS CLI and configure credentials."
    exit 1
fi

# Check if the bucket exists
if aws s3api head-bucket --bucket "$NEW_BUCKET" 2>/dev/null; then
    echo -e "${GREEN}✓ Bucket '$NEW_BUCKET' exists and is accessible!${NC}"
else
    echo -e "${RED}✗ Bucket '$NEW_BUCKET' does NOT exist or is not accessible!${NC}"
    echo ""
    echo "============================================="
    echo -e "${YELLOW}  Please Create Your Bucket First${NC}"
    echo "============================================="
    echo ""
    echo "Run these commands to create your bucket:"
    echo ""
    echo -e "${CYAN}# Create bucket${NC}"
    echo "aws s3 mb s3://$NEW_BUCKET --region us-east-1"
    echo ""
    echo -e "${CYAN}# Enable versioning (recommended)${NC}"
    echo "aws s3api put-bucket-versioning --bucket $NEW_BUCKET --versioning-configuration Status=Enabled"
    echo ""
    echo -e "${CYAN}# Then re-run this script${NC}"
    echo "./update-s3-bucket.sh $NEW_BUCKET"
    echo ""
    exit 1
fi

echo ""

# Confirm before proceeding
read -p "Do you want to proceed with updating Terraform files? (y/n): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Operation cancelled."
    exit 0
fi

echo ""
echo "============================================="
echo "  Finding Files to Update..."
echo "============================================="
echo ""

# Find all files containing the old bucket name
FILES=$(grep -rl "$OLD_BUCKET" . --include="*.tf" --include="*.json" 2>/dev/null)

if [ -z "$FILES" ]; then
    echo -e "${YELLOW}No files found containing '$OLD_BUCKET'${NC}"
    echo ""
    echo "Possible reasons:"
    echo "- You've already updated the files"
    echo "- You're running this from the wrong directory"
    echo ""
    echo "Make sure to run this script from the correct directory:"
    echo "  cd 20_Observability_OpenTelemetry"
    echo "  ./update-s3-bucket.sh $NEW_BUCKET"
    exit 1
fi

# Count files
FILE_COUNT=$(echo "$FILES" | wc -l | tr -d ' ')
echo -e "Found ${YELLOW}$FILE_COUNT${NC} files to update:"
echo ""
echo "$FILES"
echo ""

echo "============================================="
echo "  Updating Files..."
echo "============================================="
echo ""

# Detect OS for sed compatibility (macOS vs Linux)
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    for file in $FILES; do
        sed -i '' "s|$OLD_BUCKET|$NEW_BUCKET|g" "$file"
        echo -e "${GREEN}✓${NC} Updated: $file"
    done
else
    # Linux
    for file in $FILES; do
        sed -i "s|$OLD_BUCKET|$NEW_BUCKET|g" "$file"
        echo -e "${GREEN}✓${NC} Updated: $file"
    done
fi

echo ""
echo "============================================="
echo "  Verification"
echo "============================================="
echo ""

# Verify no old references remain
REMAINING=$(grep -rl "$OLD_BUCKET" . --include="*.tf" --include="*.json" 2>/dev/null)

if [ -z "$REMAINING" ]; then
    echo -e "${GREEN}✓ Success! All references updated to: $NEW_BUCKET${NC}"
else
    echo -e "${RED}Warning: Some files still contain old bucket name:${NC}"
    echo "$REMAINING"
fi

echo ""
echo "============================================="
echo "  Next Steps"
echo "============================================="
echo ""
echo "Your S3 bucket is ready and Terraform files are updated!"
echo ""
echo "Now run the cluster creation script:"
echo -e "   ${CYAN}./create-cluster-with-karpenter-and-opentelemetry.sh${NC}"
echo ""
echo "============================================="
echo -e "  ${GREEN}Done! Happy Learning! 🚀${NC}"
echo "============================================="

