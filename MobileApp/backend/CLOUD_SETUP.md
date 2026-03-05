# Cloud Services Setup Guide

This guide walks you through configuring Google Cloud Text-to-Speech and AWS Bedrock services for PragatiConnect.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              Mobile App (Flutter)                                │
│  ┌─────────────────────────────────────────────────────────────────────────┐    │
│  │  speech_to_text package (Device STT - no cloud needed for transcription) │    │
│  │  Records audio → Transcribes on-device → Sends TEXT to backend          │    │
│  └─────────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        │ POST /api/v1/chat/voice-query
                                        │ { "query": "transcribed text", "language": "hi" }
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           Backend (FastAPI)                                      │
│                                                                                  │
│  ┌─────────────────────────────┐    ┌─────────────────────────────────────────┐ │
│  │     AWS Bedrock             │    │      Google Cloud TTS                   │ │
│  │  ┌───────────────────────┐  │    │   (All Female WaveNet Voices)          │ │
│  │  │ Amazon Nova Lite      │  │    │                                         │ │
│  │  │ (Recommended - 50x    │  │───▶│   Text Response → Female Voice Audio   │ │
│  │  │  cheaper than Claude) │  │    │   Returns MP3 to mobile app            │ │
│  │  └───────────────────────┘  │    └─────────────────────────────────────────┘ │
│  │  ┌───────────────────────┐  │                       │                        │
│  │  │ Claude 3 Sonnet       │  │                       │                        │
│  │  │ (More capable)        │  │                       │                        │
│  │  └───────────────────────┘  │                       │                        │
│  └─────────────────────────────┘                       │                        │
│                                                        ▼                        │
│                                      ┌──────────────────────────────┐           │
│                                      │    DynamoDB (Chat History)   │           │
│                                      │    S3 (Image Storage)        │           │
│                                      └──────────────────────────────┘           │
└─────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        │ Response: { "response": "...", 
                                        │            "audio_content": "base64 MP3",
                                        │            "audio_format": "mp3" }
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           Mobile App (Flutter)                                   │
│  Plays MP3 audio response with female voice                                     │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### Key Architecture Points

1. **Device-side STT**: Speech recognition happens on the mobile device using Flutter's `speech_to_text` package (no Google Cloud STT needed)
2. **Text-based API**: Backend receives text queries, not audio files
3. **Bedrock AI**: Processes queries using Nova Lite (recommended) or Claude 3 Sonnet
4. **Female TTS**: All responses use Google Cloud female WaveNet voices for natural sound

---

## Part 1: Google Cloud Setup (Text-to-Speech Only)

> **Note**: We only use Google Cloud for Text-to-Speech. Speech recognition is handled on-device by the Flutter app.

### 1.1 Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click **Select a project** → **New Project**
3. Enter project name: `pragati-connect` (or your preferred name)
4. Click **Create**
5. Note your **Project ID** (e.g., `pragati-connect-123456`)

### 1.2 Enable Required APIs

Enable the Text-to-Speech API in your project:

```bash
# Using gcloud CLI (recommended)
gcloud config set project YOUR_PROJECT_ID

# Enable Text-to-Speech API
gcloud services enable texttospeech.googleapis.com
```

Or via Console:
1. Go to **APIs & Services** → **Library**
2. Search and enable:
   - **Cloud Text-to-Speech API**

### 1.3 Create Service Account

1. Go to **IAM & Admin** → **Service Accounts**
2. Click **Create Service Account**
3. Details:
   - Name: `pragati-tts-service`
   - Description: `Service account for PragatiConnect Text-to-Speech`
4. Click **Create and Continue**
5. Grant roles:
   - `Service Usage Consumer` (allows calling enabled APIs)
   
   **Note:** Text-to-Speech doesn't have a specific role - it's controlled by enabling the API. The Service Usage Consumer role allows the service account to call any enabled API.
   
   **Alternative (simpler):** Grant `Editor` role if this is a development/test project.
6. Click **Done**

### 1.4 Generate Service Account Key

1. Click on the created service account
2. Go to **Keys** tab
3. Click **Add Key** → **Create new key**
4. Select **JSON** format
5. Click **Create**
6. Save the downloaded JSON file securely (e.g., `gcp-service-account.json`)

### 1.5 Configure Environment

Set the credentials in your backend:

```bash
# Option 1: Set environment variable (recommended for production)
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/gcp-service-account.json"

# Option 2: In .env file
GOOGLE_CLOUD_CREDENTIALS_PATH=/path/to/gcp-service-account.json
GOOGLE_CLOUD_PROJECT_ID=your-project-id
```

### 1.6 Pricing & Voice Configuration

**Text-to-Speech Voices (All Female):**

The app uses female WaveNet voices for all Indian languages. These provide natural, high-quality speech:

| Language | Voice ID | Type | Gender |
|----------|----------|------|--------|
| English | `en-IN-Wavenet-A` | WaveNet | Female |
| Hindi | `hi-IN-Wavenet-A` | WaveNet | Female |
| Tamil | `ta-IN-Wavenet-A` | WaveNet | Female |
| Telugu | `te-IN-Standard-A` | Standard* | Female |
| Bengali | `bn-IN-Wavenet-A` | WaveNet | Female |
| Marathi | `mr-IN-Wavenet-A` | WaveNet | Female |
| Gujarati | `gu-IN-Wavenet-A` | WaveNet | Female |
| Kannada | `kn-IN-Wavenet-A` | WaveNet | Female |
| Malayalam | `ml-IN-Wavenet-A` | WaveNet | Female |
| Punjabi | `pa-IN-Wavenet-A` | WaveNet | Female |

*Telugu uses Standard voice because WaveNet is not available for this language.

**Text-to-Speech Pricing:**
| Voice Type | Free Tier | Paid |
|------------|-----------|------|
| Standard | 4M chars/month | $4/1M chars |
| WaveNet | 1M chars/month | $16/1M chars |
| Neural2 | 1M chars/month | $16/1M chars |

💡 **Cost Optimization Tips:**
- Cache frequently used audio responses
- Set usage quotas in GCP Console

---

## Part 2: AWS Setup

### 2.1 Create AWS Account/IAM User

1. Go to [AWS Console](https://console.aws.amazon.com/)
2. Create an IAM user with programmatic access
3. Attach policies (or create custom):
   - `AmazonDynamoDBFullAccess`
   - `AmazonS3FullAccess`
   - `AmazonBedrockFullAccess`

### 2.2 Configure AWS Bedrock

#### Enable Model Access

1. Go to **Amazon Bedrock** in AWS Console
2. Select your region (e.g., `us-east-1` or `ap-south-1`)
3. Go to **Model access** → **Manage model access**
4. Request access to:
   - **Amazon Nova Lite** ⭐ (Recommended - much faster & cheaper)
   - **Anthropic Claude 3 Sonnet** (More capable, higher quality)
5. Wait for approval (usually instant for Nova, may take time for Claude)

#### Available Model IDs

```bash
# Amazon Nova Lite (RECOMMENDED - 50x cheaper than Claude!)
amazon.nova-lite-v1:0

# Anthropic Claude 3 Sonnet (more capable, but expensive)
anthropic.claude-3-sonnet-20240229-v1:0
```

#### Model Auto-Detection

The backend automatically detects the model type and uses the appropriate request format:

```python
# In bedrock_service.py
self.is_nova = "nova" in self.model_id.lower()
```

- **Nova models**: Use Amazon's native request/response format
- **Claude models**: Use Anthropic's Messages API format

### 2.3 Create DynamoDB Tables

#### Users Table

```bash
aws dynamodb create-table \
    --table-name pragati-users \
    --attribute-definitions \
        AttributeName=phone_number,AttributeType=S \
    --key-schema \
        AttributeName=phone_number,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region ap-south-1
```

#### Conversations Table

```bash
aws dynamodb create-table \
    --table-name pragati-conversations \
    --attribute-definitions \
        AttributeName=phone_number,AttributeType=S \
        AttributeName=conversation_id,AttributeType=S \
    --key-schema \
        AttributeName=phone_number,KeyType=HASH \
        AttributeName=conversation_id,KeyType=RANGE \
    --billing-mode PAY_PER_REQUEST \
    --region ap-south-1
```

#### Estimates Table (for price estimation feature)

```bash
aws dynamodb create-table \
    --table-name pragati-estimates \
    --attribute-definitions \
        AttributeName=estimate_id,AttributeType=S \
        AttributeName=phone_number,AttributeType=S \
    --key-schema \
        AttributeName=estimate_id,KeyType=HASH \
    --global-secondary-indexes \
        "[{\"IndexName\": \"phone-index\", \"KeySchema\": [{\"AttributeName\": \"phone_number\", \"KeyType\": \"HASH\"}], \"Projection\": {\"ProjectionType\": \"ALL\"}}]" \
    --billing-mode PAY_PER_REQUEST \
    --region ap-south-1
```

### 2.4 Create S3 Buckets

```bash
# Images bucket
aws s3 mb s3://pragati-images-YOUR_ACCOUNT_ID --region ap-south-1

# Audio bucket (optional, for storing voice recordings)
aws s3 mb s3://pragati-audio-YOUR_ACCOUNT_ID --region ap-south-1

# Set CORS for image uploads
aws s3api put-bucket-cors --bucket pragati-images-YOUR_ACCOUNT_ID --cors-configuration '{
    "CORSRules": [{
        "AllowedHeaders": ["*"],
        "AllowedMethods": ["GET", "PUT", "POST"],
        "AllowedOrigins": ["*"],
        "ExposeHeaders": ["ETag"]
    }]
}'
```

### 2.5 Create Knowledge Base (Optional - for RAG)

For enhanced scheme recommendations with RAG:

1. Go to **Amazon Bedrock** → **Knowledge bases**
2. Click **Create knowledge base**
3. Configure:
   - Name: `pragati-schemes-kb`
   - Data source: S3 bucket with scheme documents
   - Embedding model: Amazon Titan Embeddings
4. Sync your scheme documents

### 2.6 AWS Pricing

**Bedrock AI Models:**

| Model | Input | Output | Notes |
|-------|-------|--------|-------|
| **Amazon Nova Lite** ⭐ | $0.00006/1K tokens | $0.00024/1K tokens | **~50x cheaper!** Recommended |
| Claude 3 Sonnet | $0.003/1K tokens | $0.015/1K tokens | Higher quality, expensive |

> 💡 **Nova Lite is the default recommendation** - it's dramatically cheaper while providing good quality for agricultural assistant use cases.

**Cost Comparison Example (1000 queries/day):**
| Model | Daily Cost | Monthly Cost |
|-------|------------|--------------|
| Nova Lite | ~$0.15 | ~$4.50 |
| Claude 3 Sonnet | ~$9.00 | ~$270 |

**DynamoDB:** Pay per request (~$1.25 per million writes)

**S3:** ~$0.023/GB/month storage

---

## Part 3: Complete .env Configuration

Create a `.env` file in the backend folder:

```env
# ============================================
# AWS Configuration
# ============================================
AWS_REGION=ap-south-1
AWS_ACCESS_KEY_ID=AKIAXXXXXXXXXX
AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxx

# DynamoDB Tables
DYNAMODB_TABLE_USERS=pragati-users
DYNAMODB_TABLE_CONVERSATIONS=pragati-conversations
DYNAMODB_TABLE_ESTIMATES=pragati-estimates

# S3 Buckets
S3_BUCKET_IMAGES=pragati-images-123456789
S3_BUCKET_AUDIO=pragati-audio-123456789

# Amazon Bedrock - Choose one:
# Option 1: Nova Lite (RECOMMENDED - 50x cheaper)
BEDROCK_MODEL_ID=amazon.nova-lite-v1:0

# Option 2: Claude 3 Sonnet (more capable, higher cost)
# BEDROCK_MODEL_ID=anthropic.claude-3-sonnet-20240229-v1:0

# Optional: Knowledge Base for RAG
BEDROCK_KNOWLEDGE_BASE_ID=

# ============================================
# Google Cloud Configuration
# ============================================
# Set the path to your service account JSON file
GOOGLE_APPLICATION_CREDENTIALS=/path/to/gcp-service-account.json
GOOGLE_CLOUD_PROJECT_ID=pragati-connect-123456

# ============================================
# Security
# ============================================
JWT_SECRET=your-super-secure-256-bit-secret-key-here
JWT_ALGORITHM=HS256
JWT_EXPIRY_HOURS=24

# ============================================
# App Settings
# ============================================
DEBUG=false
CORS_ORIGINS=https://your-app-domain.com

# ============================================
# Testing/Development Mode
# ============================================
# Set these for local development to skip real OTP verification
OTP_MOCK_MODE=true
OTP_MOCK_CODE=123456
```

---

## Part 4: API Endpoints

### Voice/Chat Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/chat/voice-query` | POST | Main voice query endpoint (text in → text + audio out) |
| `/api/v1/voice/synthesize` | POST | Text-to-speech only (convert text to female voice audio) |

### Example: Voice Query (Main Flow)

The mobile app transcribes speech on-device and sends text:

```bash
curl -X POST "https://api.pragaticonnect.com/api/v1/chat/voice-query" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "मुझे PM किसान योजना के बारे में बताओ",
    "language": "hi",
    "conversation_id": "conv_123"
  }'
```

Response:
```json
{
  "response": "PM किसान सम्मान निधि योजना में किसानों को प्रति वर्ष ₹6,000 की आर्थिक सहायता दी जाती है...",
  "audio_content": "base64_encoded_mp3_audio...",
  "audio_format": "mp3",
  "conversation_id": "conv_123",
  "language": "hi"
}
```

### Example: Text-to-Speech Only

```bash
curl -X POST "https://api.pragaticonnect.com/api/v1/voice/synthesize" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "नमस्कार, तुम्ही कसे आहात?",
    "language": "mr"
  }'
```

Response:
```json
{
  "audio_content": "base64_encoded_mp3_audio...",
  "audio_format": "mp3",
  "language": "mr"
}
```

---

## Part 5: Testing

### Test Google Cloud TTS Connection

```python
# test_google_tts.py
from google.cloud import texttospeech

# Test TTS  
tts = texttospeech.TextToSpeechClient()
voices = tts.list_voices(language_code="hi-IN")
print(f"✅ Text-to-Speech connected, {len(voices.voices)} Hindi voices available")

# Verify female WaveNet voice exists
for voice in voices.voices:
    if "Wavenet-A" in voice.name:
        print(f"✅ Found female WaveNet voice: {voice.name}")
```

### Test AWS Bedrock Connection

```python
# test_bedrock.py
import boto3
import json

# Test Bedrock with Nova Lite
bedrock = boto3.client('bedrock-runtime', region_name='ap-south-1')

# Test Nova Lite request format
response = bedrock.invoke_model(
    modelId='amazon.nova-lite-v1:0',
    body=json.dumps({
        "inferenceConfig": {"max_new_tokens": 100, "temperature": 0.7},
        "system": [{"text": "You are a helpful assistant."}],
        "messages": [{"role": "user", "content": [{"text": "Hello"}]}]
    })
)
print("✅ Bedrock Nova Lite connected")
```

### Test with Mock OTP (Development)

```bash
# Register a test user
curl -X POST "http://127.0.0.1:8000/api/v1/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"phone_number": "+919999888877"}'

# Verify with mock OTP (when OTP_MOCK_MODE=true)
curl -X POST "http://127.0.0.1:8000/api/v1/auth/verify-otp" \
  -H "Content-Type: application/json" \
  -d '{"phone_number": "+919999888877", "otp": "123456"}'
```

---

## Part 6: Deployment

### Docker Deployment

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY app/ ./app/

# Copy Google credentials (mount as secret in production)
COPY secrets/gcp-service-account.json /app/secrets/

ENV GOOGLE_APPLICATION_CREDENTIALS=/app/secrets/gcp-service-account.json

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### AWS Lambda Deployment

The app includes `mangum` handler for Lambda:

```python
# In app/main.py
handler = Mangum(app, lifespan="off")
```

Deploy using SAM or Serverless Framework.

---

## Part 7: Cost Estimation

For 10,000 monthly active users with ~5 voice queries/day:

**Using Amazon Nova Lite (Recommended):**
| Service | Usage | Cost/Month |
|---------|-------|------------|
| Google TTS (WaveNet) | ~50M chars | ~$200 |
| AWS Bedrock (Nova Lite) | ~5M tokens | ~$1.50 |
| DynamoDB | ~15M requests | ~$20 |
| S3 | 50GB storage | ~$2 |
| **Total** | | **~$224/month** |

**Using Claude 3 Sonnet:**
| Service | Usage | Cost/Month |
|---------|-------|------------|
| Google TTS (WaveNet) | ~50M chars | ~$200 |
| AWS Bedrock (Claude 3 Sonnet) | ~5M tokens | ~$90 |
| DynamoDB | ~15M requests | ~$20 |
| S3 | 50GB storage | ~$2 |
| **Total** | | **~$312/month** |

💡 **Optimization Strategies:**
- **Use Nova Lite** - 50x cheaper than Claude with good quality for most queries
- Cache common TTS responses in S3
- Consider Standard TTS voices for non-critical audio (~4x cheaper than WaveNet)
- Implement request throttling

---

## Troubleshooting

### Google Cloud Issues

```bash
# Verify credentials are set
echo $GOOGLE_APPLICATION_CREDENTIALS

# Check API enabled
gcloud services list --enabled | grep texttospeech
```

### AWS Issues

```bash
# Verify AWS credentials
aws sts get-caller-identity

# Check Bedrock model access (list available models)
aws bedrock list-foundation-models --region ap-south-1

# Check if Nova Lite is accessible
aws bedrock list-foundation-models --region ap-south-1 | grep -i nova
```

### Common Errors

| Error | Solution |
|-------|----------|
| `GOOGLE_APPLICATION_CREDENTIALS not found` | Set env var: `export GOOGLE_APPLICATION_CREDENTIALS=/path/to/file.json` |
| `Bedrock model not accessible` | Request model access in AWS Console → Bedrock → Model access |
| `Nova model format error` | Ensure using correct request format (check `is_nova` detection) |
| `DynamoDB table not found` | Create tables with correct names |
| `TTS voice not found` | Verify language code matches supported voices |
| `OTP verification failed` | Set `OTP_MOCK_MODE=true` and `OTP_MOCK_CODE=123456` for testing |
