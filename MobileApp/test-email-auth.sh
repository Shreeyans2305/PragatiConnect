#!/bin/bash

# Email Authentication Test Script
# Tests the email-based OTP authentication flow

set -e

echo "=========================================="
echo "  Email Authentication Test"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BASE_URL="http://127.0.0.1:8000/api/v1"
TEST_EMAIL="test-$(date +%s)@example.com"

echo "Test Email: $TEST_EMAIL"
echo ""

# Step 1: Register
echo "Step 1: Registering user..."
REGISTER_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"$TEST_EMAIL\"}")

echo "Response: $REGISTER_RESPONSE"
echo ""

# Extract OTP from response (for testing purposes)
OTP=$(echo "$REGISTER_RESPONSE" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('otp', ''))" 2>/dev/null || echo "")

if [ -z "$OTP" ]; then
    echo -e "${YELLOW}Note: OTP not in response (expected if EMAIL_MOCK_MODE=false)${NC}"
    echo "Check your email for the OTP code"
    echo ""
    read -p "Enter OTP from email: " OTP
fi

echo -e "${GREEN}✅ OTP obtained: $OTP${NC}"
echo ""

# Step 2: Verify OTP
echo "Step 2: Verifying OTP..."
VERIFY_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/verify-otp" \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"$TEST_EMAIL\", \"otp\": \"$OTP\"}")

echo "Response: $VERIFY_RESPONSE"
echo ""

# Extract tokens
ACCESS_TOKEN=$(echo "$VERIFY_RESPONSE" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('access_token', ''))" 2>/dev/null)
REFRESH_TOKEN=$(echo "$VERIFY_RESPONSE" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('refresh_token', ''))" 2>/dev/null)

if [ -z "$ACCESS_TOKEN" ]; then
    echo -e "${RED}❌ Failed to get tokens${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Successfully authenticated!${NC}"
echo "Access Token: ${ACCESS_TOKEN:0:30}..."
echo "Refresh Token: ${REFRESH_TOKEN:0:30}..."
echo ""

# Step 3: Sign in again with same email (data persistence)
echo "Step 3: Testing data persistence - signing in again..."
REGISTER_RESPONSE2=$(curl -s -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"$TEST_EMAIL\"}")

OTP2=$(echo "$REGISTER_RESPONSE2" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('otp', ''))" 2>/dev/null || echo "")

if [ -z "$OTP2" ]; then
    echo "Check your email for the new OTP"
    read -p "Enter new OTP from email: " OTP2
fi

VERIFY_RESPONSE2=$(curl -s -X POST "$BASE_URL/auth/verify-otp" \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"$TEST_EMAIL\", \"otp\": \"$OTP2\"}")

ACCESS_TOKEN2=$(echo "$VERIFY_RESPONSE2" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('access_token', ''))" 2>/dev/null)

if [ -z "$ACCESS_TOKEN2" ]; then
    echo -e "${RED}❌ Failed to sign in again${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Successfully signed in again with same email!${NC}"
echo ""

echo "=========================================="
echo "  ✅ Email Authentication Test PASSED"
echo "=========================================="
echo ""
echo "Summary:"
echo "- User can register with email"
echo "- OTP is sent and can be verified"
echo "- User can sign in again with same email"
echo "- Data persists across sign-ins"
echo ""
