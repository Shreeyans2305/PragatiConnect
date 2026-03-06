from pydantic_settings import BaseSettings
from pydantic import ConfigDict
from functools import lru_cache
from typing import List
from pathlib import Path


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    _env_path = Path(__file__).resolve().parents[1] / ".env"
    model_config = ConfigDict(
        env_file=str(_env_path),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # AWS Configuration
    aws_region: str = "us-east-1"       # used for Bedrock
    aws_s3_region: str = "ap-south-1"   # used for S3 and DynamoDB
    aws_access_key_id: str = ""
    aws_secret_access_key: str = ""

    # DynamoDB Tables
    dynamodb_table_users: str = "pragati-users"
    dynamodb_table_conversations: str = "pragati-conversations"
    dynamodb_table_estimates: str = "pragati-estimates"

    # S3 Configuration
    s3_bucket_images: str = "pragati-images"
    s3_bucket_audio: str = "pragati-audio"  # For storing voice recordings

    # Amazon Bedrock
    bedrock_model_id: str = "anthropic.claude-3-sonnet-20240229-v1:0"
    bedrock_knowledge_base_id: str = ""

    # Google Cloud Configuration
    # Path to service account JSON file (standard Google Cloud env var)
    google_application_credentials: str = ""
    google_cloud_credentials_path: str = ""
    google_cloud_project_id: str = ""

    # Gemini API (fallback when Bedrock unavailable)
    gemini_api_key: str = ""

    # JWT Configuration
    jwt_secret: str = "change_me_in_production"
    jwt_algorithm: str = "HS256"
    jwt_expiry_hours: int = 24

    # OTP Configuration
    otp_mock_mode: bool = False
    otp_mock_code: str = "123456"

    # Email Configuration (Gmail SMTP)
    gmail_address: str = ""  # Your Gmail address (e.g., your-email@gmail.com)
    gmail_app_password: str = ""  # Your Gmail App Password (16-character password)
    email_mock_mode: bool = False  # Set to True to skip actual email sending

    # App Configuration
    debug: bool = True
    cors_origins: str = "http://localhost:3000,http://localhost:8080"

    @property
    def cors_origins_list(self) -> List[str]:
        return [origin.strip() for origin in self.cors_origins.split(",")]


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()


settings = get_settings()
