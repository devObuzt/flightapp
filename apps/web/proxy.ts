import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import { jwtVerify } from "jose";

// Only these routes require auth — search/agent/flights are public
const PROTECTED_PATHS = ["/bookings", "/profile"];

function isProtected(pathname: string): boolean {
  return PROTECTED_PATHS.some(
    (p) => pathname === p || pathname.startsWith(p + "/")
  );
}

export async function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Skip Next.js internals and static files
  if (
    pathname.startsWith("/_next") ||
    pathname.startsWith("/favicon")
  ) {
    return NextResponse.next();
  }

  // Only protected routes need auth checks
  if (!isProtected(pathname)) {
    return NextResponse.next();
  }

  const token =
    request.cookies.get("access_token")?.value ??
    request.headers.get("authorization")?.replace("Bearer ", "");

  if (!token) {
    if (pathname.startsWith("/api/")) {
      return NextResponse.json({ detail: "Not authenticated" }, { status: 401 });
    }
    return NextResponse.redirect(new URL("/login", request.url));
  }

  try {
    await jwtVerify(
      token,
      new TextEncoder().encode(process.env.JWT_SECRET_KEY)
    );
    return NextResponse.next();
  } catch {
    if (pathname.startsWith("/api/")) {
      return NextResponse.json({ detail: "Invalid or expired token" }, { status: 401 });
    }
    const response = NextResponse.redirect(new URL("/login", request.url));
    response.cookies.delete("access_token");
    return response;
  }
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico).*)"],
};
