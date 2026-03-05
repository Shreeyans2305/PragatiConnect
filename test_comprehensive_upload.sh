#!/bin/bash

# Comprehensive test for image upload fixes
echo "=== Testing Image Upload Fixes ==="

# Create test images with different extensions
echo "Creating test images..."
python3 << 'EOF'
from PIL import Image
import os

# Create test images
extensions = ['png', 'jpg', 'gif', 'webp', 'heic']
for ext in extensions:
    img = Image.new('RGB', (100, 100), color='blue')
    filepath = f'/tmp/test_image.{ext}'
    if ext == 'webp':
        img.save(filepath, 'WEBP')
    elif ext == 'heic':
        img.save(filepath, 'JPEG')  # Save as JPEG since HEIC requires pillow-heif
    else:
        img.save(filepath, ext.upper())
    size = os.path.getsize(filepath)
    print(f"Created: {filepath} ({size} bytes)")
EOF

# Register and get token
echo ""
echo "Getting authentication token..."
curl -s -X POST "http://127.0.0.1:8000/api/v1/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"email": "test_upload@example.com"}' > /dev/null 2>&1

TOKEN=$(curl -s -X POST "http://127.0.0.1:8000/api/v1/auth/verify-otp" \
  -H "Content-Type: application/json" \
  -d '{"email": "test_upload@example.com", "otp": "123456"}' | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('access_token', ''))" 2>/dev/null)

if [ -z "$TOKEN" ]; then
  echo "✗ Failed to get authentication token"
  exit 1
fi

echo "✓ Token obtained"
echo ""

# Test different formats
echo "Testing image uploads with different formats:"
for ext in png jpg gif webp heic; do
  TEST_IMAGE="/tmp/test_image.$ext"
  echo -n "  Testing .$ext format... "
  
  RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "http://127.0.0.1:8000/api/v1/price/estimate" \
    -H "Authorization: Bearer $TOKEN" \
    -F "image=@$TEST_IMAGE" \
    -F "language=en" 2>/dev/null)
  
  HTTP_CODE=$(echo "$RESPONSE" | tail -1)
  BODY=$(echo "$RESPONSE" | head -n -1)
  
  if [ "$HTTP_CODE" == "200" ]; then
    echo "✓ Success (HTTP $HTTP_CODE)"
  elif echo "$BODY" | grep -q "Invalid file type"; then
    echo "✗ Rejected (Invalid file type)"
    echo "    Response: $(echo "$BODY" | head -c 100)..."
  else
    echo "⚠ HTTP $HTTP_CODE"
    echo "    Response: $(echo "$BODY" | head -c 100)..."
  fi
  
  rm -f "$TEST_IMAGE"
done

echo ""
echo "✓ Test complete"
