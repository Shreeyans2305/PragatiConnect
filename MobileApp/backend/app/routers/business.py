from fastapi import APIRouter, Depends
from pydantic import BaseModel
from typing import Optional

from app.dependencies import get_current_user
from app.services.bedrock_service import bedrock_service
from app.services.prompts import BUSINESS_PROFILE_PROMPT

router = APIRouter()


class BusinessProfileRequest(BaseModel):
    """Request for business profile generation."""
    business_name: str
    trade: str
    location: Optional[str] = None
    experience_years: int
    specialties: Optional[str] = None
    target_customers: Optional[str] = None
    language: str = "hi"


class BusinessProfileResponse(BaseModel):
    """Generated business profile."""
    content: str
    language: str


def get_language_name(code: str) -> str:
    """Get full language name from code."""
    languages = {
        "en": "English",
        "hi": "Hindi",
        "mr": "Marathi",
        "ta": "Tamil",
        "te": "Telugu",
        "bn": "Bengali",
        "gu": "Gujarati",
        "pa": "Punjabi",
    }
    return languages.get(code, "English")


@router.post("/profile-generator", response_model=BusinessProfileResponse)
async def generate_business_profile(
    request: BusinessProfileRequest,
    current_user: dict = Depends(get_current_user),
):
    """Generate a professional business profile and marketing content."""
    
    system_prompt = BUSINESS_PROFILE_PROMPT.format(
        business_name=request.business_name,
        trade=request.trade,
        location=(request.location or current_user.get("location") or "Not specified"),
        experience=f"{request.experience_years} years",
        specialties=request.specialties or "General services",
        target_customers=request.target_customers or "Local customers",
        language=get_language_name(request.language),
    )
    
    prompt = f"""Generate a complete business profile for:

Business Name: {request.business_name}
Trade/Service: {request.trade}
Location: {request.location or current_user.get('location', 'Not specified')}
Experience: {request.experience_years} years
Specialties: {request.specialties or 'General'}
Target Customers: {request.target_customers or 'Local community'}

Please create professional content including business description, tagline, social media bio, service list, and marketing messages."""
    
    response_text = await bedrock_service.generate_response(
        prompt=prompt,
        system_prompt=system_prompt,
        max_tokens=2048,
    )
    
    return BusinessProfileResponse(
        content=response_text,
        language=request.language,
    )
