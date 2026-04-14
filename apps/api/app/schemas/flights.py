"""
Public-facing flight schemas — what the API accepts and returns.
"""
from typing import Literal
from pydantic import BaseModel, Field


# ─── Search Request ───────────────────────────────────────

class PassengerCount(BaseModel):
    adults: int = Field(default=1, ge=1, le=9)
    children: int = Field(default=0, ge=0, le=9)
    infants: int = Field(default=0, ge=0, le=4)


class FlightSearchRequest(BaseModel):
    origin: str = Field(..., min_length=3, max_length=3, description="IATA airport code")
    destination: str = Field(..., min_length=3, max_length=3, description="IATA airport code")
    departure_date: str = Field(..., description="YYYY-MM-DD")
    return_date: str | None = Field(default=None, description="YYYY-MM-DD for round-trip")
    passengers: PassengerCount = Field(default_factory=PassengerCount)
    cabin: Literal["ECONOMY", "PREMIUM_ECONOMY", "BUSINESS", "FIRST"] = "ECONOMY"


# ─── Search Response ──────────────────────────────────────

class SegmentResponse(BaseModel):
    origin: str
    destination: str
    departure_datetime: str
    arrival_datetime: str
    carrier: str
    flight_number: str
    cabin: str
    duration_minutes: int
    stops: int


class FlightOfferResponse(BaseModel):
    offer_id: str
    price_total: float
    currency: str
    segments: list[SegmentResponse]
    refundable: bool


class FlightSearchResponse(BaseModel):
    search_id: str
    offers: list[FlightOfferResponse]
    total: int


# ─── Booking Request ──────────────────────────────────────

class PassengerDetail(BaseModel):
    type: Literal["ADT", "CHD", "INF"] = "ADT"
    first_name: str
    last_name: str
    date_of_birth: str = Field(..., description="YYYY-MM-DD")
    nationality: str = Field(..., min_length=2, max_length=2, description="ISO 2-letter country code")
    passport_number: str | None = None
    passport_expiry: str | None = Field(default=None, description="YYYY-MM-DD")


class FlightBookingRequest(BaseModel):
    offer_id: str
    passengers: list[PassengerDetail] = Field(..., min_length=1)
    contact_email: str
    contact_phone: str


# ─── Booking Response ─────────────────────────────────────

class FlightBookingResponse(BaseModel):
    booking_reference: str
    status: str
    price_total: float
    currency: str
