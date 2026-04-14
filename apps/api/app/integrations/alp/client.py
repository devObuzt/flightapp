"""
ALP Flight Provider Client
--------------------------
Handles:
  - OAuth2 client-credentials token fetch & refresh
  - Token caching in Redis (falls back to in-memory)
  - All requests to ALP Listener API (listener.php)
"""
import time
import asyncio
import logging
from typing import Any

import httpx

from app.core.config import settings
from app.core.redis import get_redis
from app.integrations.alp.schemas import (
    ALPToken,
    ALPSearchRequest,
    ALPSearchResponse,
    ALPOffer,
    ALPSegment,
    ALPBookingRequest,
    ALPBookingResponse,
    ALPPassenger,
)

logger = logging.getLogger(__name__)

# In-memory fallback when Redis is not available
_token_cache: dict[str, Any] = {}
_token_lock = asyncio.Lock()

REDIS_TOKEN_KEY = "alp:access_token"
REDIS_TOKEN_TTL = 270  # refresh 30 sec before ALP's 300-sec expiry


# ─── Token Management ─────────────────────────────────────

async def _fetch_token() -> str:
    """Fetch a fresh OAuth2 token from ALP Keycloak."""
    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.post(
            settings.alp_token_url,
            data={
                "grant_type": "client_credentials",
                "client_id": settings.alp_client_id,
                "client_secret": settings.alp_client_secret,
            },
            headers={"Content-Type": "application/x-www-form-urlencoded"},
        )
        resp.raise_for_status()
        data = resp.json()
        return data["access_token"]


async def get_alp_token() -> str:
    """
    Return a valid ALP bearer token.
    Checks Redis → in-memory cache → fetches fresh one.
    """
    async with _token_lock:
        # 1. Try Redis
        redis = await get_redis()
        if redis:
            cached = await redis.get(REDIS_TOKEN_KEY)
            if cached:
                return cached

        # 2. Try in-memory fallback
        if _token_cache.get("token") and _token_cache.get("expires_at", 0) > time.time():
            return _token_cache["token"]

        # 3. Fetch fresh token
        logger.info("Fetching fresh ALP token")
        token = await _fetch_token()

        # Store in Redis
        if redis:
            await redis.setex(REDIS_TOKEN_KEY, REDIS_TOKEN_TTL, token)

        # Store in-memory fallback
        _token_cache["token"] = token
        _token_cache["expires_at"] = time.time() + REDIS_TOKEN_TTL

        return token


# ─── Base Listener Request ────────────────────────────────

async def _alp_request(payload: dict[str, Any]) -> dict[str, Any]:
    """
    Send a JSON request to ALP Listener endpoint.
    Automatically attaches bearer token.
    """
    token = await get_alp_token()
    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.post(
            settings.alp_listener_url,
            json=payload,
            headers={
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json",
                "Accept": "application/json",
            },
        )
        resp.raise_for_status()
        return resp.json()


# ─── Flight Search ────────────────────────────────────────

def _build_search_payload(req: ALPSearchRequest) -> dict[str, Any]:
    pax = [{"type": p.type, "count": p.count} for p in req.passengers]
    payload: dict[str, Any] = {
        "action": "search",
        "origin": req.origin.upper(),
        "destination": req.destination.upper(),
        "departure_date": req.departure_date,
        "passengers": pax,
        "cabin": req.cabin,
    }
    if req.return_date:
        payload["return_date"] = req.return_date
        payload["trip_type"] = "RT"
    else:
        payload["trip_type"] = "OW"
    return payload


def _parse_search_response(raw: dict[str, Any]) -> ALPSearchResponse:
    """Map ALP raw JSON → ALPSearchResponse."""
    offers: list[ALPOffer] = []

    for item in raw.get("offers", raw.get("results", [])):
        segments = []
        for seg in item.get("segments", item.get("legs", [])):
            segments.append(ALPSegment(
                origin=seg.get("origin", seg.get("from", "")),
                destination=seg.get("destination", seg.get("to", "")),
                departure_datetime=seg.get("departure", seg.get("dep_datetime", "")),
                arrival_datetime=seg.get("arrival", seg.get("arr_datetime", "")),
                carrier=seg.get("carrier", seg.get("airline", "")),
                flight_number=seg.get("flight_number", seg.get("flight_no", "")),
                cabin=seg.get("cabin", seg.get("class", "ECONOMY")),
                duration_minutes=int(seg.get("duration", 0)),
                stops=int(seg.get("stops", 0)),
            ))

        offers.append(ALPOffer(
            offer_id=str(item.get("offer_id", item.get("id", ""))),
            price_total=float(item.get("price", item.get("total_price", 0))),
            currency=item.get("currency", "USD"),
            segments=segments,
            refundable=bool(item.get("refundable", False)),
            raw=item,
        ))

    return ALPSearchResponse(
        offers=offers,
        search_id=str(raw.get("search_id", "")),
    )


async def search_flights(req: ALPSearchRequest) -> ALPSearchResponse:
    """Search for available flights via ALP."""
    payload = _build_search_payload(req)
    logger.info("ALP search: %s → %s on %s", req.origin, req.destination, req.departure_date)
    raw = await _alp_request(payload)
    return _parse_search_response(raw)


# ─── Booking ──────────────────────────────────────────────

def _build_booking_payload(req: ALPBookingRequest) -> dict[str, Any]:
    passengers = []
    for p in req.passengers:
        pax: dict[str, Any] = {
            "type": p.type,
            "first_name": p.first_name,
            "last_name": p.last_name,
            "date_of_birth": p.date_of_birth,
            "nationality": p.nationality,
        }
        if p.passport_number:
            pax["passport_number"] = p.passport_number
        if p.passport_expiry:
            pax["passport_expiry"] = p.passport_expiry
        passengers.append(pax)

    return {
        "action": "book",
        "offer_id": req.offer_id,
        "passengers": passengers,
        "contact": {
            "email": req.contact_email,
            "phone": req.contact_phone,
        },
    }


async def create_booking(req: ALPBookingRequest) -> ALPBookingResponse:
    """Create a flight booking (PNR) via ALP."""
    payload = _build_booking_payload(req)
    logger.info("ALP booking: offer=%s", req.offer_id)
    raw = await _alp_request(payload)

    return ALPBookingResponse(
        booking_reference=raw.get("pnr", raw.get("booking_reference", "")),
        status=raw.get("status", "PENDING").upper(),
        price_total=float(raw.get("price", raw.get("total_price", 0))),
        currency=raw.get("currency", "USD"),
        raw=raw,
    )


# ─── Offer Retrieval (for booking confirmation) ────────────

async def get_offer(offer_id: str) -> dict[str, Any]:
    """Retrieve a specific offer by ID."""
    return await _alp_request({"action": "get_offer", "offer_id": offer_id})


# ─── Booking Retrieval ─────────────────────────────────────

async def get_booking(pnr: str) -> dict[str, Any]:
    """Retrieve a booking by PNR."""
    return await _alp_request({"action": "get_booking", "pnr": pnr})


# ─── Cancellation ─────────────────────────────────────────

async def cancel_booking(pnr: str) -> dict[str, Any]:
    """Cancel a booking by PNR."""
    return await _alp_request({"action": "cancel", "pnr": pnr})
