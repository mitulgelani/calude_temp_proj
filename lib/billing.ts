import type { Billing, PlanId } from "@/lib/plans";

/**
 * Dodo Payments (merchant of record). Product IDs are not secret, so the live IDs are
 * defaults here and can be overridden per environment (e.g. test-mode IDs on previews).
 */
const PRODUCTS: Record<`${Exclude<PlanId, "free">}-${Billing}`, string> = {
  "creator-monthly": process.env.DODO_PRODUCT_CREATOR_MONTHLY || "pdt_0NqQmFluApyrt5gdaCqJm",
  "creator-yearly": process.env.DODO_PRODUCT_CREATOR_YEARLY || "pdt_0NqQml0TvQzYtjxwbY6f4",
  "studio-monthly": process.env.DODO_PRODUCT_STUDIO_MONTHLY || "pdt_0NqQn7hQNiR03trTC2Er2",
  "studio-yearly": process.env.DODO_PRODUCT_STUDIO_YEARLY || "pdt_0NqQnNDZ7LhBKyYmgZFdF",
};

/** Live checkout by default; set DODO_CHECKOUT_BASE=https://test.checkout.dodopayments.com for test mode. */
const CHECKOUT_BASE = (process.env.DODO_CHECKOUT_BASE || "https://checkout.dodopayments.com").replace(/\/$/, "");

/** Business ID for the hosted customer portal (customers manage or cancel their subscription there). */
const BUSINESS_ID = process.env.DODO_BUSINESS_ID || "bus_0NfJEWFx7fnaoi48etTYe";

export function productFor(plan: string, billing: string): string | null {
  return (PRODUCTS as Record<string, string>)[`${plan}-${billing}`] ?? null;
}

/** Which LinkPlz plan a Dodo product belongs to. Products from the business's other brands return null. */
export function planForProduct(productId: string | undefined | null): "creator" | "studio" | null {
  if (!productId) return null;
  const extra = (v?: string) => (v ?? "").split(",").map((s) => s.trim()).filter(Boolean);
  if (productId === PRODUCTS["studio-monthly"] || productId === PRODUCTS["studio-yearly"]) return "studio";
  if (productId === PRODUCTS["creator-monthly"] || productId === PRODUCTS["creator-yearly"]) return "creator";
  if (extra(process.env.DODO_PRODUCTS_STUDIO).includes(productId)) return "studio";
  if (extra(process.env.DODO_PRODUCTS_CREATOR).includes(productId)) return "creator";
  return null;
}

/** Hosted checkout link with the buyer's email locked and their LinkPlz user ID attached as metadata. */
export function checkoutLink(opts: { productId: string; email: string; userId: string; returnUrl: string }): string {
  const params = new URLSearchParams({
    quantity: "1",
    email: opts.email,
    disableEmail: "true",
    redirect_url: opts.returnUrl,
    metadata_user_id: opts.userId,
  });
  return `${CHECKOUT_BASE}/buy/${opts.productId}?${params.toString()}`;
}

export function customerPortalUrl(): string {
  const host = CHECKOUT_BASE.includes("test.") ? "https://test.customer.dodopayments.com" : "https://customer.dodopayments.com";
  return `${host}/login/${BUSINESS_ID}`;
}
