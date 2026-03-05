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
ALLOWED_TYPES = [
    "image/jpeg",
    "image/png",
    "image/webp",
    "image/gif",
    "image/bmp",
    "image/tiff",
    "image/x-tiff",
    "image/svg+xml",
    "image/heif",
    "image/heic",
    "image/heif-sequence",  # Animated HEIF
    "image/heic-sequence",  # Animated HEIC
]


def compress_image(image_bytes: bytes, max_size: int = 500 * 1024) -> bytes:
    """Compress image to target size. Handles HEIF, HEIC, and other formats."""
    from PIL import ImageFile
    ImageFile.LOAD_TRUNCATED_IMAGES = True
    
    # Try to register HEIF support
    heif_supported = False
    try:
        import pillow_heif
        pillow_heif.register_heif_opener()
        heif_supported = True
    except ImportError:
        pass  # pillow-heif not installed, PIL will handle it if possible
    
    try:
        img = Image.open(io.BytesIO(image_bytes))
        img.load()  # Force load to catch any decoding issues early
    except Exception as e:
        # If image fails to open, return original bytes as fallback
        # This prevents crashes on unsupported formats
        if len(image_bytes) <= max_size:
            return image_bytes
        # If too large and can't be processed, raise error
        raise HTTPException(
            status_code=400,
            detail=f"Unable to process image: {str(e)}. Please try another image.",
        )
    
    try:
        # Convert to RGB if necessary
        if img.mode in ("RGBA", "P", "LA", "PA"):
            img = img.convert("RGB")
        
        # Resize if too large
        max_dimension = 1024
        if max(img.size) > max_dimension:
            ratio = max_dimension / max(img.size)
            new_size = tuple(int(dim * ratio) for dim in img.size)
            img = img.resize(new_size, Image.Resampling.LANCZOS)
        
        # Compress to JPEG
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
    except Exception as e:
        # Fallback: return original image if compression fails
        return image_bytes if len(image_bytes) <= max_size else image_bytes[:max_size]


@router.post("/estimate", response_model=PriceEstimateResponse)
async def estimate_price(
    image: UploadFile = File(...),
    language: str = Form(default="hi"),
    current_user: dict = Depends(get_current_user),
):
    """Analyze a product image and estimate its market price."""
    email = current_user["email"]
    
    # Validate file type (case-insensitive)
    content_type = image.content_type.lower() if image.content_type else ""
    
    # If content_type is empty, try to infer from filename
    if not content_type and image.filename:
        file_ext = image.filename.lower().split('.')[-1]
        ext_to_mime = {
            'jpg': 'image/jpeg',
            'jpeg': 'image/jpeg',
            'png': 'image/png',
            'gif': 'image/gif',
            'webp': 'image/webp',
            'bmp': 'image/bmp',
            'tiff': 'image/tiff',
            'tif': 'image/tiff',
            'svg': 'image/svg+xml',
            'heif': 'image/heif',
            'heic': 'image/heic',
            'heifs': 'image/heif-sequence',
            'heics': 'image/heic-sequence',
        }
        content_type = ext_to_mime.get(file_ext, '')
    
    allowed_types_lower = [t.lower() for t in ALLOWED_TYPES]
    if content_type not in allowed_types_lower:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid file type. Allowed: {', '.join(ALLOWED_TYPES)}. Received: {image.content_type or 'None (inferred: ' + content_type + ')'}",
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
    s3_key = s3_client.upload_image(compressed, email)
    
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
    # Handle materials - convert to list of dicts if needed
    materials = analysis.get("materials", [])
    if materials and isinstance(materials, list) and len(materials) > 0:
        # If materials are dicts, ensure they have material and confidence keys
        if isinstance(materials[0], dict):
            materials = [
                {
                    "material": m.get("material", m.get("name", str(m))),
                    "confidence": m.get("confidence", 0.5)
                }
                for m in materials
            ]
    else:
        materials = []
    
    estimate_data = {
        "product_category": analysis.get("product_category", "Unknown"),
        "materials": materials,
        "craftsmanship_score": analysis.get("craftsmanship_score", 5),
        "craftsmanship_description": analysis.get("craftsmanship_description", ""),
        "price_min": analysis.get("price_min", 0),
        "price_max": analysis.get("price_max", 0),
        "pricing_factors": analysis.get("pricing_factors", []),
        "selling_tips": analysis.get("selling_tips", []),
        "image_s3_key": s3_key,
    }
    
    # Save to database
    dynamodb.create_price_estimate(email, estimate_id, estimate_data)
    
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
    email = current_user["email"]
    estimates = dynamodb.get_user_estimates(email, limit)
    
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
    email = current_user["email"]
    estimate = dynamodb.get_estimate(email, estimate_id)
    
    if not estimate:
        raise HTTPException(status_code=404, detail="Estimate not found")
    
    # Add image URL
    if estimate.get("image_s3_key"):
        estimate["image_url"] = s3_client.get_presigned_url(estimate["image_s3_key"])
    
    return estimate
