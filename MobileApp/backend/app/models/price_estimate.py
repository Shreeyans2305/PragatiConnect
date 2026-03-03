from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class PriceEstimateRequest(BaseModel):
    """Price estimation request metadata."""
    language: str = Field(default="hi", pattern=r"^(en|hi|mr|ta|te|bn)$")


class MaterialAnalysis(BaseModel):
    """Material analysis from image."""
    material: str
    confidence: float = Field(..., ge=0, le=1)


class PriceEstimateResponse(BaseModel):
    """Price estimation response."""
    estimate_id: str
    product_category: str
    materials: List[MaterialAnalysis]
    craftsmanship_score: int = Field(..., ge=1, le=10)
    craftsmanship_description: str
    price_min: int
    price_max: int
    currency: str = "INR"
    pricing_factors: List[str]
    selling_tips: List[str]
    image_url: Optional[str] = None
    created_at: datetime


class PriceEstimateHistory(BaseModel):
    """Price estimate history item."""
    estimate_id: str
    product_category: str
    price_min: int
    price_max: int
    thumbnail_url: Optional[str] = None
    created_at: datetime


class PriceHistoryResponse(BaseModel):
    """Price estimate history response."""
    estimates: List[PriceEstimateHistory]
    total: int
