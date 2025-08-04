#!/bin/bash
set -euo pipefail
trap 'echo "Error on line $LINENO"; exit 1' ERR

DEFAULT_AMI_ID="ami-0fd75e484b77fbb03"  # Default AMI ID for eu-west-1 region
DEFAULT_ARM_AMI_ID="ami-092ba6c0ef26570bf"
DEFAULT_EMAIL="test@example.com"
REGION="eu-west-1"

BUILD_AMI=false
INTERACTIVE=false
EMAIL=$DEFAULT_EMAIL
AMI_ID=$DEFAULT_AMI_ID
ARM_AMI_ID=$DEFAULT_ARM_AMI_ID

# Parse CLI args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --build-ami)
      BUILD_AMI=true
      shift
      ;;
    --ami)
      AMI_ID="$2"
      shift 2
      ;;
    --arm-ami)
      ARM_AMI_ID="$2"
      shift 2
      ;;
    --email)
      EMAIL="$2"
      shift 2
      ;;
    --interactive)
      INTERACTIVE=true
      shift
      ;;
    *)
      echo "Unknown argument: $1"
      echo "Usage: $0 [--build-ami] [--ami <ami-id>] [--arm-ami <arm-ami-id>] [--email your@email.com] [--interactive]"
      exit 1
      ;;
  esac
done

# === AMI selection ===
if $INTERACTIVE; then
  echo "Do you want to build both x86_64 and ARM AMIs from source using metagraph-ami.yaml?"
  read -p "NOTE: This will take around 30 minutes and uses EC2 compute. [y/N]: " BUILD_BOTH
  BUILD_BOTH="${BUILD_BOTH,,}"

  if [[ "$BUILD_BOTH" == "y" || "$BUILD_BOTH" == "yes" ]]; then
    BUILD_AMI=true
  else
    read -p "Enter general (x86_64) AMI ID [${DEFAULT_AMI_ID}]: " AMI_ID
    AMI_ID="${AMI_ID:-$DEFAULT_AMI_ID}"

    read -p "Enter ARM (aarch64) AMI ID [${DEFAULT_ARM_AMI_ID}]: " ARM_AMI_ID
    ARM_AMI_ID="${ARM_AMI_ID:-$DEFAULT_ARM_AMI_ID}"
  fi
fi

if $BUILD_AMI; then
  echo "Deploying AMI builder stack..."
  aws cloudformation deploy \
    --template-file metagraph-ami.yaml \
    --capabilities CAPABILITY_IAM \
    --stack-name MetagraphAmiBuilder

  echo "Waiting for AMI to finish building..."
  sleep 10  # Give some time for the stack output to be available
  AMI_ID=$(aws cloudformation describe-stacks \
    --stack-name MetagraphAmiBuilder \
    --query "Stacks[0].Outputs[?OutputKey=='AmiId'].OutputValue" \
    --output text)

  ARM_AMI_ID=$(aws cloudformation describe-stacks \
    --stack-name MetagraphAmiBuilder \
    --query "Stacks[0].Outputs[?OutputKey=='ArmAmiId'].OutputValue" \
    --output text)
fi

echo "Using AMI: $AMI_ID"
echo "Using ARM AMI: $ARM_AMI_ID"

# === Email selection ===
if $INTERACTIVE; then
  read -p "Notification email [${DEFAULT_EMAIL}]: " EMAIL
  EMAIL="${EMAIL:-$DEFAULT_EMAIL}"
fi

echo "Using notification email: $EMAIL"

# === Detect default VPC and security group ===
echo "Detecting default VPC and its security group in region $REGION..."

VPC_ID=$(aws ec2 describe-vpcs \
  --region "$REGION" \
  --filters Name=isDefault,Values=true \
  --query 'Vpcs[0].VpcId' \
  --output text)

SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
  --region "$REGION" \
  --filters Name=vpc-id,Values="$VPC_ID" Name=group-name,Values=default \
  --query 'SecurityGroups[0].GroupId' \
  --output text)

echo "Using VPC: $VPC_ID"
echo "Using Security Group: $SECURITY_GROUP_ID"

# === Deploy main stack ===
aws cloudformation deploy \
  --template-file metagraph-stack.yaml \
  --capabilities CAPABILITY_IAM \
  --stack-name MetagraphQuerySystem \
  --region "$REGION" \
  --parameter-overrides \
    NotificationEmail="$EMAIL" \
    MetagraphAmiId="$AMI_ID" \
    MetagraphArmAmiId="$ARM_AMI_ID" \
    SecurityGroupId="$SECURITY_GROUP_ID"
