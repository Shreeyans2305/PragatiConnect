from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class SchemeBase(BaseModel):
    """Base scheme model."""
    name: str
    description: str
    category: str
    ministry: str
    benefit_amount: Optional[str] = None
    eligibility_criteria: Optional[List[str]] = None
    application_process: Optional[List[str]] = None
    deadline: Optional[datetime] = None
    is_active: bool = True


class SchemeCreate(SchemeBase):
    """Scheme creation request (admin)."""
    pass


class SchemeResponse(SchemeBase):
    """Scheme response."""
    id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class SchemeListResponse(BaseModel):
    """List of schemes response."""
    schemes: List[SchemeResponse]
    total: int
    page: int = 1
    page_size: int = 20


class SchemeQueryRequest(BaseModel):
    """Question about a scheme."""
    scheme_id: str
    question: str = Field(..., min_length=1, max_length=1000)
    language: str = Field(default="hi", pattern=r"^(en|hi|mr|ta|te|bn|gu|pa)$")


class SchemeQueryResponse(BaseModel):
    """Answer about a scheme."""
    answer: str
    scheme_name: str
    language: str


class EligibilityMatch(BaseModel):
    """Scheme eligibility match."""
    scheme: SchemeResponse
    match_score: float = Field(..., ge=0, le=1)
    match_reasons: List[str]
