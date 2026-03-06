import requests
import sys

BASE_URL = "http://localhost:8000/api/v1"

def test_voice():
    print("1. Registering new user...")
    test_email = "test.voice.mr@example.com"
    res = requests.post(f"{BASE_URL}/auth/register", json={"email": test_email})
    if res.status_code != 200:
        print(f"Failed to register: {res.text}")
        return
        
    print("2. Verifying OTP (mock mode)...")
    res = requests.post(f"{BASE_URL}/auth/verify-otp", json={
        "email": test_email,
        "otp": "123456"
    })
    if res.status_code != 200:
        print(f"Failed to verify OTP: {res.text}")
        return
        
    token = res.json().get("access_token")
    if not token:
        print("No access token received.")
        return
        
    print("3. Testing /chat/voice-query with language 'mr' (Marathi)...")
    headers = {"Authorization": f"Bearer {token}"}
    payload = {
        "transcript": "Hello, how can you help me today?",
        "language": "mr",
        "conversation_id": None
    }
    
    res = requests.post(f"{BASE_URL}/chat/voice-query", json=payload, headers=headers)
    if res.status_code != 200:
        print(f"Failed to query voice API: {res.text}")
        return
        
    data = res.json()
    print("Response Status Code:", res.status_code)
    print("Response Language Returned:", data.get("language"))
    print("Response Text:", data.get("response"))

if __name__ == "__main__":
    test_voice()
