import type { Metadata } from "next";
import { LegalPage } from "@/components/LegalPage";
import { SUPPORT_EMAIL } from "@/lib/site";

export const metadata: Metadata = {
  title: "Terms of service",
  description: "The terms for using Hookline, the Instagram comment-to-DM automation tool.",
  alternates: { canonical: "/terms" },
};

export default function TermsPage() {
  return (
    <LegalPage
      title="Terms of service"
      sections={[
        {
          heading: "Using Hookline",
          body: [
            "By creating an account you agree to these terms. You must be at least 18, and you may only connect Instagram accounts you own or are authorised to manage.",
          ],
        },
        {
          heading: "Acceptable use",
          body: [
            "You agree to follow Instagram's Terms of Use, Community Guidelines and Meta's Platform policies. You may not use Hookline to send spam, misleading links, malware, or messages to people who did not interact with your account.",
          ],
        },
        {
          heading: "Plans and billing",
          body: [
            "Paid plans renew automatically each month or year until cancelled. You can cancel from your dashboard; paid features continue until the end of the current period. Fees already paid are not refunded except where required by law.",
          ],
        },
        {
          heading: "Availability",
          body: [
            "Hookline depends on Instagram's API. If Meta changes, limits or suspends API access, some features may stop working, and we are not liable for messages Instagram declines to deliver.",
          ],
        },
        {
          heading: "Liability",
          body: [
            "Hookline is provided as is. To the extent permitted by law, our total liability is limited to the amount you paid us in the 12 months before the claim.",
          ],
        },
        {
          heading: "Contact",
          body: [`Questions about these terms: ${SUPPORT_EMAIL}.`],
        },
      ]}
    />
  );
}
