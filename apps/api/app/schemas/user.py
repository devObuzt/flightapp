import uuid
from datetime import datetime
from pydantic import BaseModel, EmailStr


class UserResponse(BaseModel):
    id: uuid.UUID
    email: str | None
    phone: str | None
    full_name: str
    avatar_url: str | None
    language: str
    currency: str
    country: str | None
    is_verified: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class UpdateProfileRequest(BaseModel):
    full_name: str | None = None
    language: str | None = None
    currency: str | None = None
    country: str | None = None
    avatar_url: str | None = None


class UserPreferencesResponse(BaseModel):
    preferred_airlines: list[str] | None
    preferred_cabin: str
    preferred_seat: str
    frequent_flyer_nos: dict | None
    notifications_push: bool
    notifications_email: bool
    voice_enabled: bool

    model_config = {"from_attributes": True}


class UpdatePreferencesRequest(BaseModel):
    preferred_airlines: list[str] | None = None
    preferred_cabin: str | None = None
    preferred_seat: str | None = None
    frequent_flyer_nos: dict | None = None
    notifications_push: bool | None = None
    notifications_email: bool | None = None
    voice_enabled: bool | None = None
