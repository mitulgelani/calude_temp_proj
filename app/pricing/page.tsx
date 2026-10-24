import type { Metadata } from "next";
import { FaqList, faqJsonLd } from "@/components/FaqList";
import { JsonLd } from "@/components/JsonLd";
import { MarketingShell } from "@/components/MarketingShell";
import { PricingTable } from "@/components/PricingTable";
import type { Faq } from "@/lib/content";

export const metadata: Metadata = {
  title: "Pricing — free plan, then $9 or ₹399 a month",
  description:
    "LinkPlz pricing: 1,000 free DMs a month, unlimited DMs from $9 or ₹399 a month, and a Studio plan for five Instagram accounts. No per-contact fees.",
  alternates: { canonical: "/pricing" },
};

const PRICING_FAQS: Faq[] = [
  {
    q: "What happens when I hit 1,000 DMs on the Free plan?",
    a: "LinkPlz stops sending new DMs until the next calendar month and shows the skipped comments in your activity. Upgrade at any time and they can be re-run, as long as they're under seven days old.",
  },
  {
    q: "Do you charge per contact like some chatbot tools?",
    a: "No. Paid plans have a flat price and unlimited DMs, so the bill stays the same when a Reel goes viral.",
  },
  {
    q: "Can I cancel any time?",
    a: "Yes. Cancel from your dashboard and you keep paid features until the end of the period you've paid for.",
  },
  {
    q: "Which currencies do you accept?",
    a: "You can pay in US dollars or Indian rupees. Cards, UPI and most local payment methods are supported at checkout.",
  },
];

export default function PricingPage() {
  return (
    <MarketingShell>
      <JsonLd data={faqJsonLd(PRICING_FAQS)} />
      <section className="wrap pb-16 pt-12 md:pt-20">
        <h1 className="max-w-[16ch] text-[clamp(2.5rem,6vw,4.5rem)] font-extrabold leading-[0.95] tracking-[-0.045em]">
          Start free. Pay when your Reels take off.
        </h1>
        <p className="mb-12 mt-5 max-w-[52ch] text-lg text-ink-soft">
          Every plan uses Instagram&apos;s official API and includes link tracking. Paid plans remove the DM limit entirely.
        </p>
        <PricingTable />
      </section>
      <section className="wrap grid gap-10 py-16 lg:grid-cols-[0.7fr_1.3fr]">
        <h2 className="text-[clamp(1.8rem,4vw,2.8rem)] font-bold leading-[1.05] tracking-[-0.04em]">Billing questions</h2>
        <FaqList faqs={PRICING_FAQS} />
      </section>
    </MarketingShell>
  );
}
