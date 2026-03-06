import requests

BASE_URL = "http://localhost:8001/api/v1"

def test_price():
    # Registration handling
    test_email = "test.price.8001@example.com"
    requests.post(f"{BASE_URL}/auth/register", json={"email": test_email})
    res = requests.post(f"{BASE_URL}/auth/verify-otp", json={"email": test_email, "otp": "123456"})
    token = res.json().get("access_token") if res.status_code == 200 else None
    
    if not token:
        print("Failed to get token.")
        return

    # Create dummy image
    dummy_image = b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x01\x00\x00\x05\x00\x01\x0d\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82"

    files = {"image": ("test.png", dummy_image, "image/png")}
    data = {"language": "en"}
    headers = {"Authorization": f"Bearer {token}"}

    res = requests.post(f"{BASE_URL}/price/estimate", files=files, data=data, headers=headers)
    print("Status:", res.status_code)

if __name__ == "__main__":
    test_price()
