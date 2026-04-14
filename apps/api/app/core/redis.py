from redis.asyncio import Redis, from_url
from app.core.config import settings

_redis: Redis | None = None


async def get_redis() -> Redis:
    global _redis
    if _redis is None:
        _redis = await from_url(
            settings.redis_url,
            encoding="utf-8",
            decode_responses=True,
        )
    return _redis


async def close_redis() -> None:
    global _redis
    if _redis is not None:
        await _redis.aclose()
        _redis = None


# ─── Helpers ──────────────────────────────────────────────

class RedisKeys:
    @staticmethod
    def session_messages(session_id: str) -> str:
        return f"session:{session_id}:messages"

    @staticmethod
    def session_state(session_id: str) -> str:
        return f"session:{session_id}:state"

    @staticmethod
    def user_rate_limit(user_id: str, endpoint: str) -> str:
        return f"user:{user_id}:ratelimit:{endpoint}"

    @staticmethod
    def flight_offer(offer_id: str) -> str:
        return f"flight:offer:{offer_id}"

    @staticmethod
    def amadeus_token() -> str:
        return "amadeus:access_token"

    @staticmethod
    def booking_draft(session_id: str) -> str:
        return f"booking:draft:{session_id}"

    @staticmethod
    def voice_stream(session_id: str) -> str:
        return f"voice:stream:{session_id}"
