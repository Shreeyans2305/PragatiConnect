from fastapi import APIRouter, Depends, Query
from typing import Optional, List
import uuid

from app.dependencies import get_current_user, get_optional_user
from app.services.bedrock_service import bedrock_service
from app.services.prompts import SCHEME_ASSISTANT_PROMPT
from app.models.scheme import (
    SchemeResponse,
    SchemeQueryRequest,
    SchemeQueryResponse,
)

router = APIRouter()

# Mock scheme data (in production, this would come from Knowledge Base)
MOCK_SCHEMES = [
    {
        "id": "pm-kisan",
        "name": "PM-KISAN",
        "description": "Direct income support of ₹6,000 per year to farmer families",
        "category": "Agriculture",
        "ministry": "Ministry of Agriculture & Farmers Welfare",
        "benefit_amount": "₹6,000 per year",
        "eligibility_criteria": [
            "Land-owning farmer family",
            "Valid Aadhaar card",
            "Bank account linked to Aadhaar",
        ],
        "application_process": [
            "Visit nearest CSC or bank",
            "Submit land documents",
            "Link Aadhaar with bank account",
            "Register on PM-KISAN portal",
        ],
        "is_active": True,
    },
    {
        "id": "pmay",
        "name": "Pradhan Mantri Awas Yojana (PMAY)",
        "description": "Housing subsidy for first-time home buyers and homeless families",
        "category": "Housing",
        "ministry": "Ministry of Housing and Urban Affairs",
        "benefit_amount": "Up to ₹2.67 lakh subsidy",
        "eligibility_criteria": [
            "Annual household income up to ₹18 lakh",
            "No pucca house in family's name",
            "First-time home buyer",
        ],
        "application_process": [
            "Apply through bank or housing finance company",
            "Submit income proof and ID",
            "Property documents verification",
            "Subsidy credited to loan account",
        ],
        "is_active": True,
    },
    {
        "id": "vishwakarma",
        "name": "PM Vishwakarma Scheme",
        "description": "Support for traditional artisans and craftspeople",
        "category": "Business",
        "ministry": "Ministry of Micro, Small & Medium Enterprises",
        "benefit_amount": "₹15,000 toolkit + ₹3 lakh loan",
        "eligibility_criteria": [
            "Traditional artisan or craftsperson",
            "Working with hands and tools",
            "Age 18 years or above",
            "Not in government service",
        ],
        "application_process": [
            "Register on PM Vishwakarma portal",
            "Verify through Gram Panchayat/ULB",
            "Complete skill training",
            "Receive toolkit and loan",
        ],
        "is_active": True,
    },
    {
        "id": "mudra",
        "name": "MUDRA Loan (PMMY)",
        "description": "Collateral-free loans for micro and small enterprises",
        "category": "Business",
        "ministry": "Ministry of Finance",
        "benefit_amount": "Up to ₹10 lakh loan",
        "eligibility_criteria": [
            "Non-corporate, non-farm small business",
            "Manufacturing, trading, or service sector",
            "Valid ID and address proof",
        ],
        "application_process": [
            "Approach any bank, NBFC, or MFI",
            "Submit business plan",
            "KYC documents verification",
            "Loan sanctioned without collateral",
        ],
        "is_active": True,
    },
    {
        "id": "pm-svanidhi",
        "name": "PM SVANidhi",
        "description": "Working capital loan for street vendors",
        "category": "Business",
        "ministry": "Ministry of Housing and Urban Affairs",
        "benefit_amount": "₹10,000 to ₹50,000 loan",
        "eligibility_criteria": [
            "Street vendor with vending certificate or ID",
            "Operating before 24 March 2020",
            "Surveyed by urban local body",
        ],
        "application_process": [
            "Apply on PM SVANidhi portal",
            "Submit vendor certificate/ID",
            "Digital payment incentive on repayment",
            "Enhanced loan on timely repayment",
        ],
        "is_active": True,
    },
]


def get_language_name(code: str) -> str:
    """Get full language name from code."""
    languages = {
        "en": "English",
        "hi": "Hindi",
        "mr": "Marathi",
        "ta": "Tamil",
        "te": "Telugu",
        "bn": "Bengali",
    }
    return languages.get(code, "Hindi")


@router.get("")
async def get_schemes(
    category: Optional[str] = Query(None),
    search: Optional[str] = Query(None),
    current_user: Optional[dict] = Depends(get_optional_user),
):
    """Get list of government schemes."""
    schemes = MOCK_SCHEMES.copy()
    
    # Filter by category
    if category:
        schemes = [s for s in schemes if s["category"].lower() == category.lower()]
    
    # Search filter
    if search:
        search_lower = search.lower()
        schemes = [
            s for s in schemes
            if search_lower in s["name"].lower()
            or search_lower in s["description"].lower()
        ]
    
    return {
        "schemes": schemes,
        "total": len(schemes),
    }


@router.get("/eligible")
async def get_eligible_schemes(
    current_user: dict = Depends(get_current_user),
):
    """Get schemes user may be eligible for based on their profile."""
    user_trade = current_user.get("primary_trade", "").lower()
    
    eligible_schemes = []
    
    for scheme in MOCK_SCHEMES:
        match_score = 0.5  # Base score
        reasons = []
        
        # Trade-based matching
        if user_trade in ["farmer", "agriculture"]:
            if scheme["category"] == "Agriculture":
                match_score += 0.3
                reasons.append("Matches your trade as a farmer")
        
        if user_trade in ["carpenter", "weaver", "potter", "artisan", "tailor"]:
            if scheme["id"] == "vishwakarma":
                match_score += 0.4
                reasons.append("Designed for traditional artisans like you")
        
        if user_trade in ["vendor", "small_business"]:
            if scheme["id"] in ["pm-svanidhi", "mudra"]:
                match_score += 0.3
                reasons.append("Supports small businesses and vendors")
        
        # Everyone can benefit from housing
        if scheme["category"] == "Housing":
            reasons.append("Housing support available for all eligible families")
        
        if reasons:
            eligible_schemes.append({
                "scheme": scheme,
                "match_score": min(match_score, 1.0),
                "match_reasons": reasons,
            })
    
    # Sort by match score
    eligible_schemes.sort(key=lambda x: x["match_score"], reverse=True)
    
    return {"schemes": eligible_schemes}


@router.get("/{scheme_id}")
async def get_scheme_details(
    scheme_id: str,
    current_user: Optional[dict] = Depends(get_optional_user),
):
    """Get detailed information about a scheme."""
    scheme = next((s for s in MOCK_SCHEMES if s["id"] == scheme_id), None)
    
    if not scheme:
        return {"error": "Scheme not found"}
    
    return scheme


@router.post("/query", response_model=SchemeQueryResponse)
async def query_scheme(
    request: SchemeQueryRequest,
    current_user: dict = Depends(get_current_user),
):
    """Ask a question about a specific scheme."""
    scheme = next((s for s in MOCK_SCHEMES if s["id"] == request.scheme_id), None)
    
    if not scheme:
        return SchemeQueryResponse(
            answer="I couldn't find that scheme. Please check the scheme name.",
            scheme_name="Unknown",
            language=request.language,
        )
    
    # Build context from scheme data
    scheme_context = f"""
Scheme: {scheme['name']}
Description: {scheme['description']}
Ministry: {scheme['ministry']}
Benefits: {scheme['benefit_amount']}
Eligibility: {', '.join(scheme.get('eligibility_criteria', []))}
Application Process: {', '.join(scheme.get('application_process', []))}
"""
    
    system_prompt = SCHEME_ASSISTANT_PROMPT.format(
        user_trade=current_user.get("primary_trade", "worker"),
        user_location=current_user.get("location", "India"),
        user_state=current_user.get("state", ""),
        language=get_language_name(request.language),
    )
    
    full_prompt = f"""
Context about the scheme:
{scheme_context}

User's question: {request.question}

Please answer the question based on the scheme information provided. Be helpful and concise.
"""
    
    response_text = await bedrock_service.generate_response(
        prompt=full_prompt,
        system_prompt=system_prompt,
        max_tokens=512,
    )
    
    return SchemeQueryResponse(
        answer=response_text,
        scheme_name=scheme["name"],
        language=request.language,
    )
