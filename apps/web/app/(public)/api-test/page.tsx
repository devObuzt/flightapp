"use client";

import { useState } from "react";

const API_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000/api/v1";

const PRESETS = [
  {
    label: "Search – action: search",
    payload: {
      action: "search",
      origin: "TLV",
      destination: "LHR",
      departure_date: "2026-06-01",
      trip_type: "OW",
      passengers: [{ type: "ADT", count: 1 }],
      cabin: "ECONOMY",
    },
  },
  {
    label: "Search – action: Search",
    payload: {
      action: "Search",
      origin: "TLV",
      destination: "LHR",
      departure_date: "2026-06-01",
      trip_type: "OW",
      passengers: [{ type: "ADT", count: 1 }],
      cabin: "ECONOMY",
    },
  },
  {
    label: "Search – action: FlightSearch",
    payload: {
      action: "FlightSearch",
      origin: "TLV",
      destination: "LHR",
      departure_date: "2026-06-01",
      passengers: [{ type: "ADT", count: 1 }],
    },
  },
  {
    label: "Search – action: AirSearch",
    payload: {
      action: "AirSearch",
      origin: "TLV",
      destination: "LHR",
      departure_date: "2026-06-01",
      passengers: [{ type: "ADT", count: 1 }],
    },
  },
  {
    label: "Search – action: GetFlights",
    payload: {
      action: "GetFlights",
      origin: "TLV",
      destination: "LHR",
      departure_date: "2026-06-01",
      passengers: [{ type: "ADT", count: 1 }],
    },
  },
  {
    label: "Search – action: availability",
    payload: {
      action: "availability",
      origin: "TLV",
      destination: "LHR",
      departure_date: "2026-06-01",
      passengers: [{ type: "ADT", count: 1 }],
    },
  },
  {
    label: "Search – action: Availability",
    payload: {
      action: "Availability",
      origin: "TLV",
      destination: "LHR",
      departure_date: "2026-06-01",
      passengers: [{ type: "ADT", count: 1 }],
    },
  },
  {
    label: "Search – action: LowFareSearch",
    payload: {
      action: "LowFareSearch",
      origin: "TLV",
      destination: "LHR",
      departure_date: "2026-06-01",
      passengers: [{ type: "ADT", count: 1 }],
    },
  },
  {
    label: "Search – action: AirLowFareSearch",
    payload: {
      action: "AirLowFareSearch",
      origin: "TLV",
      destination: "LHR",
      departure_date: "2026-06-01",
      passengers: [{ type: "ADT", count: 1 }],
    },
  },
  {
    label: "Token check",
    payload: null,
    endpoint: "/flights/debug/token",
    method: "GET",
  },
  {
    label: "🔍 Discover all actions (takes ~30s)",
    payload: null,
    endpoint: "/flights/debug/discover",
    method: "GET",
  },
  {
    label: "Empty body (see base error)",
    payload: {},
  },
  {
    label: "No action key",
    payload: {
      origin: "TLV",
      destination: "LHR",
      departure_date: "2026-06-01",
      passengers: [{ type: "ADT", count: 1 }],
    },
  },
];

export default function ApiTestPage() {
  const [payload, setPayload] = useState(
    JSON.stringify(PRESETS[0].payload, null, 2)
  );
  const [response, setResponse] = useState<string>("");
  const [status, setStatus] = useState<number | null>(null);
  const [loading, setLoading] = useState(false);
  const [endpoint, setEndpoint] = useState("/flights/debug/raw");
  const [method, setMethod] = useState("POST");

  async function runRequest() {
    setLoading(true);
    setResponse("");
    setStatus(null);
    try {
      const opts: RequestInit = { method };
      if (method === "POST") {
        opts.headers = { "Content-Type": "application/json" };
        opts.body = payload;
      }
      const res = await fetch(`${API_URL}${endpoint}`, opts);
      setStatus(res.status);
      const text = await res.text();
      try {
        setResponse(JSON.stringify(JSON.parse(text), null, 2));
      } catch {
        setResponse(text);
      }
    } catch (err) {
      setResponse(String(err));
    } finally {
      setLoading(false);
    }
  }

  function loadPreset(p: (typeof PRESETS)[0]) {
    if (p.payload !== null && p.payload !== undefined) {
      setPayload(JSON.stringify(p.payload, null, 2));
    }
    setEndpoint(p.endpoint ?? "/flights/debug/raw");
    setMethod(p.method ?? "POST");
  }

  const isSuccess = status && status >= 200 && status < 300;

  return (
    <div className="max-w-5xl mx-auto px-6 py-10">
      <h1 className="text-2xl font-bold text-gray-900 mb-1">ALP API Tester</h1>
      <p className="text-sm text-gray-500 mb-6">
        Send raw requests to the ALP flight API via the backend proxy.
      </p>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {/* Left – presets */}
        <div>
          <p className="text-xs font-semibold text-gray-400 uppercase mb-2">
            Presets
          </p>
          <div className="flex flex-col gap-1">
            {PRESETS.map((p) => (
              <button
                key={p.label}
                onClick={() => loadPreset(p)}
                className="text-left px-3 py-2 text-sm rounded-lg border border-gray-200 hover:border-brand-400 hover:bg-brand-50 transition truncate"
              >
                {p.label}
              </button>
            ))}
          </div>
        </div>

        {/* Right – editor + response */}
        <div className="md:col-span-2 flex flex-col gap-4">
          {/* Endpoint bar */}
          <div className="flex gap-2">
            <select
              value={method}
              onChange={(e) => setMethod(e.target.value)}
              className="border border-gray-200 rounded-lg px-3 py-2 text-sm text-gray-700 bg-white"
            >
              <option>POST</option>
              <option>GET</option>
            </select>
            <input
              value={endpoint}
              onChange={(e) => setEndpoint(e.target.value)}
              className="flex-1 border border-gray-200 rounded-lg px-3 py-2 text-sm font-mono text-gray-700 outline-none focus:border-brand-500"
            />
          </div>

          {/* Payload editor */}
          {method === "POST" && (
            <textarea
              value={payload}
              onChange={(e) => setPayload(e.target.value)}
              rows={14}
              className="w-full border border-gray-200 rounded-xl px-4 py-3 text-sm font-mono text-gray-800 outline-none focus:border-brand-500 resize-y"
              spellCheck={false}
            />
          )}

          {/* Send button */}
          <button
            onClick={runRequest}
            disabled={loading}
            className="w-full bg-brand-600 hover:bg-brand-700 disabled:opacity-50 text-white font-semibold py-3 rounded-xl transition"
          >
            {loading ? "Sending…" : "Send Request"}
          </button>

          {/* Response */}
          {(response || status !== null) && (
            <div className="border border-gray-200 rounded-xl overflow-hidden">
              <div
                className={`px-4 py-2 text-sm font-medium flex items-center gap-2 ${
                  isSuccess
                    ? "bg-green-50 text-green-700"
                    : "bg-red-50 text-red-700"
                }`}
              >
                <span
                  className={`w-2 h-2 rounded-full ${isSuccess ? "bg-green-500" : "bg-red-500"}`}
                />
                HTTP {status}
              </div>
              <pre className="p-4 text-xs font-mono text-gray-700 overflow-x-auto max-h-96 overflow-y-auto bg-gray-50 whitespace-pre-wrap break-words">
                {response}
              </pre>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
