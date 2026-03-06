from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
import io
from PIL import Image

from app.dependencies import get_current_user
from app.db.dynamodb import dynamodb
from app.db.s3 import s3_client
from app.models.user import UserProfile, UserUpdate

router = APIRouter()


@router.get("", response_model=UserProfile)
async def get_profile(current_user: dict = Depends(get_current_user)):
    """Get current user's profile."""
    data = dict(current_user)
    # Regenerate a fresh presigned URL on every fetch (avoids expiry issues)
    s3_key = data.get("profile_photo_s3_key")
    if s3_key:
        data["profile_photo_url"] = s3_client.get_presigned_url(s3_key, expires_in=7 * 24 * 3600)
    return UserProfile(**data)


@router.put("", response_model=UserProfile)
async def update_profile(
    updates: UserUpdate,
    current_user: dict = Depends(get_current_user),
):
    """Update current user's profile."""
    email = current_user["email"]

    # Filter out None values
    update_data = {k: v for k, v in updates.model_dump().items() if v is not None}

    if not update_data:
        return UserProfile(**current_user)

    updated_user = dynamodb.update_user(email, update_data)
    return UserProfile(**updated_user)


@router.post("/photo", response_model=UserProfile)
async def upload_profile_photo(
    photo: UploadFile = File(...),
    current_user: dict = Depends(get_current_user),
):
    """Upload a profile photo and save the URL to the user's profile."""
    email = current_user["email"]

    # Read and compress to ≤ 300 KB
    raw = await photo.read()
    try:
        img = Image.open(io.BytesIO(raw))
        if img.mode in ("RGBA", "P", "LA", "PA"):
            img = img.convert("RGB")
        max_dim = 512
        if max(img.size) > max_dim:
            ratio = max_dim / max(img.size)
            img = img.resize(
                (int(img.size[0] * ratio), int(img.size[1] * ratio)),
                Image.Resampling.LANCZOS,
            )
        buf = io.BytesIO()
        quality = 85
        while quality >= 30:
            buf.seek(0)
            buf.truncate()
            img.save(buf, format="JPEG", quality=quality, optimize=True)
            if buf.tell() <= 300 * 1024:
                break
            quality -= 10
        compressed = buf.getvalue()
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid image: {e}")

    # Upload under a profile_photos/ prefix so it stays separate from price-estimator images
    safe_email = (
        email.replace("@", "_").replace(".", "_").replace("+", "").replace("/", "_")
    )
    import uuid as _uuid
    key = f"profile_photos/{safe_email}/{_uuid.uuid4()}.jpg"
    s3_client.client.put_object(
        Bucket=s3_client.bucket,
        Key=key,
        Body=compressed,
        ContentType="image/jpeg",
    )

    # Store the S3 key in DynamoDB (presigned URL is generated on demand)
    updated_user = dynamodb.update_user(email, {"profile_photo_s3_key": key})

    # Return the updated profile with a fresh presigned URL (7-day expiry)
    presigned_url = s3_client.get_presigned_url(key, expires_in=7 * 24 * 3600)
    updated_user["profile_photo_url"] = presigned_url
    return UserProfile(**updated_user)


@router.delete("", status_code=status.HTTP_204_NO_CONTENT)
async def delete_profile(current_user: dict = Depends(get_current_user)):
    """Delete current user's account."""
    email = current_user["email"]
    dynamodb.delete_user(email)
    return None
