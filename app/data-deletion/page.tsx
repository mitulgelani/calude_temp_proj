import type { Metadata } from "next";
import { LegalPage } from "@/components/LegalPage";
import { SUPPORT_EMAIL } from "@/lib/site";

export const metadata: Metadata = {
  title: "Data deletion instructions",
  description: "How to delete the data Hookline stores about your Instagram account.",
  alternates: { canonical: "/data-deletion" },
};

export default function DataDeletionPage() {
  return (
    <LegalPage
      title="Delete your data"
      sections={[
        {
          heading: "From the dashboard",
          body: [
            "Open Settings in your Hookline dashboard and choose Disconnect next to your Instagram account. This immediately deletes the access token, automations, activity log and contacts for that account.",
          ],
        },
        {
          heading: "From Instagram",
          body: [
            "In Instagram, open Settings, then Website permissions, then Apps and websites, and remove Hookline. Instagram notifies us and we delete the account's data automatically.",
          ],
        },
        {
          heading: "By email",
          body: [
            `Email ${SUPPORT_EMAIL} from the address you signed up with and ask us to delete your account. We confirm deletion within 30 days, usually much sooner.`,
          ],
        },
      ]}
    />
  );
}
