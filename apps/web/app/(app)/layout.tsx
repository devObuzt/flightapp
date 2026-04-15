import { redirect } from "next/navigation";
import { getServerSession } from "@/lib/session";

export default async function AppLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const session = await getServerSession();

  if (!session) {
    redirect("/login");
  }

  return (
    <div className="min-h-screen flex flex-col">
      <header className="flex items-center justify-between px-6 py-4 border-b border-gray-100 bg-white">
        <span className="text-lg font-bold text-brand-600">CheckinCheckOut</span>
        <nav className="flex items-center gap-6 text-sm">
          <a href="/agent" className="text-gray-600 hover:text-gray-900">
            AI Agent
          </a>
          <a href="/flights/search" className="text-gray-600 hover:text-gray-900">
            Flights
          </a>
          <a href="/bookings" className="text-gray-600 hover:text-gray-900">
            My Bookings
          </a>
          <a href="/profile" className="text-gray-600 hover:text-gray-900">
            Profile
          </a>
        </nav>
      </header>
      <main className="flex-1">{children}</main>
    </div>
  );
}
