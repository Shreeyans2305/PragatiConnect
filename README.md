# Pragati Connect

> Unified AI assistant for India’s informal workforce, focused on practical access through mobile and voice-first interfaces.

Pragati Connect helps workers (artisans, daily wage workers, domestic workers, small service providers) with:
- fair pricing support,
- voice-based assistance,
- government scheme discovery,
- and business enablement tools.

---

## ✅ Current Product Status (What is Working Now)

This repository currently ships **two active user-facing products**:

1. **Mobile App (Flutter, iOS + Android)** — production-style feature set
2. **On-Call Interface (Web prototype)** — browser-based voice call experience, designed as a toll-free-call prototype

---

## 📱 Mobile App (Flutter)

Location: [MobileApp](MobileApp)

### Implemented features

- **User onboarding + authentication** (OTP-backed API flow)
- **Dashboard + profile management**
- **AI Chat assistant**
- **Voice Assistant**
  - speech input
  - AI response generation
  - spoken response playback
- **Government Schemes module**
  - list/search/filter schemes
  - scheme details view
  - **official links open externally**
- **Price Estimator**
  - image upload
  - AI-driven estimate response
  - estimate history
- **Business Boost tools**
  - AI-generated business support content
- **Multilingual experience** for major Indian languages

### Mobile tech stack

- Flutter + Dart
- Provider for state management
- Backend APIs (FastAPI)
- AI via Amazon Bedrock (Nova/Claude model configuration)
- Speech pipeline integrated via backend + device/client flow

### Run mobile app locally

```bash
cd MobileApp
flutter pub get
flutter run
```

Build Android APK:

```bash
cd MobileApp
flutter build apk
```

Generated file:
- [MobileApp/build/app/outputs/flutter-apk/app-release.apk](MobileApp/build/app/outputs/flutter-apk/app-release.apk)

---

## 📞 On-Call Interface (Web Prototype)

Location: [web-call-interface](web-call-interface)

Live prototype:
- https://pragati-connect-on-call.vercel.app/

This is a web implementation of the call flow while toll-free telephony integration is being productized.

### Implemented features

- iPhone-style call UI
- Start/End call flow
- Hold-to-talk microphone interaction
- Sends voice audio to backend voice endpoint (`/api/v1/voice/query-base64`)
- Plays AI-generated audio response
- Conversation transcript bubbles
- Language selection
- Auto-auth support (with OTP fallback when needed)

### Run web call interface locally

```bash
cd web-call-interface
npm install
npm run dev
```

---

## 🧠 Backend APIs (Used by Both Interfaces)

Location: [MobileApp/backend](MobileApp/backend)

### Core API groups

- `auth` – registration, OTP verify, token refresh
- `profile` – user profile read/update
- `chat` – AI messaging and related flows
- `voice` – STT → AI → TTS pipeline (`/query`, `/query-base64`, `/transcribe`, `/synthesize`)
- `schemes` – government scheme retrieval + Q&A
- `price` – product image pricing/estimate APIs
- `business` – business profile/content generation

### Run backend locally

```bash
cd MobileApp/backend
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

API docs (local):
- http://localhost:8000/docs

---

## 🏗️ High-Level Architecture

```text
Flutter Mobile App ───────┐
                          ├──> AWS API Gateway / FastAPI backend
React Web Call Interface ─┘

Backend services:
- Auth + profile orchestration
- Voice pipeline (audio in/out)
- Chat + scheme assistance
- Price estimation
- Business tools

Infra + AI:
- AWS Lambda deployment pattern (FastAPI via Mangum)
- DynamoDB for users/conversations/estimates
- S3 for media objects
- Amazon Bedrock for LLM reasoning (Nova/Claude)
```

---

## 🧪 Practical Testing Checklist

### Mobile app testing

1. Launch app and authenticate
2. Open Schemes list and navigate to a scheme detail
3. Tap official scheme link (should open browser)
4. Test Voice Assistant query + spoken response
5. Test Price Estimator with sample image
6. Test AI Chat and Business Boost outputs

### Web call testing

1. Open live site: https://pragati-connect-on-call.vercel.app/
2. Grant microphone access
3. Start call
4. Use hold-to-talk and send a query
5. Verify transcript + audio response
6. End call

---

## 📂 Repository Structure (Key Paths)

- [MobileApp](MobileApp) — Flutter client
- [MobileApp/backend](MobileApp/backend) — FastAPI backend
- [web-call-interface](web-call-interface) — React on-call prototype
- [design.md](design.md) — detailed system design
- [requirements.md](requirements.md) — product/functional requirements

---

## 🚀 Roadmap Snapshot

- Toll-free phone number integration for production call flow
- Broader scheme intelligence and personalization
- Stronger offline and low-connectivity behavior
- Expanded analytics and deployment hardening

---

## 📄 License

MIT License

---

Built with focus on accessibility, local-language support, and real-world deployability.
