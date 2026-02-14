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
# Clone the repository
git clone https://github.com/your-org/pragati-connect.git
cd pragati-connect

# Install dependencies
pip install -r requirements.txt

# Set up environment variables
cp .env.example .env
# Edit .env with your AWS credentials, Vapi API key, etc.

# Deploy to AWS (using Serverless Framework or SAM)
serverless deploy
```

### Configuration

```bash
# Configure AWS Bedrock
aws bedrock create-knowledge-base --name pragati-schemes --region ap-south-1

# Set up Vapi.ai webhook
# Point Vapi webhook to: https://your-api-gateway-url/v1/voice-webhook

# Configure WhatsApp Business API
# Set webhook to: https://your-api-gateway-url/v1/whatsapp-webhook
```

---

## 📋 API Endpoints

### Core Endpoints (P0)

#### POST /api/v1/voice-webhook
Handle Vapi.ai voice call events
```json
{
  "transcript": "Main carpenter hoon",
  "user_phone": "+919876543210",
  "language": "hi"
}
```

#### POST /api/v1/whatsapp-webhook
Process incoming WhatsApp messages
```json
{
  "from": "+919876543210",
  "message": "Kaise apply karein?",
  "message_type": "text"
}
```

#### POST /api/v1/users/profile
Create or update user profile
```json
{
  "phone": "+919876543210",
  "primary_trade": "carpenter",
  "location": {"state": "Uttar Pradesh", "district": "Lucknow"},
  "language": "hi",
  "whatsapp_opt_in": true
}
```

### Future Enhancement (P1)

#### POST /api/v1/analyze-image
Analyze product image for price estimation
```json
{
  "user_id": "+919876543210",
  "image": "base64_encoded_image",
  "language": "ta"
}
```

---

## 🧪 Testing

### Run Tests

```bash
# Unit tests
pytest tests/unit/ -v

# Property-based tests (100 iterations each)
pytest tests/property/ -v --hypothesis-show-statistics

# Integration tests
pytest tests/integration/ -v

# Coverage report
pytest --cov=src --cov-report=html
```

### Testing Strategy

- **Unit Tests:** Specific examples, edge cases, error conditions
- **Property Tests:** Universal properties across randomized inputs (using Hypothesis)
- **Integration Tests:** End-to-end flows with mocked external services

**Priority:**
- P0: Voice webhook, WhatsApp handler, profile management
- P1: Image analysis, price estimation

---

## 🌍 Language Support

Supported languages for voice and text:
- **Hindi (hi):** Primary language
- **Tamil (ta):** South India
- **Telugu (te):** Andhra Pradesh, Telangana
- **Bengali (bn):** West Bengal, Bangladesh

All interfaces automatically adapt to user's language preference stored in profile.

---

## 📊 Key Features

### Voice Negotiator
✅ Real-time wage queries (<2s latency)  
✅ Negotiation practice with AI simulation  
✅ Multi-language support (4 languages)  
✅ Context-aware conversations (5-minute memory)  
✅ SMS summary of key points (optional)

### Opportunity Alert
✅ Automated scheme matching based on profile  
✅ Proactive WhatsApp notifications (max 2/week)  
✅ Conversational Q&A about eligibility  
✅ Application process guidance  
✅ Deadline tracking and reminders

### Visual Price Estimator (P1)
✅ Photo-based product analysis  
✅ Fair market price estimates  
✅ Voice-guided explanations  
✅ Offline caching (last 10 estimates)  
✅ Regional market context

---

## 🔒 Security & Privacy

- **Encryption:** TLS 1.3 in transit, AWS KMS at rest
- **Data Residency:** All data stored in AWS India regions (Mumbai/Hyderabad)
- **Consent Management:** Explicit opt-in for WhatsApp notifications
- **Data Deletion:** User-initiated via WhatsApp command `/delete-my-data`
- **No Third-Party Sharing:** User data never shared without explicit consent

---

## 📈 Success Metrics

- **Price Fairness:** 20%+ increase in user earnings after using price estimates
- **Scheme Awareness:** 50%+ discover relevant schemes within first week
- **Engagement:** 60%+ return for second interaction within 7 days
- **Voice Satisfaction:** 4+/5 rating for ease of use by low-literacy users

---

## 🛣️ Roadmap

### Phase 1: MVP (P0) - Current Focus
- [x] Voice Negotiator with wage queries
- [x] WhatsApp scheme notifications
- [x] User profile management
- [x] Knowledge base for government schemes
- [ ] Production deployment

### Phase 2: Enhancement (P1)
- [ ] Visual Price Estimator mobile app
- [ ] Advanced negotiation scenarios (3 personality types)
- [ ] Analytics dashboard
- [ ] Offline price estimate caching

### Phase 3: Scale (Future)
- [ ] Direct marketplace integration
- [ ] Payment processing
- [ ] Video-based skill tutorials
- [ ] Community forum
- [ ] Government portal integration

---

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Setup

```bash
# Install dev dependencies
pip install -r requirements-dev.txt

# Run linter
flake8 src/

# Format code
black src/

# Type checking
mypy src/
```

---

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Target Users:** India's 450+ million informal workers
- **Government Schemes:** Data sourced from official government portals
- **Voice Technology:** Powered by Vapi.ai, Deepgram, and ElevenLabs
- **AI Models:** Amazon Bedrock (Claude 3.5 Sonnet by Anthropic)

---


**Built with ❤️ for India's backbone workforce**
