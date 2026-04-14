"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { CABIN_MAP } from "@/lib/api/flights";

type TripType = "return" | "one-way" | "multi-city";

const CABIN_OPTIONS = ["Economy", "Premium Economy", "Business", "First"];

const PRODUCTS = [
  { id: "flights", label: "Flights", emoji: "✈️", active: true },
  { id: "hotels", label: "Hotels", emoji: "🏨", active: false },
  { id: "cars", label: "Car Rental", emoji: "🚗", active: false },
  { id: "events", label: "Events", emoji: "🎭", active: false },
  { id: "sport", label: "Sport", emoji: "⚽", active: false },
  { id: "all-inclusive", label: "All-Inclusive", emoji: "🌴", active: false },
  { id: "local", label: "Local Agents", emoji: "🧭", active: false },
];

export default function FlightsPage() {
  const router = useRouter();

  const [tripType, setTripType] = useState<TripType>("return");
  const [origin, setOrigin] = useState("");
  const [destination, setDestination] = useState("");
  const [departDate, setDepartDate] = useState("");
  const [returnDate, setReturnDate] = useState("");
  const [passengers, setPassengers] = useState(1);
  const [cabin, setCabin] = useState("Economy");
  const [error, setError] = useState("");

  function handleSearch(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setError("");

    if (!origin.trim() || origin.trim().length < 3) {
      setError("Please enter a valid origin airport code (e.g. TLV)");
      return;
    }
    if (!destination.trim() || destination.trim().length < 3) {
      setError("Please enter a valid destination airport code (e.g. LHR)");
      return;
    }
    if (!departDate) {
      setError("Please select a departure date");
      return;
    }

    const params = new URLSearchParams({
      origin: origin.trim().toUpperCase(),
      destination: destination.trim().toUpperCase(),
      departure_date: departDate,
      adults: String(passengers),
      cabin: CABIN_MAP[cabin] ?? "ECONOMY",
    });

    if (tripType === "return" && returnDate) {
      params.set("return_date", returnDate);
    }

    router.push(`/flights/results?${params.toString()}`);
  }

  return (
    <div className="flex flex-col">
      {/* Product category tabs */}
      <div className="bg-white border-b border-gray-100">
        <div className="max-w-5xl mx-auto px-6 py-3 flex gap-1 overflow-x-auto">
          {PRODUCTS.map((p) => (
            <button
              key={p.id}
              disabled={!p.active}
              className={`flex items-center gap-2 px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition
                ${p.active
                  ? "bg-brand-600 text-white"
                  : "bg-gray-100 text-gray-400 cursor-not-allowed"
                }`}
            >
              <span>{p.emoji}</span>
              {p.label}
            </button>
          ))}
        </div>
      </div>

      {/* Search form */}
      <div className="max-w-5xl mx-auto w-full px-6 py-10">
        <h1 className="text-3xl font-bold text-gray-900 mb-6">
          Where to next?
        </h1>

        <form
          onSubmit={handleSearch}
          className="bg-white rounded-2xl shadow-sm border border-gray-200 p-6 flex flex-col gap-5"
        >
          {/* Trip type */}
          <div className="flex gap-2">
            {(["return", "one-way", "multi-city"] as TripType[]).map((t) => (
              <button
                key={t}
                type="button"
                onClick={() => setTripType(t)}
                className={`px-4 py-1.5 rounded-full text-sm font-medium border transition
                  ${tripType === t
                    ? "border-brand-600 bg-brand-50 text-brand-700"
                    : "border-gray-200 text-gray-500 hover:border-gray-300"
                  }`}
              >
                {t === "return" ? "Return" : t === "one-way" ? "One way" : "Multi-city"}
              </button>
            ))}
          </div>

          {/* From / To */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs text-gray-400 mb-1 ml-1">From</label>
              <div className="flex items-center border border-gray-200 rounded-xl px-4 py-3 focus-within:border-brand-500 focus-within:ring-1 focus-within:ring-brand-500">
                <span className="text-gray-400 mr-3">✈️</span>
                <input
                  type="text"
                  placeholder="Airport code (e.g. TLV)"
                  value={origin}
                  onChange={(e) => setOrigin(e.target.value.toUpperCase())}
                  maxLength={3}
                  className="flex-1 outline-none text-gray-800 text-sm bg-transparent uppercase"
                />
              </div>
            </div>

            <div>
              <label className="block text-xs text-gray-400 mb-1 ml-1">To</label>
              <div className="flex items-center border border-gray-200 rounded-xl px-4 py-3 focus-within:border-brand-500 focus-within:ring-1 focus-within:ring-brand-500">
                <span className="text-gray-400 mr-3">🛬</span>
                <input
                  type="text"
                  placeholder="Airport code (e.g. LHR)"
                  value={destination}
                  onChange={(e) => setDestination(e.target.value.toUpperCase())}
                  maxLength={3}
                  className="flex-1 outline-none text-gray-800 text-sm bg-transparent uppercase"
                />
              </div>
            </div>
          </div>

          {/* Dates / Passengers / Cabin */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div>
              <label className="block text-xs text-gray-400 mb-1 ml-1">Depart</label>
              <input
                type="date"
                value={departDate}
                min={new Date().toISOString().split("T")[0]}
                onChange={(e) => setDepartDate(e.target.value)}
                className="w-full border border-gray-200 rounded-xl px-4 py-3 text-sm text-gray-700 outline-none focus:border-brand-500 focus:ring-1 focus:ring-brand-500"
              />
            </div>

            {tripType === "return" && (
              <div>
                <label className="block text-xs text-gray-400 mb-1 ml-1">Return</label>
                <input
                  type="date"
                  value={returnDate}
                  min={departDate || new Date().toISOString().split("T")[0]}
                  onChange={(e) => setReturnDate(e.target.value)}
                  className="w-full border border-gray-200 rounded-xl px-4 py-3 text-sm text-gray-700 outline-none focus:border-brand-500 focus:ring-1 focus:ring-brand-500"
                />
              </div>
            )}

            <div>
              <label className="block text-xs text-gray-400 mb-1 ml-1">Passengers</label>
              <div className="flex items-center border border-gray-200 rounded-xl px-4 py-3 gap-3">
                <button
                  type="button"
                  onClick={() => setPassengers(Math.max(1, passengers - 1))}
                  className="text-gray-400 hover:text-gray-700 text-lg leading-none"
                >−</button>
                <span className="flex-1 text-center text-sm font-medium text-gray-700">{passengers}</span>
                <button
                  type="button"
                  onClick={() => setPassengers(Math.min(9, passengers + 1))}
                  className="text-gray-400 hover:text-gray-700 text-lg leading-none"
                >+</button>
              </div>
            </div>

            <div>
              <label className="block text-xs text-gray-400 mb-1 ml-1">Cabin</label>
              <select
                value={cabin}
                onChange={(e) => setCabin(e.target.value)}
                className="w-full border border-gray-200 rounded-xl px-4 py-3 text-sm text-gray-700 outline-none focus:border-brand-500 bg-white"
              >
                {CABIN_OPTIONS.map((c) => (
                  <option key={c}>{c}</option>
                ))}
              </select>
            </div>
          </div>

          {/* Validation error */}
          {error && (
            <p className="text-sm text-red-500 bg-red-50 px-4 py-2 rounded-lg">{error}</p>
          )}

          {/* Search button */}
          <button
            type="submit"
            className="w-full bg-brand-600 hover:bg-brand-700 text-white font-semibold py-4 rounded-xl text-base transition flex items-center justify-center gap-2"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
            Search flights
          </button>
        </form>

        {/* AI Agent CTA */}
        <div className="mt-6 bg-white rounded-2xl border border-gray-200 p-5 flex items-center gap-4 hover:border-brand-300 transition cursor-pointer">
          <div className="w-12 h-12 bg-brand-600 rounded-xl flex items-center justify-center text-2xl flex-shrink-0">
            🤖
          </div>
          <div className="flex-1">
            <p className="font-semibold text-gray-800">AI Travel Agent</p>
            <p className="text-sm text-gray-500">
              Just tell me where you want to go — text or voice, any language.
            </p>
          </div>
          <a
            href="/agent"
            className="text-brand-600 font-medium text-sm hover:underline whitespace-nowrap"
          >
            Chat now →
          </a>
        </div>
      </div>
    </div>
  );
}
