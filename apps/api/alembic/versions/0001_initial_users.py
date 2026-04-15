"""initial users tables

Revision ID: 0001
Revises:
Create Date: 2026-03-14
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID, JSONB, ARRAY

revision = "0001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    # ─── users ────────────────────────────────────────────
    op.create_table(
        "users",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("email", sa.String(255), unique=True, nullable=True),
        sa.Column("phone", sa.String(50), unique=True, nullable=True),
        sa.Column("full_name", sa.String(255), nullable=False, server_default=""),
        sa.Column("hashed_password", sa.Text, nullable=True),
        sa.Column("avatar_url", sa.Text, nullable=True),
        sa.Column("language", sa.String(10), nullable=False, server_default="en"),
        sa.Column("currency", sa.String(10), nullable=False, server_default="USD"),
        sa.Column("country", sa.String(10), nullable=True),
        sa.Column("is_verified", sa.Boolean, nullable=False, server_default="false"),
        sa.Column("created_at", sa.TIMESTAMP(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.TIMESTAMP(timezone=True), server_default=sa.text("now()"), nullable=False),
    )
    op.create_index("ix_users_email", "users", ["email"])
    op.create_index("ix_users_phone", "users", ["phone"])

    # ─── user_sessions ────────────────────────────────────
    op.create_table(
        "user_sessions",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("user_id", UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("refresh_token_hash", sa.Text, nullable=False),
        sa.Column("device_info", JSONB, nullable=True),
        sa.Column("platform", sa.String(50), nullable=True),
        sa.Column("last_used_at", sa.TIMESTAMP(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("expires_at", sa.TIMESTAMP(timezone=True), nullable=False),
        sa.Column("created_at", sa.TIMESTAMP(timezone=True), server_default=sa.text("now()"), nullable=False),
    )
    op.create_index("ix_user_sessions_user_id", "user_sessions", ["user_id"])
    op.create_index("ix_user_sessions_token_hash", "user_sessions", ["refresh_token_hash"])

    # ─── user_preferences ─────────────────────────────────
    op.create_table(
        "user_preferences",
        sa.Column("user_id", UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), primary_key=True),
        sa.Column("preferred_airlines", ARRAY(sa.String), nullable=True),
        sa.Column("preferred_cabin", sa.String(30), nullable=False, server_default="ECONOMY"),
        sa.Column("preferred_seat", sa.String(20), nullable=False, server_default="WINDOW"),
        sa.Column("frequent_flyer_nos", JSONB, nullable=True),
        sa.Column("travel_document", JSONB, nullable=True),
        sa.Column("notifications_push", sa.Boolean, nullable=False, server_default="true"),
        sa.Column("notifications_email", sa.Boolean, nullable=False, server_default="true"),
        sa.Column("voice_enabled", sa.Boolean, nullable=False, server_default="true"),
        sa.Column("updated_at", sa.TIMESTAMP(timezone=True), server_default=sa.text("now()"), nullable=False),
    )

    # ─── user_travel_memory ───────────────────────────────
    op.create_table(
        "user_travel_memory",
        sa.Column("user_id", UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), primary_key=True),
        sa.Column("summary", sa.Text, nullable=True),
        sa.Column("known_passengers", JSONB, nullable=True),
        sa.Column("frequent_routes", ARRAY(sa.String), nullable=True),
        sa.Column("last_updated", sa.TIMESTAMP(timezone=True), server_default=sa.text("now()"), nullable=False),
    )


def downgrade() -> None:
    op.drop_table("user_travel_memory")
    op.drop_table("user_preferences")
    op.drop_table("user_sessions")
    op.drop_table("users")
