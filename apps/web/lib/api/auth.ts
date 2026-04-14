import { apiRequest } from "./client";

const BASE_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000/api/v1";

export interface Tokens {
  access_token: string;
  refresh_token: string;
  token_type: string;
}

export const authApi = {
  async register(body: {
    full_name: string;
    email?: string;
    phone?: string;
    password: string;
    language?: string;
    currency?: string;
  }): Promise<Tokens> {
    const res = await fetch(`${BASE_URL}/auth/register`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.detail ?? "Registration failed");
    }
    return res.json();
  },

  async login(body: { identifier: string; password: string }): Promise<Tokens> {
    const res = await fetch(`${BASE_URL}/auth/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ ...body, platform: "web" }),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.detail ?? "Login failed");
    }
    return res.json();
  },

  me: () => apiRequest<{ id: string; email: string; full_name: string }>("/auth/me"),
};
