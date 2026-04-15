"use client";

import { useState, useEffect, useRef } from "react";

interface Airport {
  code: string;
  name: string;
  city: string;
  country: string;
}

interface AirportInputProps {
  label: string;
  placeholder?: string;
  value: string;
  onChange: (code: string) => void;
  icon?: string;
}

const API_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000/api/v1";

export default function AirportInput({
  label,
  placeholder = "City, airport or code",
  value,
  onChange,
  icon = "✈️",
}: AirportInputProps) {
  const [query, setQuery] = useState(value);
  const [results, setResults] = useState<Airport[]>([]);
  const [open, setOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  // Close dropdown when clicking outside
  useEffect(() => {
    function handleClick(e: MouseEvent) {
      if (ref.current && !ref.current.contains(e.target as Node)) {
        setOpen(false);
      }
    }
    document.addEventListener("mousedown", handleClick);
    return () => document.removeEventListener("mousedown", handleClick);
  }, []);

  // Fetch airports when query changes
  useEffect(() => {
    if (query.length < 2) {
      setResults([]);
      setOpen(false);
      return;
    }
    setLoading(true);
    const timer = setTimeout(async () => {
      try {
        const res = await fetch(`${API_URL}/flights/airports?q=${encodeURIComponent(query)}`);
        const data = await res.json();
        setResults(data);
        setOpen(data.length > 0);
      } catch {
        setResults([]);
      } finally {
        setLoading(false);
      }
    }, 250);
    return () => clearTimeout(timer);
  }, [query]);

  function selectAirport(airport: Airport) {
    setQuery(`${airport.city} (${airport.code})`);
    onChange(airport.code);
    setOpen(false);
    setResults([]);
  }

  return (
    <div ref={ref} className="relative">
      <label className="block text-xs text-gray-400 mb-1 ml-1">{label}</label>
      <div className="flex items-center border border-gray-200 rounded-xl px-4 py-3 focus-within:border-brand-500 focus-within:ring-1 focus-within:ring-brand-500">
        <span className="text-gray-400 mr-3">{icon}</span>
        <input
          type="text"
          placeholder={placeholder}
          value={query}
          onChange={(e) => {
            setQuery(e.target.value);
            if (!e.target.value) onChange("");
          }}
          onFocus={() => results.length > 0 && setOpen(true)}
          className="flex-1 outline-none text-gray-800 text-sm bg-transparent"
          autoComplete="off"
        />
        {loading && (
          <div className="w-4 h-4 border-2 border-brand-400 border-t-transparent rounded-full animate-spin ml-2" />
        )}
        {value && (
          <span className="ml-2 text-xs font-bold text-brand-600 bg-brand-50 px-2 py-0.5 rounded-full">
            {value}
          </span>
        )}
      </div>

      {open && results.length > 0 && (
        <div className="absolute top-full left-0 right-0 mt-1 bg-white border border-gray-200 rounded-xl shadow-lg z-50 overflow-hidden">
          {results.map((airport) => (
            <button
              key={airport.code}
              type="button"
              onClick={() => selectAirport(airport)}
              className="w-full flex items-center gap-3 px-4 py-3 hover:bg-brand-50 transition text-left"
            >
              <span className="text-lg font-bold text-brand-700 w-12 shrink-0">
                {airport.code}
              </span>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium text-gray-800 truncate">
                  {airport.city}
                </p>
                <p className="text-xs text-gray-400 truncate">
                  {airport.name} · {airport.country}
                </p>
              </div>
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
