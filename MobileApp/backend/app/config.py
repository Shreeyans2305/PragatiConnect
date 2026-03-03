from pydantic_settings import BaseSettings
from functools import lru_cache
from typing import List


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    # AWS Configuration
    aws_region: str = "ap-south-1"
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
    otp_mock_mode: bool = True
    otp_mock_code: str = "123456"

    # App Configuration
    debug: bool = True
    cors_origins: str = "http://localhost:3000,http://localhost:8080"

    @property
    def cors_origins_list(self) -> List[str]:
        return [origin.strip() for origin in self.cors_origins.split(",")]

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()


settings = get_settings()
