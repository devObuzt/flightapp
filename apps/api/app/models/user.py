import uuid
from datetime import datetime, timezone

from sqlalchemy import String, Boolean, Integer, ForeignKey, Text, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID, JSONB, ARRAY

from app.core.database import Base


def utcnow():
    return datetime.now(timezone.utc)


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    email: Mapped[str | None] = mapped_column(String(255), unique=True, nullable=True)
    phone: Mapped[str | None] = mapped_column(String(50), unique=True, nullable=True)
    full_name: Mapped[str] = mapped_column(String(255), nullable=False)
    hashed_password: Mapped[str | None] = mapped_column(Text, nullable=True)
    avatar_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    language: Mapped[str] = mapped_column(String(10), default="en")   # ISO 639-1
    currency: Mapped[str] = mapped_column(String(10), default="USD")  # ISO 4217
    country: Mapped[str | None] = mapped_column(String(10), nullable=True)
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(default=utcnow, onupdate=utcnow)

    # Relationships
    sessions: Mapped[list["UserSession"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
    preferences: Mapped["UserPreferences | None"] = relationship(
        back_populates="user", uselist=False, cascade="all, delete-orphan"
    )
    travel_memory: Mapped["UserTravelMemory | None"] = relationship(
        back_populates="user", uselist=False, cascade="all, delete-orphan"
    )


class UserSession(Base):
    __tablename__ = "user_sessions"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    refresh_token_hash: Mapped[str] = mapped_column(Text, nullable=False)
    device_info: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    platform: Mapped[str | None] = mapped_column(
        String(50), nullable=True
    )  # flutter_ios | flutter_android | web
    last_used_at: Mapped[datetime] = mapped_column(default=utcnow)
    expires_at: Mapped[datetime] = mapped_column(nullable=False)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)

    user: Mapped["User"] = relationship(back_populates="sessions")


class UserPreferences(Base):
    __tablename__ = "user_preferences"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    preferred_airlines: Mapped[list[str] | None] = mapped_column(
        ARRAY(String), nullable=True
    )
    preferred_cabin: Mapped[str] = mapped_column(String(30), default="ECONOMY")
    preferred_seat: Mapped[str] = mapped_column(String(20), default="WINDOW")
    frequent_flyer_nos: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    travel_document: Mapped[dict | None] = mapped_column(
        JSONB, nullable=True
    )  # encrypted at app layer
    notifications_push: Mapped[bool] = mapped_column(Boolean, default=True)
    notifications_email: Mapped[bool] = mapped_column(Boolean, default=True)
    voice_enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    updated_at: Mapped[datetime] = mapped_column(default=utcnow, onupdate=utcnow)

    user: Mapped["User"] = relationship(back_populates="preferences")


class UserTravelMemory(Base):
    __tablename__ = "user_travel_memory"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    summary: Mapped[str | None] = mapped_column(Text, nullable=True)
    known_passengers: Mapped[list | None] = mapped_column(JSONB, nullable=True)
    frequent_routes: Mapped[list[str] | None] = mapped_column(
        ARRAY(String), nullable=True
    )
    last_updated: Mapped[datetime] = mapped_column(default=utcnow, onupdate=utcnow)

    user: Mapped["User"] = relationship(back_populates="travel_memory")
