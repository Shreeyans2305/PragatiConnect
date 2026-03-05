# Email Authentication Setup Checklist

## Quick Start (5 minutes)

Follow these steps to enable email authentication:

### Step 1: Set Up Gmail Account ✓

- [ ] Go to https://myaccount.google.com/security
- [ ] Enable **2-Step Verification** (required for App Passwords)
  - Follow the verification process with your phone
- [ ] Go to https://myaccount.google.com/apppasswords
- [ ] Create an **App Password** for Mail:
  - Select: **Mail** and **Windows PC** (or your OS)
  - Click **Generate**
  - **Copy the 16-character password** (e.g., `abcd efgh ijkl mnop`)

### Step 2: Update Backend .env ✓

Edit `/backend/.env`:

```env
# Email Configuration (Gmail SMTP)
GMAIL_ADDRESS=your-email@gmail.com
GMAIL_APP_PASSWORD=abcdefghijklmnop
EMAIL_MOCK_MODE=false
```

Replace:
- `your-email@gmail.com` - Your actual Gmail address
- `abcdefghijklmnop` - The 16-character app password from Step 1

### Step 3: Install Dependencies ✓

```bash
cd backend
pip install email-validator
```

### Step 4: Restart Backend ✓

```bash
# Kill old process
lsof -ti:8000 | xargs kill -9

# Start fresh
cd backend && \
PYTHONPATH=..:$PYTHONPATH \
GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/google-credentials.json" \
/Users/shreeyansvichare/miniforge3/bin/python -m uvicorn backend.app.main:app --port 8000
```

### Step 5: Test ✓

```bash
bash test-email-auth.sh
```

## Detailed Setup

### Why Email Instead of Phone?

| Aspect | Phone OTP | Email OTP |
|--------|-----------|-----------|
| Device Independence | ❌ Tied to SIM | ✅ Works on any device |
| Data Persistence | ❌ Lost on device switch | ✅ Accessible anywhere |
| Cost | ❌ SMS gateway fees | ✅ Free with Gmail |
| User Experience | ⚠️ Need mobile number | ✅ Most people have email |
| Spam Risk | ⚠️ SMS spam | ✅ Email has spam filters |

### What Credentials Do You Need?

You need **one** set of Gmail credentials:

```
Email Address:    your-email@gmail.com
App Password:     abcd efgh ijkl mnop  (16 characters)
SMTP Server:      smtp.gmail.com (automatic)
SMTP Port:        587 (automatic)
Protocol:         TLS (automatic)
```

That's it! The SMTP server, port, and protocol are hardcoded.

### Important Security Notes

⚠️ **DO NOT USE YOUR PERSONAL PASSWORD**
- Always use the **App Password** (16-char code)
- Never use your regular Gmail password
- App Passwords are less dangerous if leaked

⚠️ **NEVER COMMIT .env TO GIT**
- Add to `.gitignore`
- Keep credentials local only
- Use environment variables in production

### How Users Register

#### First Time
```
User: "Sign me up with email"
     ↓
User enters: "alice@example.com"
     ↓
Backend generates OTP: "543210"
     ↓
Email sent to alice@example.com with OTP
     ↓
User checks email, sees OTP
     ↓
User enters OTP in app: "543210"
     ↓
Backend verifies and creates account
     ↓
User logged in! ✅
```

#### Second Time (Same Email)
```
User: "Sign me in with email"
     ↓
User enters: "alice@example.com"
     ↓
Backend generates NEW OTP: "789012"
     ↓
Email sent to alice@example.com with new OTP
     ↓
User checks email, enters OTP: "789012"
     ↓
Backend loads existing user account
     ↓
User logged in! Data is still there! ✅
```

## Testing Guide

### Option 1: Test with Mock Mode (No Real Email)

Edit `.env`:
```env
EMAIL_MOCK_MODE=true
OTP_MOCK_MODE=true
OTP_MOCK_CODE=123456
```

Test:
```bash
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com"}'

# Response includes: "otp": "123456"
```

### Option 2: Test with Real Email

Edit `.env`:
```env
EMAIL_MOCK_MODE=false
GMAIL_ADDRESS=your-email@gmail.com
GMAIL_APP_PASSWORD=your-16-char-password
```

Test:
```bash
# Register
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "user123@gmail.com"}'

# Check user's email for OTP

# Verify OTP
curl -X POST http://localhost:8000/api/v1/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{"email": "user123@gmail.com", "otp": "123456"}'
```

### Option 3: Run Full Test Script

```bash
bash test-email-auth.sh
```

## Troubleshooting

### ❌ "SMTP Authentication failed"

**Problem**: The Gmail credentials are wrong or 2FA isn't enabled.

**Solution**:
1. Verify 2-factor authentication is enabled: https://myaccount.google.com/security
2. Re-generate App Password: https://myaccount.google.com/apppasswords
3. Make sure you're using App Password, not regular password
4. Double-check for extra spaces in .env

### ❌ "Module 'email_validator' not found"

**Problem**: email-validator package not installed.

**Solution**:
```bash
pip install email-validator
```

### ❌ Emails not arriving

**Problem**: EMAIL_MOCK_MODE is true or SMTP error.

**Solution**:
1. Set `EMAIL_MOCK_MODE=false` in .env
2. Check backend logs: grep -i "error\|failed" backend.log
3. Check spam/junk folder
4. Test SMTP connection manually:
   ```bash
   python3 << 'EOF'
   import smtplib
   try:
       server = smtplib.SMTP('smtp.gmail.com', 587, timeout=10)
       server.starttls()
       server.login('your-email@gmail.com', 'your-app-password')
       server.quit()
       print('✅ Gmail connection successful!')
   except Exception as e:
       print(f'❌ Error: {e}')
   EOF
   ```

### ❌ "Invalid email format"

**Problem**: Email validation failed.

**Solution**:
- Use valid email: `user@example.com`
- Don't use: `user@localhost`, `test@test`, etc.
- Make sure no spaces in email

## Backend Files Changed

These files were modified to support email authentication:

```
backend/
├── app/
│   ├── services/
│   │   └── email_service.py       ← NEW: Email via SMTP
│   ├── models/
│   │   └── user.py                ← CHANGED: email instead of phone
│   ├── routers/
│   │   └── auth.py                ← CHANGED: email authentication
│   └── config.py                  ← CHANGED: added Gmail config
├── .env                           ← CHANGED: added Gmail fields
├── EMAIL_AUTH_SETUP.md            ← NEW: Full setup guide
└── test-email-auth.sh             ← NEW: Test script
```

## Environment Variables Reference

```env
# Email Configuration
GMAIL_ADDRESS=your-email@gmail.com
  └─ Your Gmail address

GMAIL_APP_PASSWORD=abcdefghijklmnop
  └─ 16-character app password (NOT regular password)

EMAIL_MOCK_MODE=false
  └─ false: Send real emails via Gmail
  └─ true: Print OTP to console (testing only)

# Related settings
OTP_MOCK_MODE=true
  └─ true: Generate fixed OTP (123456)
  └─ false: Generate random 6-digit OTP

OTP_MOCK_CODE=123456
  └─ OTP code to use in mock mode
```

## Security Checklist

Before deploying to production:

- [ ] Gmail account uses 2-factor authentication
- [ ] Using App Password (16-char), not regular password
- [ ] `.env` is in `.gitignore` (not committed to Git)
- [ ] EMAIL_MOCK_MODE=false in production
- [ ] Regularly rotate App Passwords (monthly recommended)
- [ ] Use a dedicated Gmail account (not personal)
- [ ] Monitor backend logs for failed authentication attempts
- [ ] Back up DynamoDB users table before switching auth methods
- [ ] Test OTP expiration (5 minutes)
- [ ] Test rate limiting on repeated registration attempts

## Production Deployment

### Environment Setup

Use environment variables instead of .env:

```bash
export GMAIL_ADDRESS="pragaticonnect@gmail.com"
export GMAIL_APP_PASSWORD="your-app-password"
export EMAIL_MOCK_MODE="false"
```

### Monitoring

Monitor for:
- Failed email sends
- High OTP request rates (potential attack)
- Authentication failures
- Email bounces

### Backup & Migration

From phone OTP to email OTP requires:
1. Delete existing `pragati-users` table (or migrate data)
2. Redeploy backend
3. Users register with new email-based system
4. Old user data won't be accessible (migration needed if important)

## Next Steps

1. ✅ Get Gmail App Password
2. ✅ Update `.env`
3. ✅ Install `email-validator`
4. ✅ Restart backend
5. ✅ Test with `test-email-auth.sh`
6. ✅ Update Flutter app to use email instead of phone
7. ✅ Deploy to production

## Support

If you need help:
1. Check the logs: `tail -f /tmp/backend.log`
2. Review the error message in EMAIL_AUTH_SETUP.md troubleshooting section
3. Verify all environment variables are set correctly
4. Test Gmail SMTP connectivity independently

---

**Email authentication is now ready!** 🎉
