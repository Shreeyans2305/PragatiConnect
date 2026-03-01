# PragatiConnect Backend

FastAPI backend for PragatiConnect - Economic empowerment platform for India's informal workforce.

## Features

- User authentication via phone number + OTP
- Chat interface with Amazon Bedrock (Claude)
- Government scheme discovery and eligibility matching
- Visual price estimation for artisan products
- Business profile generation

## Tech Stack

- **Framework**: FastAPI
- **AI/ML**: Amazon Bedrock (Claude 3.5 Sonnet)
- **Database**: DynamoDB
- **Storage**: S3 (for images)
- **Deployment**: AWS Lambda via Mangum

## Setup

### Prerequisites

- Python 3.11+
- AWS Account with Bedrock access
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

4. Edit `.env` with your credentials

### Running Locally

```bash
uvicorn app.main:app --reload --port 8000
```

API will be available at `http://localhost:8000`
Docs at `http://localhost:8000/docs`

### Running with Docker

```bash
docker-compose up --build
```

## API Endpoints

### Authentication
- `POST /api/v1/auth/register` - Register with phone number
- `POST /api/v1/auth/verify-otp` - Verify OTP
- `POST /api/v1/auth/refresh-token` - Refresh JWT token

### Profile
- `GET /api/v1/profile` - Get user profile
- `PUT /api/v1/profile` - Update profile

### Chat
- `POST /api/v1/chat/message` - Send chat message
- `POST /api/v1/voice/query` - Voice query
- `GET /api/v1/chat/history` - Conversation history

### Schemes
- `GET /api/v1/schemes` - List schemes
- `GET /api/v1/schemes/{id}` - Scheme details
- `GET /api/v1/schemes/eligible` - User-eligible schemes
- `POST /api/v1/schemes/query` - Ask about a scheme

### Price Estimation
- `POST /api/v1/price/estimate` - Analyze product image
- `GET /api/v1/price/estimates` - Estimate history

### Business Tools
- `POST /api/v1/business/profile-generator` - Generate business profile

## Environment Variables

See `.env.example` for all required variables.

## License

MIT
