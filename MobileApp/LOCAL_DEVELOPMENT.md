# PragatiConnect - Complete Local Development Guide

This guide explains every feature of PragatiConnect and how to configure them for local testing.

---

## 📱 App Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         MOBILE APP (Flutter)                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │  Dashboard  │  │   Schemes   │  │   AI Chat   │  │   Voice     │    │
│  │   Screen    │  │   Screen    │  │   Screen    │  │  Assistant  │    │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘    │
│                                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │   Scheme    │  │  Business   │  │  Settings   │  │   Edit      │    │
│  │  Assistant  │  │   Boost     │  │   Screen    │  │  Profile    │    │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘    │
│                                                                         │
├─────────────────────────────────────────────────────────────────────────┤
│                           SERVICES LAYER                                │
│                                                                         │
│  ┌─────────────────┐     ┌─────────────────┐     ┌──────────────────┐  │
│  │ GeminiService   │     │  ApiService     │     │ VoiceApiService  │  │
│  │ (Fallback AI)   │     │ (Backend API)   │     │ (Voice Backend)  │  │
│  └────────┬────────┘     └────────┬────────┘     └────────┬─────────┘  │
│           │                       │                        │            │
└───────────┼───────────────────────┼────────────────────────┼────────────┘
            │                       │                        │
            ▼                       ▼                        ▼
    ┌───────────────┐      ┌───────────────────────────────────────────┐
    │  Google       │      │          BACKEND (FastAPI)                │
    │  Gemini API   │      │                                           │
    │  (Fallback)   │      │  ┌─────────────┐  ┌──────────┐  ┌──────┐ │
    │               │      │  │ Google TTS  │  │  AWS     │  │ AWS  │ │
    │  gemini-2.0-  │      │  │ (WaveNet    │  │ Bedrock  │  │ DDB  │ │
    │  flash        │      │  │  Female)    │  │ (Nova/   │  │      │ │
    └───────────────┘      │  └─────────────┘  │ Claude)  │  └──────┘ │
                           │                   └──────────┘            │
                           └───────────────────────────────────────────┘
```

---

## 🤖 AI Models & Voice Configuration

### Backend AI Models

The backend uses **AWS Bedrock** for AI responses with automatic model detection:

| Model | Model ID | Usage |
|-------|----------|-------|
| **Amazon Nova Lite** (Default) | `amazon.nova-lite-v1:0` | Fast, cost-effective responses |
| **Claude 3 Sonnet** (Alternative) | `anthropic.claude-3-sonnet-20240229-v1:0` | Higher quality responses |

The `bedrock_service.py` automatically detects which model is configured and formats requests accordingly:
- **Nova models**: Uses `inferenceConfig` with `max_new_tokens`
- **Claude models**: Uses `anthropic_version` with `max_tokens`

### Fallback AI

When backend is unavailable, the app falls back to:
- **Google Gemini** `gemini-2.0-flash` (configured via `GEMINI_API_KEY`)

### Text-to-Speech Voices (ALL FEMALE)

Google Cloud TTS WaveNet voices for natural-sounding speech:

| Language | Voice Code | Gender | Type |
|----------|------------|--------|------|
| English (India) | `en-IN-Wavenet-A` | Female | WaveNet |
| Hindi | `hi-IN-Wavenet-A` | Female | WaveNet |
| Marathi | `mr-IN-Wavenet-A` | Female | WaveNet |
| Tamil | `ta-IN-Wavenet-A` | Female | WaveNet |
| Telugu | `te-IN-Standard-A` | Female | Standard |
| Bengali | `bn-IN-Wavenet-A` | Female | WaveNet |
| Gujarati | `gu-IN-Wavenet-A` | Female | WaveNet |
| Kannada | `kn-IN-Wavenet-A` | Female | WaveNet |
| Malayalam | `ml-IN-Wavenet-A` | Female | WaveNet |
| Punjabi | `pa-IN-Wavenet-A` | Female | WaveNet |

> **Gujarati and Punjabi are now fully supported in both backend and frontend for STT and TTS.**

---

## 🎯 Features and How They Work

### 1. **Dashboard** (`dashboard_screen.dart`)
- **What it does:** Main home screen showing quick access to all features
- **Backend needed:** No (UI only)
- **Configuration:** None required

### 2. **Government Schemes** (`schemes_screen.dart`)
- **What it does:** Lists government welfare schemes for informal workers
- **How it works:** 
  1. Calls `GeminiService.fetchGovernmentSchemes()` 
  2. Gemini generates a JSON list of schemes
  3. User can search/filter and view details
- **Backend needed:** No (uses direct Gemini API)
- **Configuration:** Gemini API key only

### 3. **Scheme Assistant** (`scheme_assistant_screen.dart`)
- **What it does:** Chatbot to help users find eligible schemes
- **How it works:**
  1. User asks questions about schemes
  2. `GeminiService.sendSchemeAssistantMessage()` processes query
  3. AI responds with scheme recommendations
- **Backend needed:** No (uses direct Gemini API)
- **Configuration:** Gemini API key only

### 4. **AI Chat** (`ai_chat_screen.dart`)
- **What it does:** General AI assistant with image/file upload
- **How it works:**
  1. User types message or attaches image/file
  2. `GeminiService.sendAiChatMessage()` sends to Gemini
  3. AI responds (can analyze images)
- **Backend needed:** No (uses direct Gemini API)
- **Configuration:** Gemini API key only

### 5. **Voice Assistant** (`voice_assistant_screen.dart`) ⭐
- **What it does:** Voice-based AI interaction with natural female voices
- **Complete Flow (Backend Mode - Default):**
  ```
  ┌─────────────────────────────────────────────────────────────────────────┐
  │                        VOICE ASSISTANT FLOW                             │
  ├─────────────────────────────────────────────────────────────────────────┤
  │                                                                         │
  │   📱 MOBILE APP                        🖥️ BACKEND                       │
  │   ─────────────                        ─────────                        │
  │                                                                         │
  │   1. User taps sphere                                                   │
  │          │                                                              │
  │          ▼                                                              │
  │   2. speech_to_text package                                             │
  │      (Device STT) captures                                              │
  │      speech → text                                                      │
  │          │                                                              │
  │          ▼                                                              │
  │   3. Text sent via ──────────────────► /api/v1/chat/voice-query         │
  │                                               │                         │
  │                                               ▼                         │
  │                                        4. AWS Bedrock                   │
  │                                           (Nova/Claude)                 │
  │                                           generates response            │
  │                                               │                         │
  │                                               ▼                         │
  │                                        5. Google Cloud TTS              │
  │                                           (Female WaveNet)              │
  │                                           converts to audio             │
  │                                               │                         │
  │   6. Audio (MP3) ◄────────────────────────────┘                         │
  │          │                                                              │
  │          ▼                                                              │
  │   7. Save to temp file                                                  │
  │      with .mp3 extension                                                │
  │      (iOS compatibility)                                                │
  │          │                                                              │
  │          ▼                                                              │
  │   8. audioplayers package                                               │
  │      plays audio                                                        │
  │                                                                         │
  └─────────────────────────────────────────────────────────────────────────┘
  ```

- **Fallback Mode (Local):**
  1. Device STT captures speech → text
  2. Text sent to `GeminiService.getVoiceResponse()`
  3. Response spoken via `flutter_tts` (local TTS with female voice preference)

- **iOS Audio Fix:** Audio saved to temp file with `.mp3` extension for AVPlayer compatibility

### 6. **Business Boost** (`business_boost_screen.dart`)
- **What it does:** Generates business profiles and marketing content
- **How it works:**
  1. User enters business details (name, type, location)
  2. `GeminiService.generateBusinessProfile()` creates content
  3. Displays professional description, tagline, social media bio
- **Backend needed:** No (uses direct Gemini API)
- **Configuration:** Gemini API key only

### 7. **Settings** (`settings_screen.dart`)
- **What it does:** Theme, language, profile management
- **Backend needed:** No (local SharedPreferences)
- **Configuration:** None required

---

## 🖥️ Option 1: Backend Mode (Recommended - Default)

The app defaults to using the backend API for voice and chat features.

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `USE_BACKEND_API` | `true` (if unset) | Use backend for chat/voice |
| `API_BASE_URL` | `http://localhost:8000/api/v1` | Backend server URL |
| `GEMINI_API_KEY` | Required | Fallback when backend unavailable |

### URL Auto-Conversion

The `environment.dart` automatically handles localhost issues:
- **iOS Simulator:** `localhost` → `127.0.0.1`
- **Android Emulator:** `localhost` → `10.0.2.2`
- **Physical Device:** Use your Mac's actual IP address

### Step 1: AWS Setup

#### 1.1 Create IAM User
1. Go to **IAM** → **Users** → **Create User**
2. Name: `pragati-backend`
3. Attach policies:
   - `AmazonDynamoDBFullAccess`
   - `AmazonS3FullAccess`
   - `AmazonBedrockFullAccess`
4. Create access key for "Application running outside AWS"

#### 1.2 Enable Bedrock Model Access
1. Go to **Amazon Bedrock** → **Model access**
2. Enable one of:
   - **Amazon** → **Nova Lite** (recommended, faster)
   - **Anthropic** → **Claude 3 Sonnet** (higher quality)
3. Wait for "Access granted"

#### 1.3 Create DynamoDB Tables
```bash
# Users table
aws dynamodb create-table \
    --table-name pragati-users \
    --attribute-definitions AttributeName=phone_number,AttributeType=S \
    --key-schema AttributeName=phone_number,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region ap-south-1

# Conversations table
aws dynamodb create-table \
    --table-name pragati-conversations \
    --attribute-definitions \
        AttributeName=user_phone,AttributeType=S \
        AttributeName=conversation_id,AttributeType=S \
    --key-schema \
        AttributeName=user_phone,KeyType=HASH \
        AttributeName=conversation_id,KeyType=RANGE \
    --billing-mode PAY_PER_REQUEST \
    --region ap-south-1
```

### Step 2: Google Cloud Setup (for TTS)

1. Create project at [console.cloud.google.com](https://console.cloud.google.com)
2. Enable **Cloud Text-to-Speech API**
3. Create service account with **Cloud Speech Client** role
4. Download JSON key file

### Step 3: Configure Backend

```bash
cd /Users/shreeyansvichare/Code/PragatiConnect/MobileApp/backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
```

Edit `backend/.env`:
```env
# AWS Configuration
AWS_REGION=ap-south-1
AWS_ACCESS_KEY_ID=AKIAXXXXXXXXXXXXXXXXXX
AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# DynamoDB Tables
DYNAMODB_TABLE_USERS=pragati-users
DYNAMODB_TABLE_CONVERSATIONS=pragati-conversations
DYNAMODB_TABLE_ESTIMATES=pragati-estimates

# Amazon Bedrock - Choose ONE:
# Option 1: Nova (faster, cost-effective)
BEDROCK_MODEL_ID=amazon.nova-lite-v1:0
# Option 2: Claude (higher quality)
# BEDROCK_MODEL_ID=anthropic.claude-3-sonnet-20240229-v1:0

# Google Cloud (for TTS)
GOOGLE_CLOUD_CREDENTIALS_PATH=/path/to/service-account.json
GOOGLE_CLOUD_PROJECT_ID=your-project-id

# Fallback AI (when Bedrock unavailable)
GEMINI_API_KEY=AIzaSy_YOUR_KEY_HERE

# JWT Secret
JWT_SECRET=your-super-secret-random-string-at-least-32-chars

# OTP (for testing)
OTP_MOCK_MODE=true
OTP_MOCK_CODE=123456

# App Config
DEBUG=true
CORS_ORIGINS=http://localhost:3000,http://localhost:8080
```

### Step 4: Run Backend

```bash
cd /Users/shreeyansvichare/Code/PragatiConnect/MobileApp/backend
source .venv/bin/activate
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Test: Open http://localhost:8000/docs

### Step 5: Configure Mobile App

Edit `MobileApp/.env`:
```env
# Gemini API Key (fallback)
GEMINI_API_KEY=AIzaSy_YOUR_KEY_HERE

# Backend API (defaults to true if not set)
USE_BACKEND_API=true
API_BASE_URL=http://localhost:8000/api/v1

# For physical device, use your Mac's IP:
# API_BASE_URL=http://192.168.1.XXX:8000/api/v1
```

### Step 6: Run App

```bash
cd /Users/shreeyansvichare/Code/PragatiConnect/MobileApp
flutter run -d "iPhone 17 Pro"
```

---

## 🖥️ Option 2: Local Testing (Fallback - No Backend)

For quick testing without backend infrastructure.

### Step 1: Get a Gemini API Key

1. Go to [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Click **"Create API Key"**
3. Copy the key (starts with `AIza...`)

### Step 2: Configure the Flutter App

```bash
cd /Users/shreeyansvichare/Code/PragatiConnect/MobileApp
cp .env.example .env
```

Edit `.env`:
```env
# Your Gemini API Key
GEMINI_API_KEY=AIzaSy_YOUR_ACTUAL_KEY_HERE

# Disable backend API
USE_BACKEND_API=false

# Not needed in local mode
API_BASE_URL=http://localhost:8000/api/v1
```

### Step 3: Run the App

```bash
flutter run -d "iPhone 17 Pro"
```

### What Works in Local Mode:
| Feature | Works? | Notes |
|---------|--------|-------|
| Dashboard | ✅ | UI only |
| Government Schemes | ✅ | Fetches from Gemini |
| Scheme Assistant | ✅ | Chat with Gemini |
| AI Chat | ✅ | Including image analysis |
| Voice Assistant | ⚠️ | Uses device STT/TTS (less natural voices) |
| Business Boost | ✅ | Profile generation via Gemini |
| Settings | ✅ | Local storage |

---

## 🧪 Testing Features

### Test 1: Voice Assistant (Backend Mode)
1. Ensure backend is running
2. Tap **Voice Assistant** in drawer
3. Tap the sphere to start listening
4. Say: "मुझे PM किसान योजना के बारे में बताइए"
5. Wait for:
   - 🎤 Transcription (device STT)
   - 🧠 AI processing (Bedrock Nova/Claude)
   - 🔊 Female voice response (Google TTS WaveNet)

### Test 2: Voice Synthesis API
```bash
# Register and get token
curl -s -X POST "http://127.0.0.1:8000/api/v1/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"phone_number": "+919999888877"}'

TOKEN=$(curl -s -X POST "http://127.0.0.1:8000/api/v1/auth/verify-otp" \
  -H "Content-Type: application/json" \
  -d '{"phone_number": "+919999888877", "otp": "123456"}' \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

# Test Marathi TTS (female voice)
curl -s -X POST "http://127.0.0.1:8000/api/v1/voice/synthesize" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"text": "नमस्कार, तुम्ही कसे आहात?", "language": "mr"}'
```

### Test 3: AI Chat with Image
1. Tap **AI Chat** in drawer
2. Tap attachment icon → Select image
3. Ask: "What is this?"
4. AI analyzes the image

### Test 4: Change Language
1. Tap **Settings** in drawer
2. Change language to Hindi/Marathi/Tamil
3. Voice Assistant will use appropriate female WaveNet voice

---

## 💰 Cost Summary

### Backend Mode (Recommended)
| Service | Cost | Free Tier |
|---------|------|-----------|
| AWS Bedrock (Nova Lite) | ~$0.0002/1K input tokens | None |
| AWS Bedrock (Claude 3 Sonnet) | ~$0.003/1K input tokens | None |
| Google Cloud TTS (WaveNet) | ~$16/1M chars | First 1M chars/month free |
| DynamoDB | Pay-per-request | 25 GB free |
| **Estimated Total** | ~**$5-15/month** | For light development |

### Local Mode (Fallback)
| Service | Cost | Notes |
|---------|------|-------|
| Google Gemini | Free | 60 requests/minute |
| Device STT/TTS | Free | Built-in, less natural |
| **Total** | **$0** | Limited voice quality |

---

## 🐛 Troubleshooting

### Voice Assistant Issues

#### "Audio not playing on iOS"
- **Fixed:** Audio is now saved to temp file with `.mp3` extension
- Verify `audioplayers` package is up to date in `pubspec.yaml`

#### "Voice sounds robotic/male"
- Ensure backend TTS is being used (check `USE_BACKEND_API=true`)
- Backend uses Google WaveNet female voices for natural speech
- Local fallback uses device TTS which is less natural

#### "Speech recognition fails for regional languages"
- Some languages (Tamil, Telugu, Bengali) may have limited device STT support
- The app now has expanded error handling with automatic restart
- Try speaking clearly and slowly
- Falls back to Hindi/English if language unavailable on device

### Backend Issues

#### "Bedrock model access denied"
- Ensure model access is granted in AWS Bedrock console
- Check `BEDROCK_MODEL_ID` matches an enabled model:
  - Nova: `amazon.nova-lite-v1:0`
  - Claude: `anthropic.claude-3-sonnet-20240229-v1:0`

#### "TTS returns empty audio"
- Check `GOOGLE_APPLICATION_CREDENTIALS` is set
- Verify Cloud Text-to-Speech API is enabled
- Check service account has proper permissions

### Connection Issues

#### "Backend connection failed"
- Verify backend is running: `curl http://localhost:8000/health`
- For iOS: App auto-converts `localhost` to `127.0.0.1`
- For Android: App auto-converts `localhost` to `10.0.2.2`
- For physical device: Use actual Mac IP in `.env`

---

## 📂 Key Files Reference

```
MobileApp/
├── .env                           # App configuration
├── lib/
│   ├── config/
│   │   └── environment.dart       # Env loader (auto localhost conversion)
│   ├── services/
│   │   ├── gemini_service.dart    # Direct Gemini API (fallback)
│   │   ├── api_service.dart       # Backend API calls
│   │   └── voice_api_service.dart # Voice backend calls
│   └── screens/
│       └── voice_assistant_screen.dart  # Voice UI + audio playback
│
└── backend/
    ├── .env                       # Backend configuration
    └── app/
        ├── config.py              # Settings (BEDROCK_MODEL_ID, etc.)
        └── services/
            ├── bedrock_service.py # AWS Bedrock (Nova + Claude support)
            └── speech_service.py  # Google TTS (Female WaveNet voices)
```

---

## ✅ Quick Start Checklist

### For Backend Mode (Recommended):
- [ ] Set up AWS account + IAM user with Bedrock access
- [ ] Enable Bedrock model (Nova Lite or Claude 3 Sonnet)
- [ ] Create DynamoDB tables
- [ ] Set up Google Cloud project + enable TTS API
- [ ] Configure `backend/.env` with credentials
- [ ] Run `uvicorn app.main:app --reload --port 8000`
- [ ] Create `MobileApp/.env` with `GEMINI_API_KEY` (fallback)
- [ ] Run `flutter run`
- [ ] Test voice assistant with female TTS voice!

### For Local Mode (Quick Testing):
- [ ] Get Gemini API key from [aistudio.google.com](https://aistudio.google.com/app/apikey)
- [ ] Create `MobileApp/.env` with `GEMINI_API_KEY=your_key`
- [ ] Set `USE_BACKEND_API=false`
- [ ] Run `flutter run`
- [ ] Note: Voice uses device TTS (less natural)
