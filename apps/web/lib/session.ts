import { cookies } from "next/headers";
import { jwtVerify } from "jose";

export interface Session {
  userId: string;
}

export async function getServerSession(): Promise<Session | null> {
  const cookieStore = await cookies();
  const token = cookieStore.get("access_token")?.value;

  if (!token) return null;

  try {
    const { payload } = await jwtVerify(
      token,
      new TextEncoder().encode(process.env.JWT_SECRET_KEY)
    );
    return { userId: payload.sub as string };
  } catch {
    return null;
  }
}
