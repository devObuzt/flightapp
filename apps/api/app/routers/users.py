from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User, UserPreferences
from app.schemas.user import (
    UserResponse,
    UpdateProfileRequest,
    UserPreferencesResponse,
    UpdatePreferencesRequest,
)

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/me", response_model=UserResponse)
async def get_profile(current_user: User = Depends(get_current_user)):
    return current_user


@router.patch("/me", response_model=UserResponse)
async def update_profile(
    body: UpdateProfileRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    for field, value in body.model_dump(exclude_none=True).items():
        setattr(current_user, field, value)
    return current_user


@router.get("/me/preferences", response_model=UserPreferencesResponse)
async def get_preferences(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(UserPreferences).where(UserPreferences.user_id == current_user.id)
    )
    prefs = result.scalar_one_or_none()
    if not prefs:
        prefs = UserPreferences(user_id=current_user.id)
        db.add(prefs)
        await db.flush()
    return prefs


@router.patch("/me/preferences", response_model=UserPreferencesResponse)
async def update_preferences(
    body: UpdatePreferencesRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(UserPreferences).where(UserPreferences.user_id == current_user.id)
    )
    prefs = result.scalar_one_or_none()
    if not prefs:
        prefs = UserPreferences(user_id=current_user.id)
        db.add(prefs)

    for field, value in body.model_dump(exclude_none=True).items():
        setattr(prefs, field, value)

    return prefs
