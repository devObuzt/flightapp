"""
ALP internal data models — shapes of what ALP API returns.
These are NOT the public API schemas (see app/schemas/flights.py).
"""
from typing import Any
from pydantic import BaseModel


# ─── Token ────────────────────────────────────────────────

class ALPToken(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int = 300


# ─── Flight Search ────────────────────────────────────────

class ALPPassenger(BaseModel):
    type: str          # ADT | CHD | INF
    count: int = 1


class ALPSearchRequest(BaseModel):
    origin: str        # IATA airport code  e.g. "TLV"
    destination: str   # IATA airport code  e.g. "LHR"
    departure_date: str  # YYYY-MM-DD
    return_date: str | None = None
    passengers: list[ALPPassenger]
    cabin: str = "ECONOMY"   # ECONOMY | BUSINESS | FIRST


class ALPSegment(BaseModel):
    origin: str
    destination: str
    departure_datetime: str
    arrival_datetime: str
    carrier: str
    flight_number: str
    cabin: str
    duration_minutes: int
    stops: int = 0


class ALPOffer(BaseModel):
    offer_id: str
    price_total: float
    currency: str
    segments: list[ALPSegment]
    refundable: bool = False
    raw: dict[str, Any] = {}   # full raw response kept for booking step


class ALPSearchResponse(BaseModel):
    offers: list[ALPOffer]
    search_id: str


# ─── Booking ──────────────────────────────────────────────

class ALPPassengerDetail(BaseModel):
    type: str                  # ADT | CHD | INF
    first_name: str
    last_name: str
    date_of_birth: str         # YYYY-MM-DD
    nationality: str           # ISO 2-letter country code
    passport_number: str | None = None
    passport_expiry: str | None = None


class ALPBookingRequest(BaseModel):
    offer_id: str
    passengers: list[ALPPassengerDetail]
    contact_email: str
    contact_phone: str


class ALPBookingResponse(BaseModel):
    booking_reference: str     # PNR
    status: str                # CONFIRMED | PENDING | FAILED
    price_total: float
    currency: str
    raw: dict[str, Any] = {}
