# Pragati Connect

> **Unified Economic Assistant for India's Informal Workforce**

Pragati Connect bridges the gap between informal workers (artisans, maids, daily wage laborers) and the formal economy through fair price discovery, negotiation support, and government scheme access.

---

## 🎯 The Problem

India's 450+ million informal workers operate in an economic blind spot:
- **Information Asymmetry:** No access to fair price discovery or wage benchmarks
- **Exploitation:** Middlemen and clients leverage knowledge gaps to underpay
- **Missed Opportunities:** Unaware of government welfare schemes worth ₹6,000-₹2,50,000 annually
- **Confidence Gap:** Lack negotiation skills and practice for formal interactions

**Impact:** Fair price discovery alone can increase artisan income by 15-30%.

---

## 💡 The Solution

Pragati Connect provides three accessible interfaces powered by a unified AI backend:

### 1. 🎙️ Voice Negotiator (Phone Call) - **P0 Core Feature**
- **Access:** Standard phone call to toll-free number
- **Features:**
  - Real-time wage queries in local language (Hindi, Tamil, Telugu, Bengali)
  - Interactive negotiation practice with AI client simulation
  - Confidence-building through realistic scenarios
- **Technology:** Vapi.ai + Deepgram (STT) + ElevenLabs (TTS)
- **Latency:** <2 seconds end-to-end response time

### 2. 💬 Opportunity Alert (WhatsApp) - **P0 Core Feature**
- **Access:** WhatsApp chatbot on user's existing number
- **Features:**
  - Proactive notifications about relevant government schemes
  - Eligibility matching based on trade, location, and profile
  - Conversational Q&A about scheme details and application process
- **Rate Limiting:** Max 2 notifications per week to avoid spam

### 3. 📱 Visual Price Estimator (Mobile App) - **P1 Future Enhancement**
- **Access:** Mobile application (React Native/Flutter)
- **Features:**
  - Photo-based product analysis using multimodal AI
  - Fair market price estimates with regional context
  - Voice-guided explanations in local language
  - Offline caching of recent estimates
- **Technology:** Amazon Bedrock (Claude 3.5 Sonnet) for vision analysis

---

## 🏗️ Architecture

### High-Level Design

```
┌─────────────────────────────────────────────────────────────┐
│                     User Interfaces                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Phone Call   │  │  WhatsApp    │  │  Mobile App  │      │
│  │  (Vapi.ai)   │  │   Chatbot    │  │   (Future)   │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
└─────────┼──────────────────┼──────────────────┼─────────────┘
          │                  │                  │
          └──────────────────┼──────────────────┘
                             │
                    ┌────────▼────────┐
                    │  AWS API Gateway │
                    └────────┬────────┘
                             │
          ┌──────────────────┼──────────────────┐
          │                  │                  │
    ┌─────▼─────┐     ┌─────▼─────┐     ┌─────▼─────┐
    │  Voice    │     │ WhatsApp  │     │  Profile  │
    │  Handler  │     │  Handler  │     │  Manager  │
    │  Lambda   │     │  Lambda   │     │  Lambda   │
    └─────┬─────┘     └─────┬─────┘     └─────┬─────┘
          │                  │                  │
          └──────────────────┼──────────────────┘
                             │
                    ┌────────▼────────┐
                    │  Central Brain   │
                    │  (Orchestration) │
                    └────────┬────────┘
                             │
          ┌──────────────────┼──────────────────┐
          │                  │                  │
    ┌─────▼─────┐     ┌─────▼─────┐     ┌─────▼─────┐
    │  Bedrock  │     │ Knowledge │     │ DynamoDB  │
    │   LLM     │     │   Base    │     │  Profiles │
    │  (Claude) │     │   (RAG)   │     │  & Data   │
    └───────────┘     └───────────┘     └───────────┘
```

### Technology Stack

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| **Backend** | Python + FastAPI | Rapid development, async support, AWS Lambda native |
| **AI/LLM** | Amazon Bedrock (Claude 3.5 Sonnet) | Best reasoning, AWS-native, low latency from India |
| **Knowledge Base** | Knowledge Bases for Bedrock (RAG) | Managed semantic search for government schemes |
| **Voice** | Vapi.ai + Deepgram + ElevenLabs | Production-ready, <2s latency, multilingual |
| **Database** | DynamoDB | Serverless, single-digit ms latency, auto-scaling |
| **Storage** | S3 | Durable image storage with lifecycle policies |
| **Compute** | AWS Lambda | Zero infrastructure, auto-scaling, pay-per-use |
| **API** | AWS API Gateway | RESTful endpoints, validation, throttling |

---

## 👥 User Personas

### Radha the Weaver (38, Tamil Nadu)
- **Trade:** Handloom saree weaving
- **Challenge:** Middlemen offer ₹800 for sarees worth ₹2,500
- **Tech Access:** Feature phone (primary), occasional smartphone via family
- **Usage:** Visual Price Estimator (via daughter's phone) + WhatsApp alerts for weaver schemes

### Raju the Carpenter (45, Uttar Pradesh)
- **Trade:** Furniture carpentry and home repairs
- **Challenge:** Accepts low rates (₹400/day) due to negotiation uncertainty
- **Tech Access:** Basic feature phone with voice capability
- **Usage:** Voice Negotiator for wage queries and practice + WhatsApp for housing schemes

---

## 🚀 Getting Started

### Prerequisites

- Python 3.11+
- AWS Account with Bedrock access
- Vapi.ai account for voice integration
- WhatsApp Business API access

### Installation

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
