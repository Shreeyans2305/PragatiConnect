# PragatiConnect Backend

FastAPI backend for PragatiConnect - Economic empowerment platform for India's informal workforce.

## Features

- **Phone-based Authentication** - OTP verification (mock mode available for development)
- **Multilingual AI Chat** - Powered by Amazon Bedrock with Nova/Claude models
- **Voice Assistant** - Full STT → AI → TTS pipeline with 10 Indian languages
- **Government Scheme Discovery** - Eligibility matching and guidance
- **Visual Price Estimation** - Image analysis for artisan products
- **Business Profile Generation** - AI-powered business tools

## Tech Stack

### AI/ML Services
| Service | Provider | Details |
|---------|----------|---------|
| **LLM (Primary)** | Amazon Bedrock | **Amazon Nova Lite** (`amazon.nova-lite-v1:0`) - Recommended for speed & cost |
| **LLM (Alternative)** | Amazon Bedrock | **Claude 3 Sonnet** (`anthropic.claude-3-sonnet-20240229-v1:0`) - More capable |
| **LLM (Fallback)** | Google | Gemini API (when Bedrock unavailable) |
| **Speech-to-Text** | Google Cloud | Speech-to-Text v1p1beta1 with enhanced models |
| **Text-to-Speech** | Google Cloud | Text-to-Speech with **WaveNet Female voices** |
| **Vision** | Amazon Bedrock | Nova/Claude Vision for image analysis |

> **Note:** The `bedrock_service.py` auto-detects whether you're using Nova or Claude and formats API requests accordingly.

### Infrastructure
- **Framework**: FastAPI
- **Database**: DynamoDB (users, conversations, estimates)
- **Storage**: S3 (images, audio)
- **Deployment**: AWS Lambda via Mangum handler

### Supported Languages (Voice)
| Code | Language | TTS Voice |
|------|----------|-----------|
| `en` | English (India) | en-IN-Wavenet-A (Female) |
| `hi` | Hindi | hi-IN-Wavenet-A (Female) |
| `mr` | Marathi | mr-IN-Wavenet-A (Female) |
| `ta` | Tamil | ta-IN-Wavenet-A (Female) |
| `te` | Telugu | te-IN-Standard-A (Female) |
| `bn` | Bengali | bn-IN-Wavenet-A (Female) |
| `gu` | Gujarati | gu-IN-Wavenet-A (Female) |
| `kn` | Kannada | kn-IN-Wavenet-A (Female) |
| `ml` | Malayalam | ml-IN-Wavenet-A (Female) |
| `pa` | Punjabi | pa-IN-Wavenet-A (Female) |

## Setup

### Prerequisites

- Python 3.11+
- AWS Account with Bedrock access (Nova Lite or Claude enabled)
- Google Cloud account with Speech APIs enabled
- AWS CLI configured

### Installation

1. Create virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Copy environment file:
```bash
cp .env.example .env
```

4. Configure environment variables (see below)

### Environment Variables

```bash
# AWS Configuration
AWS_REGION=ap-south-1
AWS_ACCESS_KEY_ID=your_key
AWS_SECRET_ACCESS_KEY=your_secret

# Amazon Bedrock - Choose your model
# Option 1: Nova Lite (recommended - faster & cheaper)
BEDROCK_MODEL_ID=amazon.nova-lite-v1:0
# Option 2: Claude 3 Sonnet (more capable)
# BEDROCK_MODEL_ID=anthropic.claude-3-sonnet-20240229-v1:0

# Google Cloud (for Speech APIs)
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
GOOGLE_CLOUD_PROJECT_ID=your_project_id

# Gemini API (fallback when Bedrock unavailable)
GEMINI_API_KEY=your_gemini_key

# JWT Configuration
JWT_SECRET=your_secure_secret_here
JWT_EXPIRY_HOURS=24

# OTP Configuration (for development)
OTP_MOCK_MODE=true
OTP_MOCK_CODE=123456

# DynamoDB Tables
DYNAMODB_TABLE_USERS=pragati-users
DYNAMODB_TABLE_CONVERSATIONS=pragati-conversations
DYNAMODB_TABLE_ESTIMATES=pragati-estimates

# S3 Buckets
S3_BUCKET_IMAGES=pragati-images
S3_BUCKET_AUDIO=pragati-audio

# App Settings
DEBUG=true
CORS_ORIGINS=http://localhost:3000,http://localhost:8080
```

### Running Locally

```bash
uvicorn app.main:app --reload --port 8000
```

- API: `http://localhost:8000`
- Docs: `http://localhost:8000/docs` (Swagger UI)
- ReDoc: `http://localhost:8000/redoc`

### Running with Docker

```bash
docker-compose up --build
```

## API Endpoints

### Health Check
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Service health check |
| GET | `/health` | Load balancer health check |

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/register` | Register with phone number, sends OTP |
| POST | `/api/v1/auth/verify-otp` | Verify OTP and get JWT tokens |
| POST | `/api/v1/auth/refresh-token` | Refresh expired access token |

> **Development Mode:** With `OTP_MOCK_MODE=true`, use OTP `123456` for any phone number.

### Chat (Text)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/chat/message` | Send text message, get AI response |
| POST | `/api/v1/chat/voice-query` | Voice-optimized chat (text in/out, used by voice assistant) |
| POST | `/api/v1/chat/analyze-image` | Analyze image with AI vision |
| GET | `/api/v1/chat/history` | Get conversation history |

### Voice Assistant
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/voice/query` | Full voice pipeline: Audio → STT → AI → TTS → Audio |
| POST | `/api/v1/voice/transcribe` | Speech-to-Text only |
| POST | `/api/v1/voice/synthesize` | Text-to-Speech only |

### Profile
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/profile` | Get user profile |
| PUT | `/api/v1/profile` | Update profile |

### Schemes
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/schemes` | List government schemes |
| GET | `/api/v1/schemes/{id}` | Get scheme details |
| GET | `/api/v1/schemes/eligible` | Get user-eligible schemes |
| POST | `/api/v1/schemes/query` | Ask about a scheme |

### Price Estimation
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/price/estimate` | Analyze product image for pricing |
| GET | `/api/v1/price/estimates` | Get estimate history |

### Business Tools
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/business/profile-generator` | Generate business profile |

## Quick Test (Development)

```bash
# Register and get token
curl -X POST "http://localhost:8000/api/v1/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"phone_number": "+919999888877"}'

# Verify OTP (mock mode)
curl -X POST "http://localhost:8000/api/v1/auth/verify-otp" \
  -H "Content-Type: application/json" \
  -d '{"phone_number": "+919999888877", "otp": "123456"}'

# Use the returned access_token for authenticated requests
TOKEN="your_access_token_here"

# Test TTS (Hindi)
curl -X POST "http://localhost:8000/api/v1/voice/synthesize" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"text": "नमस्कार, आप कैसे हैं?", "language": "hi"}'

# Test Chat
curl -X POST "http://localhost:8000/api/v1/chat/message" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "What schemes are available for tailors?", "language": "en"}'
```

## Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Mobile App    │────▶│  FastAPI API    │────▶│ Amazon Bedrock  │
│   (Flutter)     │     │  (this repo)    │     │ Nova/Claude     │
└─────────────────┘     └────────┬────────┘     └─────────────────┘
                                 │
                    ┌────────────┼────────────┐
                    ▼            ▼            ▼
            ┌───────────┐ ┌───────────┐ ┌───────────┐
            │  Google   │ │ DynamoDB  │ │    S3     │
            │  Cloud    │ │           │ │           │
            │ STT / TTS │ │  Users,   │ │  Images,  │
            │           │ │  Chats    │ │  Audio    │
            └───────────┘ └───────────┘ └───────────┘
```

## Model Selection Guide

| Model | Use Case | Cost | Speed |
|-------|----------|------|-------|
| **Nova Lite** | General queries, voice assistant | 💰 Low | ⚡ Fast |
| **Claude 3 Sonnet** | Complex reasoning, detailed analysis | 💰💰 Medium | 🐢 Moderate |
| **Gemini** | Fallback only | 💰 Low | ⚡ Fast |

**Recommendation:** Use Nova Lite (`amazon.nova-lite-v1:0`) for production - it's optimized for speed and cost while maintaining good quality for conversational AI.

## License

MIT
