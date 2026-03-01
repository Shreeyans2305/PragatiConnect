from fastapi import APIRouter, Depends, HTTPException, status

from app.dependencies import get_current_user
from app.db.dynamodb import dynamodb
from app.models.user import UserProfile, UserUpdate

router = APIRouter()


@router.get("", response_model=UserProfile)
async def get_profile(current_user: dict = Depends(get_current_user)):
    """Get current user's profile."""
    return UserProfile(**current_user)


@router.put("", response_model=UserProfile)
async def update_profile(
    updates: UserUpdate,
    current_user: dict = Depends(get_current_user),
):
    """Update current user's profile."""
    phone_number = current_user["phone_number"]
    
    # Filter out None values
    update_data = {k: v for k, v in updates.model_dump().items() if v is not None}
    
    if not update_data:
        return UserProfile(**current_user)
    
    updated_user = dynamodb.update_user(phone_number, update_data)
    return UserProfile(**updated_user)


@router.delete("", status_code=status.HTTP_204_NO_CONTENT)
async def delete_profile(current_user: dict = Depends(get_current_user)):
    """Delete current user's account."""
    phone_number = current_user["phone_number"]
    dynamodb.delete_user(phone_number)
    return None
