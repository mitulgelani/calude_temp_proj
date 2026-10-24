export type PlanId = "free" | "creator" | "studio";
export type Currency = "usd" | "inr";
export type Billing = "monthly" | "yearly";

export type Plan = {
  id: PlanId;
  name: string;
  blurb: string;
  /** Price per month, shown in the table. Yearly = billed once, 2 months free. */
  price: Record<Currency, Record<Billing, number>>;
  dmLimit: number | null;
  accounts: number;
  features: string[];
  cta: string;
  featured?: boolean;
};

export const FREE_DM_LIMIT = 1000;

export const PLANS: Plan[] = [
  {
    id: "free",
    name: "Free",
    blurb: "For trying it on your next Reel.",
    price: { usd: { monthly: 0, yearly: 0 }, inr: { monthly: 0, yearly: 0 } },
    dmLimit: FREE_DM_LIMIT,
    accounts: 1,
    features: [
      "1,000 DMs a month",
      "Unlimited automations",
      "Comment-to-DM on Reels, posts and Lives",
      "Keyword replies in DMs and Story replies",
      "Public comment replies",
      "Link click tracking",
    ],
    cta: "Start free",
  },
  {
    id: "creator",
    name: "Creator",
    blurb: "For creators whose Reels actually travel.",
    price: { usd: { monthly: 9, yearly: 7.5 }, inr: { monthly: 399, yearly: 332 } },
    dmLimit: null,
    accounts: 1,
    features: [
      "Unlimited DMs",
      "Everything in Free",
      "Follow-to-unlock links",
      "Re-run on comments from the last 7 days",
      "Contact list with CSV export",
      "Rotating public replies",
    ],
    cta: "Get Creator",
    featured: true,
  },
  {
    id: "studio",
    name: "Studio",
    blurb: "For teams and agencies running several accounts.",
    price: { usd: { monthly: 29, yearly: 24 }, inr: { monthly: 1299, yearly: 1082 } },
    dmLimit: null,
    accounts: 5,
    features: [
      "5 Instagram accounts",
      "Everything in Creator",
      "One dashboard for every account",
      "Priority support on WhatsApp and email",
    ],
    cta: "Get Studio",
  },
];

export function formatPrice(amount: number, currency: Currency): string {
  if (amount === 0) return currency === "inr" ? "₹0" : "$0";
  if (currency === "inr") return `₹${Math.round(amount).toLocaleString("en-IN")}`;
  return `$${Number.isInteger(amount) ? amount : amount.toFixed(2)}`;
}

/** Paid plans go through our checkout route, which signs the user in and opens Dodo Payments checkout. */
export function checkoutUrl(plan: PlanId, billing: Billing): string | null {
  if (plan === "free") return null;
  return `/api/billing/checkout?plan=${plan}&billing=${billing}`;
}

export function planLabel(id: string): string {
  return PLANS.find((p) => p.id === id)?.name ?? "Free";
}
