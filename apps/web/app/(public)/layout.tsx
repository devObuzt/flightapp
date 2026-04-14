import Link from "next/link";
import { getServerSession } from "@/lib/session";

export default async function PublicLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const session = await getServerSession();

  return (
    <div className="min-h-screen flex flex-col bg-gray-50">
      <header className="flex items-center justify-between px-6 py-4 border-b border-gray-100 bg-white">
        <Link href="/flights" className="text-lg font-bold text-brand-600">
          CheckinCheckOut
        </Link>
        <nav className="flex items-center gap-6 text-sm">
          <Link href="/flights" className="text-gray-600 hover:text-gray-900">
            Flights
          </Link>
          <Link href="/agent" className="text-gray-600 hover:text-gray-900">
            AI Agent
          </Link>
          {session ? (
            <>
              <Link href="/bookings" className="text-gray-600 hover:text-gray-900">
                My Trips
              </Link>
              <Link
                href="/profile"
                className="bg-brand-600 text-white px-4 py-2 rounded-lg hover:bg-brand-700"
              >
                Account
              </Link>
            </>
          ) : (
            <>
              <Link href="/login" className="text-gray-600 hover:text-gray-900">
                Sign in
              </Link>
              <Link
                href="/register"
                className="bg-brand-600 text-white px-4 py-2 rounded-lg hover:bg-brand-700"
              >
                Get started
              </Link>
            </>
          )}
        </nav>
      </header>
      <main className="flex-1">{children}</main>
    </div>
  );
}
