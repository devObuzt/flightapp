"""
Flights Router — /api/v1/flights
---------------------------------
All flight operations powered by ALP provider.
"""
import logging
from fastapi import APIRouter, Depends, HTTPException, status

from app.core.dependencies import get_current_user
from app.models.user import User
from app.schemas.flights import (
    FlightSearchRequest,
    FlightSearchResponse,
    FlightOfferResponse,
    SegmentResponse,
    FlightBookingRequest,
    FlightBookingResponse,
)
from app.integrations.alp import client as alp
from app.integrations.alp.schemas import (
    ALPSearchRequest,
    ALPPassenger,
    ALPBookingRequest,
    ALPPassengerDetail,
)

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/flights", tags=["flights"])


# ─── Helpers ──────────────────────────────────────────────

def _build_alp_passengers(req: FlightSearchRequest) -> list[ALPPassenger]:
    pax = []
    if req.passengers.adults:
        pax.append(ALPPassenger(type="ADT", count=req.passengers.adults))
    if req.passengers.children:
        pax.append(ALPPassenger(type="CHD", count=req.passengers.children))
    if req.passengers.infants:
        pax.append(ALPPassenger(type="INF", count=req.passengers.infants))
    return pax


def _map_offer(offer) -> FlightOfferResponse:
    return FlightOfferResponse(
        offer_id=offer.offer_id,
        price_total=offer.price_total,
        currency=offer.currency,
        refundable=offer.refundable,
        segments=[
            SegmentResponse(
                origin=s.origin,
                destination=s.destination,
                departure_datetime=s.departure_datetime,
                arrival_datetime=s.arrival_datetime,
                carrier=s.carrier,
                flight_number=s.flight_number,
                cabin=s.cabin,
                duration_minutes=s.duration_minutes,
                stops=s.stops,
            )
            for s in offer.segments
        ],
    )


# ─── Endpoints ────────────────────────────────────────────

@router.post("/search", response_model=FlightSearchResponse)
async def search_flights(
    body: FlightSearchRequest,
    current_user: User = Depends(get_current_user),
):
    """
    Search for available flights via ALP.

    - Supports one-way and round-trip
    - Returns list of offers sorted by price (cheapest first)
    """
    try:
        alp_req = ALPSearchRequest(
            origin=body.origin.upper(),
            destination=body.destination.upper(),
            departure_date=body.departure_date,
            return_date=body.return_date,
            passengers=_build_alp_passengers(body),
            cabin=body.cabin,
        )
        result = await alp.search_flights(alp_req)
    except Exception as exc:
        logger.error("ALP search error: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Flight search failed: {exc}",
        )

    offers = sorted(
        [_map_offer(o) for o in result.offers],
        key=lambda o: o.price_total,
    )

    return FlightSearchResponse(
        search_id=result.search_id,
        offers=offers,
        total=len(offers),
    )


@router.post("/book", response_model=FlightBookingResponse)
async def book_flight(
    body: FlightBookingRequest,
    current_user: User = Depends(get_current_user),
):
    """
    Book a flight offer returned by /flights/search.

    - Requires passenger details for all travellers
    - Returns PNR booking reference on success
    """
    try:
        alp_req = ALPBookingRequest(
            offer_id=body.offer_id,
            passengers=[
                ALPPassengerDetail(
                    type=p.type,
                    first_name=p.first_name,
                    last_name=p.last_name,
                    date_of_birth=p.date_of_birth,
                    nationality=p.nationality,
                    passport_number=p.passport_number,
                    passport_expiry=p.passport_expiry,
                )
                for p in body.passengers
            ],
            contact_email=body.contact_email,
            contact_phone=body.contact_phone,
        )
        result = await alp.create_booking(alp_req)
    except Exception as exc:
        logger.error("ALP booking error: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Booking failed: {exc}",
        )

    return FlightBookingResponse(
        booking_reference=result.booking_reference,
        status=result.status,
        price_total=result.price_total,
        currency=result.currency,
    )


@router.get("/booking/{pnr}")
async def get_booking(
    pnr: str,
    current_user: User = Depends(get_current_user),
):
    """Retrieve a booking by PNR reference."""
    try:
        return await alp.get_booking(pnr)
    except Exception as exc:
        logger.error("ALP get_booking error: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Could not retrieve booking: {exc}",
        )


@router.delete("/booking/{pnr}")
async def cancel_booking(
    pnr: str,
    current_user: User = Depends(get_current_user),
):
    """Cancel a booking by PNR reference."""
    try:
        return await alp.cancel_booking(pnr)
    except Exception as exc:
        logger.error("ALP cancel error: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Cancellation failed: {exc}",
        )


@router.get("/offer/{offer_id}")
async def get_offer(
    offer_id: str,
    current_user: User = Depends(get_current_user),
):
    """Get full details for a specific flight offer."""
    try:
        return await alp.get_offer(offer_id)
    except Exception as exc:
        logger.error("ALP get_offer error: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Could not retrieve offer: {exc}",
        )
