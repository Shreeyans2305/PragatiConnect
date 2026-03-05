# Email Authentication Setup Guide

## Overview

This guide explains how to set up email-based authentication for PragatiConnect using Gmail SMTP. Users can now sign in with their email address, and their data persists across sessions.

## What Changed

- **Authentication**: Changed from phone OTP to **email-based OTP**
- **User Identifier**: Changed from phone number to **email address**
- **Data Persistence**: User data is now tied to email (not lost when switching devices)
- **Email Delivery**: Uses Gmail SMTP to send OTP codes

## Gmail Credentials You Need

To set up email authentication, you need to provide Gmail credentials. Here's what you need:

### 1. Gmail Account
You need a Gmail account (e.g., `pragaticonnect@gmail.com`).

### 2. App Password (Required!)
Gmail accounts with 2-factor authentication enabled require an **App Password** instead of your regular password. This is a special 16-character password.

## Step-by-Step Setup

### Step 1: Enable 2-Factor Authentication on Gmail

1. Go to [Google Account Security](https://myaccount.google.com/security)
2. Click **2-Step Verification** in the left sidebar
3. Follow the setup process (you'll need to verify with your phone)

### Step 2: Create an App Password

1. Go to [Google Account App Passwords](https://myaccount.google.com/apppasswords)
   - (If you don't see this option, it means 2FA isn't enabled - go back to Step 1)
2. Under **Select the app and device type**:
   - **App**: Select **Mail**
   - **Device**: Select **Windows PC** (or your OS)
3. Click **Generate**
4. Google will show you a **16-character password** like: `abcd efgh ijkl mnop`
5. **Copy this password** (you'll need it for .env)

### Step 3: Update Your Backend Configuration

Edit `.env` file in `/backend/` and add:

```env
# Email Configuration (Gmail SMTP)
GMAIL_ADDRESS=pragaticonnect@gmail.com
GMAIL_APP_PASSWORD=abcdefghijklmnop
EMAIL_MOCK_MODE=false
```

Replace:
- `pragaticonnect@gmail.com` with your actual Gmail address
- `abcdefghijklmnop` with the 16-character app password from Step 2

### Step 4: (Optional) Enable Mock Mode for Testing

If you want to test without actually sending emails, set:

```env
EMAIL_MOCK_MODE=true
```

In mock mode, OTP codes are printed to console instead of sent via email.

### Step 5: Update DynamoDB User Table

Since we switched from phone to email, you may need to recreate your DynamoDB `pragati-users` table with email as the primary key. Current users might not be accessible.

**Option A: Fresh Start** (Recommended for development)
- Delete the old `pragati-users` table
- Redeploy (a new table will be created automatically)

**Option B: Migrate Data**
- Export existing users from DynamoDB
- Change `phone_number` field to `email` field
- Re-import

## Authentication Flow

### Registration
```
1. User enters: pragaticonnect@example.com
2. Backend generates 6-digit OTP: 123456
3. Backend sends email via Gmail SMTP with OTP
4. Email arrives in user's inbox within seconds
5. User enters OTP in app
6. Backend verifies OTP and creates user account
7. Returns JWT tokens
8. User data persists under email
```

### Sign In (Next Time)
```
1. User enters same email: pragaticonnect@example.com
2. Backend sends new OTP via email
3. User enters OTP
4. Backend loads existing user data (profile, trades, location, etc.)
5. Returns JWT tokens
6. All previous data is still there!
```

## API Endpoints

### Register
```bash
POST /api/v1/auth/register
Content-Type: application/json

{
  "email": "user@example.com"
}

Response (if EMAIL_MOCK_MODE=false):
{
  "message": "OTP sent successfully to your email",
  "email": "user@example.com"
}
```

### Verify OTP
```bash
POST /api/v1/auth/verify-otp
Content-Type: application/json

{
  "email": "user@example.com",
  "otp": "123456"
}

Response:
{
  "access_token": "eyJhbGc...",
  "refresh_token": "eyJhbGc...",
  "expires_in": 86400
}
```

## Testing

### Test with Mock Mode (No Real Email)
```env
EMAIL_MOCK_MODE=true
OTP_MOCK_MODE=true
OTP_MOCK_CODE=123456
```

Then test:
```bash
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com"}'

# Response will include OTP for testing
```

### Test with Real Email
```env
EMAIL_MOCK_MODE=false
GMAIL_ADDRESS=your-email@gmail.com
GMAIL_APP_PASSWORD=your-16-char-password
```

## Troubleshooting

### Error: "SMTP Authentication failed"
- ✅ Check that 2-factor authentication is enabled on Gmail account
- ✅ Verify you're using App Password, not regular password
- ✅ Make sure GMAIL_ADDRESS and GMAIL_APP_PASSWORD are correct in .env

### Email Not Arriving
- ✅ Check spam/junk folder
- ✅ Check that EMAIL_MOCK_MODE=false
- ✅ Check backend logs for error messages
- ✅ Verify GMAIL_APP_PASSWORD has no extra spaces

### "EmailStr" Import Error
- Run: `pip install email-validator`

## Security Best Practices

1. **Never commit credentials** to Git
   - Keep `GMAIL_APP_PASSWORD` only in `.env`
   - Add `.env` to `.gitignore`

2. **Use App Passwords, not regular password**
   - More secure than storing your actual Gmail password

3. **Set EMAIL_MOCK_MODE=false in production**
   - Only use mock mode for development

4. **Use a dedicated Gmail account**
   - Create `pragaticonnect@gmail.com` or similar
   - Don't use your personal Gmail account

5. **Rotate App Passwords periodically**
   - Delete and regenerate in Google Account settings

## Email Template

The email sent to users includes:
- Clean HTML formatting
- Clear OTP display (large, monospace font)
- Expiration time (5 minutes)
- Security notice about not sharing code
- PragatiConnect branding

## Next Steps

1. Set up Gmail account with 2FA
2. Generate App Password
3. Update `.env` with credentials
4. Restart backend
5. Test registration with your email
6. Update Flutter app to use email instead of phone (if needed)

## Support

If you encounter issues:
1. Check backend logs: `tail -f backend.log`
2. Verify .env credentials are correct
3. Test Gmail SMTP connectivity:
   ```bash
   python3 -c "
   import smtplib
   try:
       server = smtplib.SMTP('smtp.gmail.com', 587)
       server.starttls()
       server.login('your-email@gmail.com', 'your-app-password')
       print('✅ Gmail authentication successful!')
   except Exception as e:
       print(f'❌ Error: {e}')
   "
   ```

## Backend Code Changes

The following files were updated:
- `app/services/email_service.py` - New email service using SMTP
- `app/models/user.py` - Changed phone_number to email
- `app/routers/auth.py` - Updated to use email authentication
- `app/config.py` - Added Gmail configuration options
- `.env` - Added Gmail credentials fields
