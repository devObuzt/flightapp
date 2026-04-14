import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL(
    process.env.NEXT_PUBLIC_SITE_URL ?? "https://checkincheckout.app"
  ),
  title: {
    default: "CheckinCheckOut — AI Travel Agent",
    template: "%s | CheckinCheckOut",
  },
  description:
    "Book flights, hotels, and more with your AI travel agent. Search and book in your language.",
  openGraph: {
    type: "website",
    siteName: "CheckinCheckOut",
  },
  twitter: {
    card: "summary_large_image",
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="min-h-screen bg-white text-gray-900 antialiased">
        {children}
      </body>
    </html>
  );
}
