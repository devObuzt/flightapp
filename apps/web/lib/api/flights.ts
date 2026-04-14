import { apiRequest } from "./client";

// ─── Types ────────────────────────────────────────────────

export interface PassengerCount {
  adults: number;
  children: number;
  infants: number;
}

export interface FlightSearchParams {
  origin: string;
  destination: string;
  departure_date: string;
  return_date?: string;
  passengers: PassengerCount;
  cabin: "ECONOMY" | "PREMIUM_ECONOMY" | "BUSINESS" | "FIRST";
}

export interface Segment {
  origin: string;
  destination: string;
  departure_datetime: string;
  arrival_datetime: string;
  carrier: string;
  flight_number: string;
  cabin: string;
  duration_minutes: number;
  stops: number;
}

export interface FlightOffer {
  offer_id: string;
  price_total: number;
  currency: string;
  segments: Segment[];
  refundable: boolean;
}

export interface FlightSearchResponse {
  search_id: string;
  offers: FlightOffer[];
  total: number;
}

export interface PassengerDetail {
  type: "ADT" | "CHD" | "INF";
  first_name: string;
  last_name: string;
  date_of_birth: string;
  nationality: string;
  passport_number?: string;
  passport_expiry?: string;
}

export interface BookingRequest {
  offer_id: string;
  passengers: PassengerDetail[];
  contact_email: string;
  contact_phone: string;
}

export interface BookingResponse {
  booking_reference: string;
  status: string;
  price_total: number;
  currency: string;
}

// ─── Cabin label map ──────────────────────────────────────

export const CABIN_MAP: Record<string, FlightSearchParams["cabin"]> = {
  Economy: "ECONOMY",
  "Premium Economy": "PREMIUM_ECONOMY",
  Business: "BUSINESS",
  First: "FIRST",
};

// ─── API calls ────────────────────────────────────────────

export const flightsApi = {
  search: (params: FlightSearchParams) =>
    apiRequest<FlightSearchResponse>("/flights/search", {
      method: "POST",
      body: JSON.stringify(params),
    }),

  book: (params: BookingRequest) =>
    apiRequest<BookingResponse>("/flights/book", {
      method: "POST",
      body: JSON.stringify(params),
    }),

  getBooking: (pnr: string) =>
    apiRequest<Record<string, unknown>>(`/flights/booking/${pnr}`),

  cancelBooking: (pnr: string) =>
    apiRequest<Record<string, unknown>>(`/flights/booking/${pnr}`, {
      method: "DELETE",
    }),
};

// ─── Helpers ──────────────────────────────────────────────

export function formatDuration(minutes: number): string {
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  return h > 0 ? `${h}h ${m}m` : `${m}m`;
}

export function formatDateTime(dt: string): { date: string; time: string } {
  if (!dt) return { date: "", time: "" };
  const d = new Date(dt);
  return {
    date: d.toLocaleDateString("en-GB", { day: "2-digit", month: "short" }),
    time: d.toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit" }),
  };
}
