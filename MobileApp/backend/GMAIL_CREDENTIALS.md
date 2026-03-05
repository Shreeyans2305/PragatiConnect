# Gmail App Password Quick Reference

## What You Need (Copy-Paste Ready)

### 1. Your Gmail Address
```
GMAIL_ADDRESS=your-email@gmail.com
```

### 2. Your App Password (16 characters)
```
GMAIL_APP_PASSWORD=xxxx xxxx xxxx xxxx
```

## How to Get Your App Password (3 Steps)

### Step 1: Enable 2-Factor Authentication
- Go to: https://myaccount.google.com/security
- Find: **2-Step Verification**
- Click: **Get Started** or **Manage**
- Verify with your phone

### Step 2: Create App Password
- Go to: https://myaccount.google.com/apppasswords
- Select: **Mail** (dropdown)
- Select: **Windows PC** (or your device)
- Click: **Generate**
- **Copy the password shown** (it's 16 characters with spaces)

Example of what you'll see:
```
xyza bcde fghi jklm
```

### Step 3: Paste into .env
Edit: `/backend/.env`

```env
GMAIL_ADDRESS=your-email@gmail.com
GMAIL_APP_PASSWORD=xyza bcde fghi jklm
EMAIL_MOCK_MODE=false
```

## Format Examples

✅ **Correct Format**
```
GMAIL_ADDRESS=pragaticonnect@gmail.com
GMAIL_APP_PASSWORD=abcd efgh ijkl mnop
```

❌ **Wrong Format**
```
GMAIL_ADDRESS=pragaticonnect@GMAIL.COM  (lowercase required)
GMAIL_APP_PASSWORD=abcdefghijklmnop     (missing spaces)
GMAIL_APP_PASSWORD=your-password        (regular password, not app password)
```

## Verification

To test if credentials work:

```bash
python3 << 'EOF'
import smtplib

email = "your-email@gmail.com"
password = "xxxx xxxx xxxx xxxx"

try:
    server = smtplib.SMTP('smtp.gmail.com', 587)
    server.starttls()
    server.login(email, password)
    server.quit()
    print("✅ SUCCESS! Credentials are correct.")
except smtplib.SMTPAuthenticationError:
    print("❌ FAILED! Check your credentials.")
except Exception as e:
    print(f"❌ ERROR: {e}")
EOF
```

## Important Notes

⚠️ **DON'T**
- Use your regular Gmail password
- Share this password with anyone
- Commit .env to Git
- Use a personal Gmail account in production

✅ **DO**
- Use the 16-character App Password only
- Keep credentials in .env file
- Add .env to .gitignore
- Use a dedicated Gmail account (e.g., pragaticonnect@gmail.com)

## Where to Put It

File: `/Users/shreeyansvichare/Code/PragatiConnect/MobileApp/backend/.env`

```env
# ... existing config ...

# Email Configuration (Gmail SMTP)
GMAIL_ADDRESS=your-email@gmail.com
GMAIL_APP_PASSWORD=abcd efgh ijkl mnop
EMAIL_MOCK_MODE=false

# ... rest of config ...
```

## Test It

```bash
# Terminal 1: Restart backend
cd backend && python -m uvicorn app.main:app --port 8000

# Terminal 2: Test registration
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com"}'

# Check your email for OTP!
```

## Troubleshooting

**Email not arriving?**
1. Check spam folder
2. Verify GMAIL_APP_PASSWORD has no extra spaces
3. Verify 2FA is enabled
4. Check backend logs

**"Authentication failed" error?**
1. Make sure you're using App Password (not regular password)
2. Make sure 2FA is enabled
3. Regenerate the App Password and try again

**Need to regenerate?**
- Go to https://myaccount.google.com/apppasswords
- Delete the old password
- Create a new one
- Update .env with new password

---

**That's it!** Once you add these to .env, email authentication will work. 🎉
