import { createHmac } from "crypto";
import { NextResponse, type NextRequest } from "next/server";
import { safeEqual } from "@/lib/crypto";
import { env, isBackendConfigured } from "@/lib/env";
import { supabaseAdmin } from "@/lib/supabase/admin";

export const dynamic = "force-dynamic";

/**
 * Payment webhook following the Standard Webhooks spec (used by Dodo Payments).
 * Maps product IDs to plans with DODO_PRODUCTS_CREATOR / DODO_PRODUCTS_STUDIO (comma-separated).
 */
function verify(raw: string, id: string | null, ts: string | null, sigHeader: string | null): boolean {
  if (!env.billingWebhookSecret || !id || !ts || !sigHeader) return false;
  if (Math.abs(Date.now() / 1000 - Number(ts)) > 300) return false;
  const secret = Buffer.from(env.billingWebhookSecret.replace(/^whsec_/, ""), "base64");
  const expected = createHmac("sha256", secret).update(`${id}.${ts}.${raw}`).digest("base64");
  return sigHeader.split(" ").some((part) => safeEqual(part.split(",")[1] ?? "", expected));
}

function planForProduct(productId: string | undefined): "creator" | "studio" | null {
  if (!productId) return null;
  const list = (v?: string) => (v ?? "").split(",").map((s) => s.trim()).filter(Boolean);
  if (list(process.env.DODO_PRODUCTS_STUDIO).includes(productId)) return "studio";
  if (list(process.env.DODO_PRODUCTS_CREATOR).includes(productId)) return "creator";
  return null;
}

type BillingEvent = {
  type?: string;
  data?: {
    product_id?: string;
    next_billing_date?: string;
    customer?: { email?: string };
  };
};

export async function POST(req: NextRequest) {
  const raw = await req.text();
  const ok = verify(raw, req.headers.get("webhook-id"), req.headers.get("webhook-timestamp"), req.headers.get("webhook-signature"));
  if (!ok) return NextResponse.json({ error: "Invalid signature" }, { status: 401 });
  if (!isBackendConfigured()) return NextResponse.json({ ok: true });

  const event = JSON.parse(raw) as BillingEvent;
  const email = event.data?.customer?.email?.toLowerCase();
  if (!email) return NextResponse.json({ ok: true, ignored: "no email" });

  const db = supabaseAdmin();
  const type = event.type ?? "";
  if (["subscription.active", "subscription.renewed", "subscription.plan_changed"].includes(type)) {
    const plan = planForProduct(event.data?.product_id);
    if (plan) {
      await db
        .from("profiles")
        .update({ plan, plan_renews_at: event.data?.next_billing_date ?? null })
        .ilike("email", email);
    }
  } else if (["subscription.cancelled", "subscription.expired", "subscription.failed"].includes(type)) {
    await db.from("profiles").update({ plan: "free", plan_renews_at: null }).ilike("email", email);
  }
  return NextResponse.json({ ok: true });
}
