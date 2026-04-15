from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_
from jose import JWTError

from app.core.database import get_db
from app.core.redis import get_redis, RedisKeys
from app.core.security import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
    decode_refresh_token,
    generate_otp,
    OTP_TTL_SECONDS,
)
from app.core.config import settings
from app.core.dependencies import get_current_user
from app.models.user import User, UserSession, UserPreferences
from app.schemas.auth import (
    RegisterRequest,
    LoginRequest,
    OtpSendRequest,
    OtpVerifyRequest,
    RefreshRequest,
    TokenResponse,
    LogoutRequest,
)
from app.schemas.user import UserResponse

import hashlib
import uuid

router = APIRouter(prefix="/auth", tags=["auth"])


def _hash_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(body: RegisterRequest, db: AsyncSession = Depends(get_db)):
    if not body.email and not body.phone:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Either email or phone is required",
        )

    # Check uniqueness
    filters = []
    if body.email:
        filters.append(User.email == body.email)
    if body.phone:
        filters.append(User.phone == body.phone)

    result = await db.execute(select(User).where(or_(*filters)))
    if result.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="A user with this email or phone already exists",
        )

    user = User(
        full_name=body.full_name,
        email=body.email,
        phone=body.phone,
        hashed_password=hash_password(body.password),
        language=body.language,
        currency=body.currency,
    )
    db.add(user)
    await db.flush()  # get user.id

    # Create default preferences
    prefs = UserPreferences(user_id=user.id)
    db.add(prefs)

    # Issue tokens
    access_token = create_access_token(str(user.id))
    refresh_token = create_refresh_token(str(user.id))

    session = UserSession(
        user_id=user.id,
        refresh_token_hash=_hash_token(refresh_token),
        platform="web",
        expires_at=datetime.now(timezone.utc)
        + timedelta(days=settings.refresh_token_expire_days),
    )
    db.add(session)

    return TokenResponse(access_token=access_token, refresh_token=refresh_token)


@router.post("/login", response_model=TokenResponse)
async def login(body: LoginRequest, db: AsyncSession = Depends(get_db)):
    # Find user by email or phone
    identifier = body.identifier.strip()
    result = await db.execute(
        select(User).where(
            or_(User.email == identifier, User.phone == identifier)
        )
    )
    user = result.scalar_one_or_none()

    if not user or not user.hashed_password:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials",
        )

    if not verify_password(body.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials",
        )

    access_token = create_access_token(str(user.id))
    refresh_token = create_refresh_token(str(user.id))

    session = UserSession(
        user_id=user.id,
        refresh_token_hash=_hash_token(refresh_token),
        platform=body.platform,
        expires_at=datetime.now(timezone.utc)
        + timedelta(days=settings.refresh_token_expire_days),
    )
    db.add(session)

    return TokenResponse(access_token=access_token, refresh_token=refresh_token)


@router.post("/otp/send")
async def send_otp(body: OtpSendRequest, redis=Depends(get_redis)):
    otp = generate_otp()
    key = f"otp:{body.phone}"
    await redis.setex(key, OTP_TTL_SECONDS, otp)

    # TODO: send via Twilio SMS
    # For dev, log it (remove in prod)
    if settings.environment == "development":
        print(f"[DEV] OTP for {body.phone}: {otp}")

    return {"message": "OTP sent"}


@router.post("/otp/verify", response_model=TokenResponse)
async def verify_otp(
    body: OtpVerifyRequest,
    db: AsyncSession = Depends(get_db),
    redis=Depends(get_redis),
):
    key = f"otp:{body.phone}"
    stored_otp = await redis.get(key)

    if not stored_otp or stored_otp != body.code:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired OTP",
        )

    await redis.delete(key)

    # Get or create user by phone
    result = await db.execute(select(User).where(User.phone == body.phone))
    user = result.scalar_one_or_none()

    if not user:
        user = User(full_name="", phone=body.phone, is_verified=True)
        db.add(user)
        await db.flush()
        prefs = UserPreferences(user_id=user.id)
        db.add(prefs)
    else:
        user.is_verified = True

    access_token = create_access_token(str(user.id))
    refresh_token = create_refresh_token(str(user.id))

    session = UserSession(
        user_id=user.id,
        refresh_token_hash=_hash_token(refresh_token),
        platform="flutter_android",
        expires_at=datetime.now(timezone.utc)
        + timedelta(days=settings.refresh_token_expire_days),
    )
    db.add(session)

    return TokenResponse(access_token=access_token, refresh_token=refresh_token)


@router.post("/refresh", response_model=TokenResponse)
async def refresh_tokens(body: RefreshRequest, db: AsyncSession = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid or expired refresh token",
    )
    try:
        payload = decode_refresh_token(body.refresh_token)
        user_id: str = payload.get("sub")
        if not user_id:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    token_hash = _hash_token(body.refresh_token)
    result = await db.execute(
        select(UserSession).where(
            UserSession.user_id == user_id,
            UserSession.refresh_token_hash == token_hash,
        )
    )
    session = result.scalar_one_or_none()

    if not session or session.expires_at.replace(tzinfo=timezone.utc) < datetime.now(
        timezone.utc
    ):
        raise credentials_exception

    # Rotate: delete old, issue new
    await db.delete(session)

    new_access = create_access_token(user_id)
    new_refresh = create_refresh_token(user_id)

    new_session = UserSession(
        user_id=user_id,
        refresh_token_hash=_hash_token(new_refresh),
        platform=session.platform,
        expires_at=datetime.now(timezone.utc)
        + timedelta(days=settings.refresh_token_expire_days),
    )
    db.add(new_session)

    return TokenResponse(access_token=new_access, refresh_token=new_refresh)


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(
    body: LogoutRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    token_hash = _hash_token(body.refresh_token)
    result = await db.execute(
        select(UserSession).where(
            UserSession.user_id == current_user.id,
            UserSession.refresh_token_hash == token_hash,
        )
    )
    session = result.scalar_one_or_none()
    if session:
        await db.delete(session)


@router.get("/me", response_model=UserResponse)
async def me(current_user: User = Depends(get_current_user)):
    return current_user
