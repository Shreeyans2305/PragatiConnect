from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException
from typing import Optional
import uuid
from datetime import datetime
from PIL import Image
import io

from app.dependencies import get_current_user
from app.db.dynamodb import dynamodb
from app.db.s3 import s3_client
from app.services.bedrock_service import bedrock_service
from app.services.prompts import PRICE_ESTIMATOR_PROMPT
from app.models.price_estimate import (
    PriceEstimateResponse,
    PriceHistoryResponse,
    PriceEstimateHistory,
)

router = APIRouter()

MAX_IMAGE_SIZE = 5 * 1024 * 1024  # 5MB
ALLOWED_TYPES = ["image/jpeg", "image/png", "image/webp"]


def compress_image(image_bytes: bytes, max_size: int = 500 * 1024) -> bytes:
    """Compress image to target size."""
    img = Image.open(io.BytesIO(image_bytes))
    
    # Convert to RGB if necessary
    if img.mode in ("RGBA", "P"):
        img = img.convert("RGB")
    
    # Resize if too large
    max_dimension = 1024
    if max(img.size) > max_dimension:
        ratio = max_dimension / max(img.size)
        new_size = tuple(int(dim * ratio) for dim in img.size)
        img = img.resize(new_size, Image.Resampling.LANCZOS)
    
    # Compress
    output = io.BytesIO()
    quality = 85
    while quality > 20:
        output.seek(0)
        output.truncate()
        img.save(output, format="JPEG", quality=quality, optimize=True)
        if output.tell() <= max_size:
            break
        quality -= 10
    
    return output.getvalue()


@router.post("/estimate", response_model=PriceEstimateResponse)
async def estimate_price(
    image: UploadFile = File(...),
    language: str = Form(default="hi"),
    current_user: dict = Depends(get_current_user),
):
    """Analyze a product image and estimate its market price."""
    phone = current_user["phone_number"]
    
    # Validate file type
    if image.content_type not in ALLOWED_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid file type. Allowed: {', '.join(ALLOWED_TYPES)}",
        )
    
    # Read image
    image_bytes = await image.read()
    
    # Check size
    if len(image_bytes) > MAX_IMAGE_SIZE:
        raise HTTPException(
            status_code=400,
            detail=f"Image too large. Maximum size: {MAX_IMAGE_SIZE // (1024*1024)}MB",
        )
    
    # Compress image
    compressed = compress_image(image_bytes)
    
    # Upload to S3
    s3_key = s3_client.upload_image(compressed, phone)
    
    # Build prompt
    prompt = PRICE_ESTIMATOR_PROMPT.format(
        user_trade=current_user.get("primary_trade", "artisan"),
        user_location=current_user.get("location", "India"),
        user_state=current_user.get("state", ""),
    )
    
    # Analyze with Bedrock
    try:
        analysis = await bedrock_service.analyze_image(
            image_bytes=compressed,
            prompt="Analyze this product image and provide price estimation.",
            system_prompt=prompt,
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to analyze image: {str(e)}",
        )
    
    # Generate estimate ID
    estimate_id = str(uuid.uuid4())
    
    # Extract data from analysis
    estimate_data = {
        "product_category": analysis.get("product_category", "Unknown"),
        "materials": analysis.get("materials", []),
        "craftsmanship_score": analysis.get("craftsmanship_score", 5),
        "craftsmanship_description": analysis.get("craftsmanship_description", ""),
        "price_min": analysis.get("price_min", 0),
        "price_max": analysis.get("price_max", 0),
        "pricing_factors": analysis.get("pricing_factors", []),
        "selling_tips": analysis.get("selling_tips", []),
        "image_s3_key": s3_key,
    }
    
    # Save to database
    dynamodb.create_price_estimate(phone, estimate_id, estimate_data)
    
    # Get presigned URL for image
    image_url = s3_client.get_presigned_url(s3_key)
    
    return PriceEstimateResponse(
        estimate_id=estimate_id,
        product_category=estimate_data["product_category"],
        materials=estimate_data["materials"],
        craftsmanship_score=estimate_data["craftsmanship_score"],
        craftsmanship_description=estimate_data["craftsmanship_description"],
        price_min=estimate_data["price_min"],
        price_max=estimate_data["price_max"],
        currency="INR",
        pricing_factors=estimate_data["pricing_factors"],
        selling_tips=estimate_data["selling_tips"],
        image_url=image_url,
        created_at=datetime.utcnow(),
    )


@router.get("/estimates", response_model=PriceHistoryResponse)
async def get_estimates(
    current_user: dict = Depends(get_current_user),
    limit: int = 10,
):
    """Get user's price estimate history."""
    phone = current_user["phone_number"]
    estimates = dynamodb.get_user_estimates(phone, limit)
    
    history = []
    for est in estimates:
        thumbnail_url = None
        if est.get("image_s3_key"):
            thumbnail_url = s3_client.get_presigned_url(est["image_s3_key"])
        
        history.append(
            PriceEstimateHistory(
                estimate_id=est["estimate_id"],
                product_category=est.get("product_category", "Unknown"),
                price_min=est.get("price_min", 0),
                price_max=est.get("price_max", 0),
                thumbnail_url=thumbnail_url,
                created_at=datetime.fromisoformat(est["created_at"]),
            )
        )
    
    return PriceHistoryResponse(estimates=history, total=len(history))


@router.get("/estimates/{estimate_id}")
async def get_estimate(
    estimate_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Get specific price estimate details."""
    phone = current_user["phone_number"]
    estimate = dynamodb.get_estimate(phone, estimate_id)
    
    if not estimate:
        raise HTTPException(status_code=404, detail="Estimate not found")
    
    # Add image URL
    if estimate.get("image_s3_key"):
        estimate["image_url"] = s3_client.get_presigned_url(estimate["image_s3_key"])
    
    return estimate
