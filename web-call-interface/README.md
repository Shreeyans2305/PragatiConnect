# Pragati Web Call Interface

React-based web voice calling UI that uses the same backend voice endpoint as the mobile assistant.

## Features

- iPhone-style simulator shell UI
- Start/End call flow
- Hold-to-talk microphone input
- Sends audio to `/api/v1/voice/query-base64`
- Plays assistant voice audio from backend response
- Conversation bubbles with transcript + AI response
- Language selector for the same voice languages as mobile/backend
- Automatic authentication (no manual token paste)

## Setup

1. Install dependencies:

```bash
npm install
```

2. Start dev server:

```bash
npm run dev
```

3. Open `http://localhost:3000`

## Backend requirements

- Backend running (default `https://svp4ns3exj.execute-api.us-east-1.amazonaws.com/api/v1`)
- Auto-auth via `/auth/register` + `/auth/verify-otp`
- CORS should allow `http://localhost:3000`

## Optional env override

Create `.env`:

```bash
VITE_API_BASE_URL=https://svp4ns3exj.execute-api.us-east-1.amazonaws.com/api/v1
# Optional: prefill auth email in UI (otherwise user enters it)
# VITE_AUTO_AUTH_EMAIL=you@example.com
# Optional for mock OTP environments only
# VITE_AUTO_AUTH_OTP=123456
# Optional: if you already have a static token, this will be used directly
# VITE_ACCESS_TOKEN=eyJhbGciOi...
```

If OTP mock mode is disabled on backend, the app will send OTP to email and show an OTP field for one-time sign-in.
