import { redirect } from "next/navigation";

// Root → go straight to the search experience (no login required)
export default function RootPage() {
  redirect("/flights");
}
