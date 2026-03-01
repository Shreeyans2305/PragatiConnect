from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class UserBase(BaseModel):
    """Base user model."""
    phone_number: str = Field(..., pattern=r"^\+91\d{10}$")
    name: Optional[str] = None
    primary_trade: Optional[str] = None
    secondary_trades: List[str] = []
    location: Optional[str] = None
    state: Optional[str] = None
    preferred_language: str = "hi"
    whatsapp_opt_in: bool = False


class UserCreate(BaseModel):
    """User registration request."""
    phone_number: str = Field(..., pattern=r"^\+91\d{10}$")


class UserUpdate(BaseModel):
    """User profile update request."""
    name: Optional[str] = None
    primary_trade: Optional[str] = None
    secondary_trades: Optional[List[str]] = None
    location: Optional[str] = None
    state: Optional[str] = None
    preferred_language: Optional[str] = None
    whatsapp_opt_in: Optional[bool] = None


class UserProfile(UserBase):
    """Full user profile response."""
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class OTPVerifyRequest(BaseModel):
    """OTP verification request."""
    phone_number: str = Field(..., pattern=r"^\+91\d{10}$")
    otp: str = Field(..., min_length=6, max_length=6)


class TokenResponse(BaseModel):
    """Authentication token response."""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int


class RefreshTokenRequest(BaseModel):
    """Token refresh request."""
    refresh_token: str
