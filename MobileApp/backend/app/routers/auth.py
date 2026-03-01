from fastapi import APIRouter, HTTPException, status
from datetime import datetime, timedelta
from jose import jwt
import random

from app.config import settings
from app.db.dynamodb import dynamodb
from app.models.user import (
    UserCreate,
    OTPVerifyRequest,
    TokenResponse,
    RefreshTokenRequest,
)

router = APIRouter()


def create_tokens(phone_number: str) -> dict:
    """Create access and refresh tokens."""
    now = datetime.utcnow()
    
    # Access token
    access_exp = now + timedelta(hours=settings.jwt_expiry_hours)
    access_token = jwt.encode(
        {"sub": phone_number, "exp": access_exp.timestamp(), "type": "access"},
        settings.jwt_secret,
        algorithm=settings.jwt_algorithm,
    )
    
    # Refresh token (7 days)
    refresh_exp = now + timedelta(days=7)
    refresh_token = jwt.encode(
        {"sub": phone_number, "exp": refresh_exp.timestamp(), "type": "refresh"},
        settings.jwt_secret,
        algorithm=settings.jwt_algorithm,
    )
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "expires_in": settings.jwt_expiry_hours * 3600,
    }


# In-memory OTP store (use Redis in production)
otp_store: dict = {}


@router.post("/register", status_code=status.HTTP_200_OK)
async def register(request: UserCreate):
    """Register a new user and send OTP."""
    phone = request.phone_number
    
    # Generate OTP
    if settings.otp_mock_mode:
        otp = settings.otp_mock_code
    else:
        otp = str(random.randint(100000, 999999))
    
    # Store OTP (expires in 5 minutes)
    otp_store[phone] = {
        "otp": otp,
        "expires": datetime.utcnow() + timedelta(minutes=5),
    }
    
    # In production, send OTP via SMS here
    # For now, just return success
    return {
        "message": "OTP sent successfully",
        "phone_number": phone,
        # Only include in mock mode for testing
        **({"otp": otp} if settings.otp_mock_mode else {}),
    }


@router.post("/verify-otp", response_model=TokenResponse)
async def verify_otp(request: OTPVerifyRequest):
    """Verify OTP and return tokens."""
    phone = request.phone_number
    otp = request.otp
    
    # Check OTP
    stored = otp_store.get(phone)
    if not stored:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No OTP found for this phone number. Please register first.",
        )
    
    if datetime.utcnow() > stored["expires"]:
        del otp_store[phone]
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="OTP has expired. Please request a new one.",
        )
    
    if stored["otp"] != otp:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid OTP.",
        )
    
    # Clear OTP
    del otp_store[phone]
    
    # Create or get user
    user = dynamodb.get_user(phone)
    if not user:
        user = dynamodb.create_user({
            "phone_number": phone,
            "preferred_language": "hi",
            "whatsapp_opt_in": False,
        })
    
    # Generate tokens
    tokens = create_tokens(phone)
    
    return TokenResponse(
        access_token=tokens["access_token"],
        refresh_token=tokens["refresh_token"],
        expires_in=tokens["expires_in"],
    )


@router.post("/refresh-token", response_model=TokenResponse)
async def refresh_token(request: RefreshTokenRequest):
    """Refresh access token."""
    try:
        payload = jwt.decode(
            request.refresh_token,
            settings.jwt_secret,
            algorithms=[settings.jwt_algorithm],
        )
        
        if payload.get("type") != "refresh":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid token type",
            )
        
        phone_number = payload.get("sub")
        if not phone_number:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid token",
            )
        
        # Verify user exists
        user = dynamodb.get_user(phone_number)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found",
            )
        
        # Generate new tokens
        tokens = create_tokens(phone_number)
        
        return TokenResponse(
            access_token=tokens["access_token"],
            refresh_token=tokens["refresh_token"],
            expires_in=tokens["expires_in"],
        )
        
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token has expired",
        )
    except jwt.JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token",
        )
