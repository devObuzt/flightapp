"use client";

import { useEffect, useState, Suspense } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import {
  flightsApi,
  FlightOffer,
  FlightSearchResponse,
  CABIN_MAP,
  formatDuration,
  formatDateTime,
} from "@/lib/api/flights";

// ─── Offer Card ───────────────────────────────────────────

function OfferCard({
  offer,
  onSelect,
}: {
  offer: FlightOffer;
  onSelect: (id: string) => void;
}) {
  const first = offer.segments[0];
  const last = offer.segments[offer.segments.length - 1];
  const dep = formatDateTime(first.departure_datetime);
  const arr = formatDateTime(last.arrival_datetime);
  const totalDuration = offer.segments.reduce(
    (acc, s) => acc + s.duration_minutes,
    0
  );
  const stops = offer.segments.length - 1;

  return (
    <div className="bg-white rounded-2xl border border-gray-200 p-5 flex flex-col md:flex-row md:items-center gap-4 hover:border-brand-400 hover:shadow-sm transition">
      {/* Airline */}
      <div className="flex items-center gap-3 min-w-[120px]">
        <div className="w-10 h-10 bg-brand-50 rounded-lg flex items-center justify-center text-lg font-bold text-brand-700">
          {first.carrier}
        </div>
        <div>
          <p className="text-sm font-semibold text-gray-800">{first.carrier}</p>
          <p className="text-xs text-gray-400">{first.flight_number}</p>
        </div>
      </div>

      {/* Route & times */}
      <div className="flex-1 flex items-center gap-4">
        <div className="text-center">
          <p className="text-2xl font-bold text-gray-900">{dep.time}</p>
          <p className="text-xs text-gray-400">{first.origin}</p>
          <p className="text-xs text-gray-300">{dep.date}</p>
        </div>

        <div className="flex-1 flex flex-col items-center gap-1">
          <p className="text-xs text-gray-400">{formatDuration(totalDuration)}</p>
          <div className="w-full flex items-center gap-1">
            <div className="flex-1 h-px bg-gray-200" />
            {stops === 0 ? (
              <span className="text-xs text-green-600 font-medium px-2">Direct</span>
            ) : (
              <span className="text-xs text-orange-500 font-medium px-2">
                {stops} stop{stops > 1 ? "s" : ""}
              </span>
            )}
            <div className="flex-1 h-px bg-gray-200" />
          </div>
          <p className="text-xs text-gray-300">{first.cabin}</p>
        </div>

        <div className="text-center">
          <p className="text-2xl font-bold text-gray-900">{arr.time}</p>
          <p className="text-xs text-gray-400">{last.destination}</p>
          <p className="text-xs text-gray-300">{arr.date}</p>
        </div>
      </div>

      {/* Price + CTA */}
      <div className="flex flex-col items-end gap-2 min-w-[140px]">
        {offer.refundable && (
          <span className="text-xs text-green-600 font-medium bg-green-50 px-2 py-0.5 rounded-full">
            Refundable
          </span>
        )}
        <p className="text-2xl font-bold text-brand-700">
          {offer.currency} {offer.price_total.toLocaleString()}
        </p>
        <button
          onClick={() => onSelect(offer.offer_id)}
          className="bg-brand-600 hover:bg-brand-700 text-white text-sm font-semibold px-5 py-2.5 rounded-xl transition w-full text-center"
        >
          Select
        </button>
      </div>
    </div>
  );
}

// ─── Results Content ──────────────────────────────────────

function ResultsContent() {
  const params = useSearchParams();
  const router = useRouter();

  const [results, setResults] = useState<FlightSearchResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const origin = params.get("origin") ?? "";
  const destination = params.get("destination") ?? "";
  const departure_date = params.get("departure_date") ?? "";
  const return_date = params.get("return_date") ?? undefined;
  const adults = Number(params.get("adults") ?? 1);
  const cabin = (params.get("cabin") ?? "ECONOMY") as FlightSearchResponse["offers"][0]["segments"][0]["cabin"];

  useEffect(() => {
    if (!origin || !destination || !departure_date) {
      router.replace("/flights");
      return;
    }

    setLoading(true);
    setError(null);

    flightsApi
      .search({
        origin,
        destination,
        departure_date,
        return_date: return_date || undefined,
        passengers: { adults, children: 0, infants: 0 },
        cabin: cabin as any,
      })
      .then(setResults)
      .catch((err) => setError(err.message ?? "Search failed"))
      .finally(() => setLoading(false));
  }, [origin, destination, departure_date, return_date, adults, cabin]);

  const handleSelect = (offerId: string) => {
    router.push(`/flights/book?offer_id=${offerId}`);
  };

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center py-24 gap-4">
        <div className="w-10 h-10 border-4 border-brand-600 border-t-transparent rounded-full animate-spin" />
        <p className="text-gray-500 text-sm">Searching flights with ALP...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center py-24 gap-4">
        <p className="text-2xl">😕</p>
        <p className="text-gray-700 font-semibold">Search failed</p>
        <p className="text-sm text-gray-400">{error}</p>
        <button
          onClick={() => router.back()}
          className="mt-2 px-5 py-2 bg-brand-600 text-white rounded-xl text-sm font-medium"
        >
          Go back
        </button>
      </div>
    );
  }

  const offers = results?.offers ?? [];

  return (
    <div className="max-w-4xl mx-auto px-6 py-8">
      {/* Header */}
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">
            {origin} → {destination}
          </h1>
          <p className="text-sm text-gray-400 mt-1">
            {departure_date}
            {return_date ? ` · Return ${return_date}` : ""}
            {" · "}
            {adults} passenger{adults > 1 ? "s" : ""}
          </p>
        </div>
        <button
          onClick={() => router.back()}
          className="text-sm text-brand-600 hover:underline"
        >
          ← Edit search
        </button>
      </div>

      {/* Results count */}
      <p className="text-sm text-gray-500 mb-4">
        {offers.length > 0
          ? `${offers.length} flight${offers.length > 1 ? "s" : ""} found`
          : "No flights found for this route."}
      </p>

      {/* Offers list */}
      <div className="flex flex-col gap-3">
        {offers.map((offer) => (
          <OfferCard key={offer.offer_id} offer={offer} onSelect={handleSelect} />
        ))}
      </div>

      {offers.length === 0 && (
        <div className="text-center py-16 text-gray-400">
          <p className="text-4xl mb-3">✈️</p>
          <p className="font-medium">No flights available for this route</p>
          <p className="text-sm mt-1">Try different dates or airports</p>
        </div>
      )}
    </div>
  );
}

// ─── Page ─────────────────────────────────────────────────

export default function FlightResultsPage() {
  return (
    <Suspense
      fallback={
        <div className="flex items-center justify-center py-24">
          <div className="w-10 h-10 border-4 border-brand-600 border-t-transparent rounded-full animate-spin" />
        </div>
      }
    >
      <ResultsContent />
    </Suspense>
  );
}
