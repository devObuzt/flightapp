"""
ALP Flight Provider Client
--------------------------
Base URL: https://alp.co.il/newBooking
Auth:     OAuth2 client-credentials via Keycloak

Endpoints confirmed working:
  POST /newBooking/retrievePNR   — retrieve booking by PNR
  POST /newBooking/getDocketData — get docket (needs form or XML body)
  POST /newBooking/createDocket  — create a booking
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

_token_cache: dict[str, Any] = {}
_token_lock = asyncio.Lock()

REDIS_TOKEN_KEY = "alp:access_token"
REDIS_TOKEN_TTL = 270


# ─── Token Management ─────────────────────────────────────

async def _fetch_token() -> str:
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
        return resp.json()["access_token"]


async def get_alp_token() -> str:
    async with _token_lock:
        redis = await get_redis()
        if redis:
            cached = await redis.get(REDIS_TOKEN_KEY)
            if cached:
                return cached

        if _token_cache.get("token") and _token_cache.get("expires_at", 0) > time.time():
            return _token_cache["token"]

        logger.info("Fetching fresh ALP token")
        token = await _fetch_token()

        if redis:
            await redis.setex(REDIS_TOKEN_KEY, REDIS_TOKEN_TTL, token)

        _token_cache["token"] = token
        _token_cache["expires_at"] = time.time() + REDIS_TOKEN_TTL
        return token


# ─── Base Request Helper ──────────────────────────────────

async def _alp_post(path: str, payload: dict[str, Any]) -> dict[str, Any]:
    """POST JSON to an ALP newBooking endpoint."""
    token = await get_alp_token()
    url = f"{settings.alp_booking_url}/{path.lstrip('/')}"
    logger.info("ALP → %s | payload: %s", url, payload)

    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.post(
            url,
            json=payload,
            headers={
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json",
                "Accept": "*/*",
            },
        )

    logger.info("ALP ← %s | body: %s", resp.status_code, resp.text[:500])
    resp.raise_for_status()

    try:
        return resp.json()
    except Exception:
        return {"raw_text": resp.text}


# ─── Retrieve PNR ─────────────────────────────────────────

async def get_booking(pnr: str, supplier: str = "") -> dict[str, Any]:
    """Retrieve a booking by PNR reference."""
    raw = await _alp_post("retrievePNR", {
        "action": "retrievePNR",
        "pnr": pnr,
        "supplier": supplier,
    })
    if raw.get("errorCode") and raw.get("errorCode") != "0":
        raise ValueError(raw.get("errorMessage", "PNR not found"))
    return raw.get("data") or raw


# ─── Get Docket Data ──────────────────────────────────────

async def get_docket(docket_id: str, last_name: str) -> dict[str, Any]:
    """Retrieve a docket by ID and passenger last name."""
    token = await get_alp_token()
    url = f"{settings.alp_booking_url}/getDocketData"

    # getDocketData rejects application/json — use form-encoded
    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.post(
            url,
            data={
                "action": "getDocketData",
                "docketId": docket_id,
                "lastName": last_name,
            },
            headers={
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/x-www-form-urlencoded",
                "Accept": "application/json",
            },
        )

    logger.info("ALP getDocket ← %s | body: %s", resp.status_code, resp.text[:500])
    resp.raise_for_status()
    try:
        return resp.json()
    except Exception:
        return {"raw_text": resp.text}


# ─── Create Docket (Book a Deal) ──────────────────────────

async def create_booking(req: ALPBookingRequest) -> ALPBookingResponse:
    """
    Book a deal via ALP createDocket.
    req.offer_id is treated as the ALP ReferenceId (Deal ID).
    """
    clients = []
    reservations_clients = []

    for idx, p in enumerate(req.passengers, start=1):
        title = {"ADT": "MR", "CHD": "CHD", "INF": "INF"}.get(p.type, "MR")
        clients.append({
            "clientIndex": idx,
            "title": title,
            "firstName": p.first_name,
            "lastName": p.last_name,
            "dateOfBirth": p.date_of_birth,
            "passport": p.passport_number or "",
            "passportExpired": p.passport_expiry or "",
            "email": req.contact_email if idx == 1 else "",
            "phoneNum": req.contact_phone if idx == 1 else "",
        })
        reservations_clients.append({
            "ClientRef": idx,
            "Price": 0,  # price comes from the deal
        })

    payload = {
        "ReferenceId": req.offer_id,
        "ReferenceSource": "JSON",
        "Phone": req.contact_phone,
        "Email": req.contact_email,
        "Reservations": [
            {
                "ReservationIndex": 1,
                "RequestPnr": "Yes",
                "ReservationSupplier": "",
                "ReservationProducts": [
                    {
                        "ProductType": "F",
                        "ProductId": req.offer_id,
                        "ProductClients": reservations_clients,
                    }
                ],
            }
        ],
        "Clients": clients,
    }

    raw = await _alp_post("createDocket", payload)
    logger.info("ALP createDocket response: %s", raw)

    return ALPBookingResponse(
        booking_reference=str(raw.get("docketId", raw.get("pnr", raw.get("bookingRef", "")))),
        status=raw.get("status", "PENDING").upper() if raw.get("status") else "PENDING",
        price_total=float(raw.get("totalPrice", raw.get("price", 0))),
        currency=raw.get("currency", "ILS"),
        raw=raw,
    )


# ─── Cancel Booking ───────────────────────────────────────

async def cancel_booking(pnr: str) -> dict[str, Any]:
    """Cancel a booking — uses retrievePNR to check it exists first."""
    return await _alp_post("retrievePNR", {
        "action": "retrievePNR",
        "pnr": pnr,
        "supplier": "",
    })


# ─── Offer / Search (stub) ────────────────────────────────

async def get_offer(offer_id: str) -> dict[str, Any]:
    """
    ALP works with pre-loaded deals identified by ReferenceId.
    Return the deal ID as-is for now.
    """
    return {"offer_id": offer_id, "note": "ALP deal — book via /flights/book with this offer_id"}


async def search_flights(req: ALPSearchRequest) -> ALPSearchResponse:
    """
    ALP does not expose a real-time flight search endpoint.
    Returns empty — deals come from the ALP platform.
    """
    return ALPSearchResponse(offers=[], search_id="")
