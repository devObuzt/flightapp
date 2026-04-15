"""
Flights Router — /api/v1/flights
---------------------------------
All flight operations powered by ALP provider.
"""
import logging
from typing import Any
from fastapi import APIRouter, Depends, HTTPException, status
from app.core.config import settings
import httpx

# Auth disabled for testing — re-enable before production
# from app.core.dependencies import get_current_user
# from app.models.user import User
from app.schemas.flights import (
    FlightSearchRequest,
    FlightSearchResponse,
    FlightOfferResponse,
    SegmentResponse,
    FlightBookingRequest,
    FlightBookingResponse,
)
from app.integrations.alp import client as alp
from app.data.airports import search_airports
from app.integrations.alp.schemas import (
    ALPSearchRequest,
    ALPPassenger,
    ALPBookingRequest,
    ALPPassengerDetail,
)

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/flights", tags=["flights"])


# ─── Helpers ──────────────────────────────────────────────

# Maps specific airport codes → ALP city codes
# ALP uses city codes (LON, PAR, NYC...) not individual airport codes
_AIRPORT_TO_CITY: dict[str, str] = {
    # London
    "LHR": "LON", "LGW": "LON", "STN": "LON", "LTN": "LON", "LCY": "LON",
    # Paris
    "CDG": "PAR", "ORY": "PAR",
    # New York
    "JFK": "NYC", "LGA": "NYC", "EWR": "NYC",
    # Milan
    "MXP": "MIL", "LIN": "MIL",
    # Stockholm
    "ARN": "STO", "NYO": "STO",
    # Moscow
    "SVO": "MOW", "DME": "MOW", "VKO": "MOW",
    # Istanbul
    "IST": "IST", "SAW": "IST",
    # Tokyo
    "NRT": "TYO", "HND": "TYO",
}

def _to_alp_city(code: str) -> str:
    """Convert airport IATA code to ALP city code if needed."""
    return _AIRPORT_TO_CITY.get(code.upper(), code.upper())


def _duration_to_minutes(duration_str: str) -> int:
    """Convert ALP duration string '05:25' to total minutes (325)."""
    try:
        parts = duration_str.strip().split(":")
        return int(parts[0]) * 60 + int(parts[1])
    except Exception:
        return 0


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

@router.get("/airports")
async def airports_search(q: str = ""):
    """Search airports by name, city, country, or IATA code."""
    return search_airports(q)

@router.post("/search")
async def search_flights(body: FlightSearchRequest):
    """Search for available flights via ALP."""
    try:
        token = await alp.get_alp_token()

        import httpx as _httpx
        from app.core.config import settings as _settings

        # ALP listener requires form-encoded body (NOT JSON)
        # action=getData, depCity=origin, destination=dest, date=YYYY-MM-DD
        form_data = {
            "action": "getData",
            "siteRequest": _settings.alp_client_id,
            "depCity": _to_alp_city(body.origin),
            "destination": _to_alp_city(body.destination),
            "dealtype": "ALL",
            "date": body.departure_date,
            "adultNum": str(body.passengers.adults),
        }
        if body.passengers.children:
            form_data["childNum"] = str(body.passengers.children)
        if body.passengers.infants:
            form_data["infantNum"] = str(body.passengers.infants)

        async with _httpx.AsyncClient(timeout=30) as client:
            resp = await client.post(
                _settings.alp_listener_url,
                data=form_data,
                headers={
                    "Authorization": f"Bearer {token}",
                    "Content-Type": "application/x-www-form-urlencoded",
                    "Accept": "*/*",
                },
            )

        logger.info("ALP status: %s | body: %s", resp.status_code, resp.text[:1000])

        # ALP may return JSON or plain text
        ctype = resp.headers.get("Content-Type", "")
        try:
            if "application/json" in ctype.lower():
                raw = resp.json()
            else:
                raw = resp.json()  # try anyway
        except Exception:
            raw = {"raw_text": resp.text, "status_code": resp.status_code}

        # Parse ALP response structure: {Deals: [...], Flights: {Outbound, Inbound, Pairs}}
        deals = raw.get("Deals") or []
        flights_data = raw.get("Flights") or {}
        outbound_list = {f["index"]: f for f in (flights_data.get("Outbound") or [])}
        inbound_list = {f["index"]: f for f in (flights_data.get("Inbound") or [])}
        pairs = flights_data.get("Pairs") or []

        is_round_trip = bool(body.return_date)

        offers = []
        for deal in deals:
            deal_id = deal.get("dealId", "")
            related_pairs = [p for p in pairs if p.get("dealid") == deal_id]

            if not related_pairs:
                continue

            # Filter by trip type:
            # one-way  → pairs where fromIndex is null/empty
            # round-trip → pairs where fromIndex exists
            if is_round_trip:
                related_pairs = [p for p in related_pairs if p.get("fromIndex")]
            else:
                related_pairs = [p for p in related_pairs if not p.get("fromIndex")]

            if not related_pairs:
                continue

            # Build segments from the first valid pair
            pair = related_pairs[0]
            segments = []

            to_idx = pair.get("toIndex")
            from_idx = pair.get("fromIndex")

            if to_idx and to_idx in outbound_list:
                ob = outbound_list[to_idx]
                segments.append({
                    "origin": ob.get("departureIATA", ""),
                    "destination": ob.get("arrivalIATA", ""),
                    "departure_datetime": f"{ob.get('date', '')}T{ob.get('depTime', '')}",
                    "arrival_datetime": f"{ob.get('date', '')}T{ob.get('arrTime', '')}",
                    "carrier": ob.get("airline", ""),
                    "flight_number": ob.get("flightNumber", ""),
                    "cabin": pair.get("toClass", "Y"),
                    "duration_minutes": _duration_to_minutes(ob.get("flightDuration", "")),
                    "stops": 0,
                    "direction": "outbound",
                })

            if from_idx and from_idx in inbound_list:
                ib = inbound_list[from_idx]
                segments.append({
                    "origin": ib.get("departureIATA", ""),
                    "destination": ib.get("arrivalIATA", ""),
                    "departure_datetime": f"{ib.get('date', '')}T{ib.get('depTime', '')}",
                    "arrival_datetime": f"{ib.get('date', '')}T{ib.get('arrTime', '')}",
                    "carrier": ib.get("airline", ""),
                    "flight_number": ib.get("flightNumber", ""),
                    "cabin": pair.get("fromClass", "Y"),
                    "duration_minutes": _duration_to_minutes(ib.get("flightDuration", "")),
                    "stops": 0,
                    "direction": "inbound",
                })

            if not segments:
                continue

            offers.append({
                "offer_id": deal_id,
                "price_total": float(deal.get("price", 0)),
                "currency": deal.get("currency", "USD"),
                "refundable": False,
                "segments": segments,
                "provider": deal.get("provider", ""),
                "deal_type": deal.get("dealType", ""),
                "deal_features": deal.get("dealFeature", []),
                "departure_date": deal.get("departureDate", ""),
                "child_price": float(deal.get("childPrice", 0)),
                "infant_price": float(deal.get("infantPrice", 0)),
                "normal_price": float(deal.get("normalPrice", 0)),
                "baggage": deal.get("extFlag", ""),
                "title": deal.get("title") or deal.get("dealType", ""),
            })

        return {
            "search_id": f"{body.origin}-{body.destination}-{body.departure_date}",
            "total": len(offers),
            "offers": offers,
        }

    except Exception as exc:
        logger.error("ALP search error: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Flight search failed: {exc}",
        )


@router.post("/book", response_model=FlightBookingResponse)
async def book_flight(
    body: FlightBookingRequest,

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
async def get_booking(pnr: str, supplier: str = ""):
    """Retrieve a booking by PNR reference via ALP retrievePNR."""
    try:
        return await alp.get_booking(pnr, supplier)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    except Exception as exc:
        logger.error("ALP get_booking error: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Could not retrieve booking: {exc}",
        )


@router.get("/docket/{docket_id}")
async def get_docket(docket_id: str, last_name: str):
    """Retrieve a docket by ID and passenger last name via ALP getDocketData."""
    try:
        return await alp.get_docket(docket_id, last_name)
    except Exception as exc:
        logger.error("ALP get_docket error: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Could not retrieve docket: {exc}",
        )


@router.delete("/booking/{pnr}")
async def cancel_booking(
    pnr: str,

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


@router.get("/debug/discover")
async def debug_discover():
    """Try common action VALUES to find what ALP supports."""
    import httpx as _httpx
    from app.core.config import settings as _cfg

    token = await alp.get_alp_token()
    action_values = [
        # Basic
        "search", "Search", "SEARCH",
        "book", "Book", "BOOK",
        "cancel", "Cancel", "CANCEL",
        # Flight-specific
        "SearchFlights", "FlightSearch", "AvailabilitySearch",
        "AirSearch", "GetFlights", "availability", "Availability",
        "SearchAvailability", "FlightAvailability", "AirAvailability",
        "GetAvailability", "LowFareSearch", "AirLowFareSearch",
        "flightSearch", "flight_search", "searchFlight",
        "getFlights", "getAvailability", "airSearch",
        "SearchRequest", "AvailabilityRequest", "FlightRequest",
        "Available", "Flights", "list",
        "search_flights", "get_flights", "air_search",
        "flight_availability", "getFlightAvailability",
        "GetFlightAvailability", "FlightAvailabilitySearch",
        "AirAvailabilitySearch", "AvailabilityInquiry",
        "PricingInquiry", "AirPrice", "FlightPrice",
        "create", "create_booking", "CreateBooking",
        "get_booking", "GetBooking",
        "info", "Info", "ping", "Ping", "status", "Status",
        "help", "Help", "actions", "Actions",
        "1", "2", "3", "01", "100",
        # Dot-notation style
        "flight.search", "air.search", "flight.availability",
        "flights.search", "booking.create",
        # Underscore/lowercase
        "air_availability", "low_fare_search", "flight_offer",
        "GetFlightOffer", "FlightOffer", "flightOffer",
        # GDS-style
        "OTA_AirAvailRQ", "OTA_AirLowFareSearchRQ",
        "AirAvailabilityRequest", "PriceItinerary",
        # Hebrew transliterated
        "chipa", "chipus", "hazmana", "bidul",
    ]
    results = {}
    async with _httpx.AsyncClient(timeout=10) as client:
        for action_val in action_values:
            payload = {
                "action": action_val,
                "origin": "TLV",
                "destination": "LHR",
                "departure_date": "2026-05-01",
                "passengers": [{"type": "ADT", "count": 1}],
            }
            try:
                r = await client.post(
                    _cfg.alp_listener_url,
                    json=payload,
                    headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json", "Accept": "*/*"},
                )
                body = r.text[:200]
                # Flag anything that's NOT the standard error
                is_different = "Unsupported action" not in body
                results[action_val] = {
                    "status": r.status_code,
                    "body": body,
                    "DIFFERENT": is_different,
                }
            except Exception as e:
                results[action_val] = {"error": str(e)}
    return results


@router.post("/debug/raw")
async def debug_raw(body: dict[str, Any]):
    """
    DEBUG ONLY — sends any payload directly to ALP and returns raw response.
    Remove before production.
    """
    try:
        token = await alp.get_alp_token()
        async with httpx.AsyncClient(timeout=30) as client:
            resp = await client.post(
                settings.alp_listener_url,
                json=body,
                headers={
                    "Authorization": f"Bearer {token}",
                    "Content-Type": "application/json",
                    "Accept": "*/*",
                },
            )
            return {
                "status_code": resp.status_code,
                "headers": dict(resp.headers),
                "body": resp.text,
                "token_preview": token[:30] + "...",
            }
    except Exception as exc:
        return {"error": str(exc)}


@router.get("/debug/probe")
async def debug_probe():
    """
    Try completely different request structures to ALP:
    - form-encoded body
    - action as URL query param
    - nested JSON wrappers
    - different field names
    """
    import httpx as _httpx
    from app.core.config import settings as _cfg

    token = await alp.get_alp_token()
    hdrs_json = {"Authorization": f"Bearer {token}", "Content-Type": "application/json", "Accept": "*/*"}
    hdrs_form = {"Authorization": f"Bearer {token}", "Content-Type": "application/x-www-form-urlencoded", "Accept": "*/*"}

    base_json = {"origin": "TLV", "destination": "LHR", "departure_date": "2026-06-01", "passengers": [{"type": "ADT", "count": 1}]}
    base_form = {"origin": "TLV", "destination": "LHR", "departure_date": "2026-06-01"}

    results = {}

    async with _httpx.AsyncClient(timeout=15) as client:

        # 1. Form-encoded with action field
        for act in ["search", "Search", "FlightSearch", "AirSearch"]:
            try:
                r = await client.post(
                    _cfg.alp_listener_url,
                    data={**base_form, "action": act},
                    headers=hdrs_form,
                )
                results[f"form:{act}"] = {"status": r.status_code, "body": r.text[:300]}
            except Exception as e:
                results[f"form:{act}"] = {"error": str(e)}

        # 2. Action as URL query param (JSON body without action)
        for act in ["search", "Search", "FlightSearch"]:
            try:
                r = await client.post(
                    f"{_cfg.alp_listener_url}?action={act}",
                    json=base_json,
                    headers=hdrs_json,
                )
                results[f"queryparam:{act}"] = {"status": r.status_code, "body": r.text[:300]}
            except Exception as e:
                results[f"queryparam:{act}"] = {"error": str(e)}

        # 3. Nested wrapper: {"request": {"action": ..., ...}}
        for act in ["search", "Search", "FlightSearch"]:
            try:
                r = await client.post(
                    _cfg.alp_listener_url,
                    json={"request": {"action": act, **base_json}},
                    headers=hdrs_json,
                )
                results[f"nested_request:{act}"] = {"status": r.status_code, "body": r.text[:300]}
            except Exception as e:
                results[f"nested_request:{act}"] = {"error": str(e)}

        # 4. Different top-level key names: "method", "cmd", "type", "function"
        for key in ["method", "cmd", "type", "function", "op", "operation"]:
            try:
                r = await client.post(
                    _cfg.alp_listener_url,
                    json={"action": "search", key: "search", **base_json},
                    headers=hdrs_json,
                )
                results[f"extra_key:{key}"] = {"status": r.status_code, "body": r.text[:300]}
            except Exception as e:
                results[f"extra_key:{key}"] = {"error": str(e)}

        # 5. Replace "action" key entirely
        for key in ["method", "cmd", "type", "function", "op", "module"]:
            for val in ["search", "Search", "FlightSearch"]:
                try:
                    r = await client.post(
                        _cfg.alp_listener_url,
                        json={key: val, **base_json},
                        headers=hdrs_json,
                    )
                    body_txt = r.text[:200]
                    if "action value is required" in body_txt or "Unsupported" not in body_txt:
                        results[f"key_{key}_val_{val}"] = {"status": r.status_code, "body": body_txt, "INTERESTING": True}
                    # only log interesting ones to keep response small
                except Exception as e:
                    results[f"key_{key}_val_{val}"] = {"error": str(e)}

    return results


@router.get("/debug/newbooking")
async def debug_newbooking():
    """
    Test the newBooking endpoints discovered in the ALP documentation.
    Also try deal/package search action names on listener.php.
    """
    import httpx as _httpx
    from app.core.config import settings as _cfg

    token = await alp.get_alp_token()
    hdrs = {"Authorization": f"Bearer {token}", "Content-Type": "application/json", "Accept": "*/*"}
    results = {}

    async with _httpx.AsyncClient(timeout=15) as client:

        # 1. Try getDocketData with a fake docket id — if it says "not found" we know the endpoint works
        try:
            r = await client.post(
                f"{_cfg.alp_booking_url}/getDocketData",
                json={"action": "getDocketData", "docketId": "TEST123", "lastName": "TEST"},
                headers=hdrs,
            )
            results["getDocketData"] = {"status": r.status_code, "body": r.text[:400]}
        except Exception as e:
            results["getDocketData"] = {"error": str(e)}

        # 2. Try retrievePNR with a fake PNR
        try:
            r = await client.post(
                f"{_cfg.alp_booking_url}/retrievePNR",
                json={"action": "retrievePNR", "pnr": "TEST123", "supplier": "TEST"},
                headers=hdrs,
            )
            results["retrievePNR"] = {"status": r.status_code, "body": r.text[:400]}
        except Exception as e:
            results["retrievePNR"] = {"error": str(e)}

        # 3. Try listener.php with deal/package search action names
        deal_actions = [
            "getDeals", "GetDeals", "searchDeals", "SearchDeals",
            "getPackages", "GetPackages", "searchPackages",
            "getAvailableDeals", "getDeal", "deal", "deals",
            "package", "packages", "Package", "Packages",
            "getCharters", "GetCharters", "searchCharters", "SearchCharters",
            "charter", "Charter", "charters", "Charters",
            "getOffers", "GetOffers", "searchOffers", "SearchOffers",
            "offers", "Offers", "getOffer", "GetOffer",
        ]
        for act in deal_actions:
            try:
                r = await client.post(
                    _cfg.alp_listener_url,
                    json={"action": act, "origin": "TLV", "destination": "LHR", "departure_date": "2026-06-01"},
                    headers=hdrs,
                )
                body = r.text[:200]
                if "Unsupported action" not in body:
                    results[f"listener:{act}"] = {"status": r.status_code, "body": body, "DIFFERENT": True}
            except Exception as e:
                results[f"listener:{act}"] = {"error": str(e)}

    return results


@router.get("/debug/token")
async def debug_token():
    """DEBUG ONLY — check if ALP token fetch works."""
    try:
        token = await alp.get_alp_token()
        return {"ok": True, "token_preview": token[:30] + "..."}
    except Exception as exc:
        return {"ok": False, "error": str(exc)}


@router.get("/offer/{offer_id}")
async def get_offer(
    offer_id: str,

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
