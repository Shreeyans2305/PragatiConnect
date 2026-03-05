#!/bin/bash

# Test image upload with proper MIME types

echo "=== Testing Image Upload with MIME Type Fix ==="

# Create a test image (1x1 PNG)
TEST_IMAGE="/tmp/test_image.png"
python3 << 'EOF'
from PIL import Image
import os
img = Image.new('RGB', (100, 100), color='red')
img.save("/tmp/test_image.png")
print(f"Created test image: {os.path.getsize('/tmp/test_image.png')} bytes")
EOF

# Register and get token
echo "1. Registering user..."
curl -s -X POST "http://127.0.0.1:8000/api/v1/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com"}' > /dev/null

echo "2. Getting OTP token..."
TOKEN=$(curl -s -X POST "http://127.0.0.1:8000/api/v1/auth/verify-otp" \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "otp": "123456"}' | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

if [ -z "$TOKEN" ]; then
  echo "✗ Failed to get authentication token"
  exit 1
fi

echo "3. Token obtained: ${TOKEN:0:20}..."

# Test upload
echo "4. Testing image upload..."
RESPONSE=$(curl -s -X POST "http://127.0.0.1:8000/api/v1/price/estimate" \
  -H "Authorization: Bearer $TOKEN" \
  -F "image=@$TEST_IMAGE" \
  -F "language=en")

# Check response
if echo "$RESPONSE" | grep -q "detail.*Invalid file type"; then
  echo "✗ Image upload failed - Invalid file type error"
  echo "Response: $RESPONSE"
  exit 1
elif echo "$RESPONSE" | grep -q "error"; then
  echo "⚠ Got error response: $RESPONSE"
  exit 1
else
  echo "✓ Image upload successful!"
  echo "Response preview: ${RESPONSE:0:100}..."
fi

# Clean up
rm -f "$TEST_IMAGE"
echo "✓ Test complete"
