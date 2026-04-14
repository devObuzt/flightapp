const ACCESS_KEY = "cco_access_token";
const REFRESH_KEY = "cco_refresh_token";

export interface Tokens {
  access_token: string;
  refresh_token: string;
}

export function setTokens(tokens: Tokens) {
  if (typeof window === "undefined") return;
  localStorage.setItem(ACCESS_KEY, tokens.access_token);
  localStorage.setItem(REFRESH_KEY, tokens.refresh_token);
  // Also set as cookie so middleware can read it
  document.cookie = `access_token=${tokens.access_token}; path=/; max-age=900; SameSite=Lax`;
}

export function getAccessToken(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem(ACCESS_KEY);
}

export function getRefreshToken(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem(REFRESH_KEY);
}

export function clearTokens() {
  if (typeof window === "undefined") return;
  localStorage.removeItem(ACCESS_KEY);
  localStorage.removeItem(REFRESH_KEY);
  document.cookie = "access_token=; path=/; max-age=0";
}
