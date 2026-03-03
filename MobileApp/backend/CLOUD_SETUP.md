# Cloud Services Setup Guide

This guide walks you through configuring Google Cloud (Speech-to-Text, Text-to-Speech) and AWS services (Bedrock, DynamoDB, S3) for PragatiConnect.

## Architecture Overview

```
┌─────────────────┐     ┌──────────────────────────────────────────────────────┐
│   Mobile App    │     │                   Backend (FastAPI)                   │
│    (Flutter)    │────▶│                                                      │
│                 │     │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │
│  Records Audio  │     │  │ Google STT  │  │ AWS Bedrock │  │ Google TTS  │   │
│       ↓         │     │  │(Speech→Text)│─▶│   Claude    │─▶│(Text→Speech)│   │
│  Sends to API   │     │  └─────────────┘  └─────────────┘  └─────────────┘   │
└─────────────────┘     │                          │                           │
        ▲               │              ┌───────────┴───────────┐               │
        │               │              ▼                       ▼               │
        │               │     ┌─────────────┐         ┌─────────────┐          │
        │               │     │  DynamoDB   │         │     S3      │          │
        └───────────────│─────│ (History)   │         │  (Files)    │          │
     Audio Response     │     └─────────────┘         └─────────────┘          │
                        └──────────────────────────────────────────────────────┘
```

---

## Part 1: Google Cloud Setup

### 1.1 Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click **Select a project** → **New Project**
3. Enter project name: `pragati-connect` (or your preferred name)
4. Click **Create**
5. Note your **Project ID** (e.g., `pragati-connect-123456`)

### 1.2 Enable Required APIs

Enable these APIs in your project:

```bash
# Using gcloud CLI (recommended)
gcloud config set project YOUR_PROJECT_ID

# Enable Speech-to-Text API
gcloud services enable speech.googleapis.com

# Enable Text-to-Speech API
gcloud services enable texttospeech.googleapis.com
```

Or via Console:
1. Go to **APIs & Services** → **Library**
2. Search and enable:
   - **Cloud Speech-to-Text API**
   - **Cloud Text-to-Speech API**

### 1.3 Create Service Account

1. Go to **IAM & Admin** → **Service Accounts**
2. Click **Create Service Account**
3. Details:
   - Name: `pragati-voice-service`
   - Description: `Service account for PragatiConnect voice features`
4. Click **Create and Continue**
5. Grant roles (click **Add Another Role** to add multiple):
   - `Cloud Speech Client` (for Speech-to-Text)
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

### 1.6 Pricing (Important!)

**Speech-to-Text:**
| Feature | Free Tier | Paid |
|---------|-----------|------|
| Standard models | 60 min/month free | $0.006/15 sec |
| Enhanced models | 60 min/month free | $0.009/15 sec |

**Text-to-Speech:**
| Voice Type | Free Tier | Paid |
|------------|-----------|------|
| Standard | 4M chars/month | $4/1M chars |
| WaveNet | 1M chars/month | $16/1M chars |
| Neural2 | 1M chars/month | $16/1M chars |

💡 **Cost Optimization Tips:**
- Use standard voices for non-critical responses
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
   - **Anthropic Claude 3 Sonnet**
   - **Anthropic Claude 3 Haiku** (optional, faster/cheaper)
5. Wait for approval (usually instant)

#### Note Model IDs

```bash
# Claude 3 Sonnet (recommended for quality)
anthropic.claude-3-sonnet-20240229-v1:0

# Claude 3 Haiku (faster, cheaper)
anthropic.claude-3-haiku-20240307-v1:0

# Claude 3.5 Sonnet (latest, if available)
anthropic.claude-3-5-sonnet-20241022-v2:0
```

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

**Bedrock (Claude):**
| Model | Input | Output |
|-------|-------|--------|
| Claude 3 Haiku | $0.00025/1K tokens | $0.00125/1K tokens |
| Claude 3 Sonnet | $0.003/1K tokens | $0.015/1K tokens |
| Claude 3.5 Sonnet | $0.003/1K tokens | $0.015/1K tokens |

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

# Amazon Bedrock
BEDROCK_MODEL_ID=anthropic.claude-3-sonnet-20240229-v1:0
BEDROCK_KNOWLEDGE_BASE_ID=  # Optional

# ============================================
# Google Cloud Configuration
# ============================================
GOOGLE_APPLICATION_CREDENTIALS=/app/secrets/gcp-service-account.json
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
OTP_MOCK_MODE=false
```

---

## Part 4: API Endpoints

### Voice Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/voice/query` | POST | Full voice pipeline (multipart audio) |
| `/api/v1/voice/query-base64` | POST | Full voice pipeline (base64 JSON) |
| `/api/v1/voice/transcribe` | POST | Speech-to-text only |
| `/api/v1/voice/synthesize` | POST | Text-to-speech only |

### Example: Full Voice Query

```bash
curl -X POST "https://api.pragaticonnect.com/api/v1/voice/query" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "audio_file=@recording.wav" \
  -F "language=hi" \
  -F "conversation_id=conv_123"
```

Response:
```json
{
  "user_transcript": "मुझे PM किसान योजना के बारे में बताओ",
  "ai_response": "PM किसान सम्मान निधि योजना में...",
  "audio_response": "base64_encoded_mp3_audio...",
  "audio_format": "mp3",
  "conversation_id": "conv_123",
  "language": "hi",
  "stt_confidence": 0.95
}
```

---

## Part 5: Testing

### Test Google Cloud Connection

```python
# test_google.py
from google.cloud import speech_v1p1beta1 as speech
from google.cloud import texttospeech

# Test STT
stt = speech.SpeechClient()
print("✅ Speech-to-Text client connected")

# Test TTS  
tts = texttospeech.TextToSpeechClient()
voices = tts.list_voices(language_code="hi-IN")
print(f"✅ Text-to-Speech connected, {len(voices.voices)} Hindi voices available")
```

### Test AWS Connection

```python
# test_aws.py
import boto3

# Test Bedrock
bedrock = boto3.client('bedrock-runtime', region_name='ap-south-1')
print("✅ Bedrock client connected")

# Test DynamoDB
dynamodb = boto3.resource('dynamodb', region_name='ap-south-1')
table = dynamodb.Table('pragati-users')
print(f"✅ DynamoDB connected, table status: {table.table_status}")
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

| Service | Usage | Cost/Month |
|---------|-------|------------|
| Google STT | ~250K minutes | ~$100 |
| Google TTS | ~50M chars | ~$200 |
| AWS Bedrock | ~5M tokens | ~$75 |
| DynamoDB | ~15M requests | ~$20 |
| S3 | 50GB storage | ~$2 |
| **Total** | | **~$400/month** |

💡 **Optimization strategies:**
- Use Claude Haiku for simple queries (~90% cheaper)
- Cache common TTS responses in S3
- Use Standard TTS voices instead of WaveNet
- Implement request throttling

---

## Troubleshooting

### Google Cloud Issues

```bash
# Verify credentials
gcloud auth application-default print-access-token

# Check API enabled
gcloud services list --enabled | grep -E "speech|texttospeech"
```

### AWS Issues

```bash
# Verify AWS credentials
aws sts get-caller-identity

# Check Bedrock model access
aws bedrock list-foundation-models --region ap-south-1
```

### Common Errors

| Error | Solution |
|-------|----------|
| `GOOGLE_APPLICATION_CREDENTIALS not found` | Set env var or path in config |
| `Bedrock model not accessible` | Request model access in AWS Console |
| `DynamoDB table not found` | Create tables with correct names |
| `Audio encoding not supported` | Use LINEAR16, OGG_OPUS, or FLAC |
