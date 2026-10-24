import { createHmac } from "crypto";
import { NextResponse, type NextRequest } from "next/server";
import { planForProduct } from "@/lib/billing";
import { safeEqual } from "@/lib/crypto";
import { env, isBackendConfigured } from "@/lib/env";
import { supabaseAdmin } from "@/lib/supabase/admin";

export const dynamic = "force-dynamic";

/**
 * Dodo Payments webhook (Standard Webhooks signatures).
 * The Dodo business also sells other brands, and every endpoint receives every event,
 * so anything that isn't a LinkPlz product is acknowledged and ignored.
 */
function verify(raw: string, id: string | null, ts: string | null, sigHeader: string | null): boolean {
  if (!env.billingWebhookSecret || !id || !ts || !sigHeader) return false;
  if (Math.abs(Date.now() / 1000 - Number(ts)) > 300) return false;
  const secret = Buffer.from(env.billingWebhookSecret.replace(/^whsec_/, ""), "base64");
  const expected = createHmac("sha256", secret).update(`${id}.${ts}.${raw}`).digest("base64");
  return sigHeader.split(" ").some((part) => safeEqual(part.split(",")[1] ?? "", expected));
}

type BillingEvent = {
  type?: string;
  data?: {
    product_id?: string;
    subscription_id?: string;
    status?: string;
    next_billing_date?: string;
    metadata?: Record<string, string>;
    customer?: { email?: string; customer_id?: string };
  };
};

const ACTIVATE = ["subscription.active", "subscription.renewed", "subscription.plan_changed", "subscription.updated"];
const DEACTIVATE = ["subscription.cancelled", "subscription.expired", "subscription.failed"];

export async function POST(req: NextRequest) {
  const raw = await req.text();
  const ok = verify(raw, req.headers.get("webhook-id"), req.headers.get("webhook-timestamp"), req.headers.get("webhook-signature"));
  if (!ok) {
    console.warn("[billing] invalid signature", { configured: Boolean(env.billingWebhookSecret) });
    return NextResponse.json({ error: "Invalid signature" }, { status: 401 });
  }
  if (!isBackendConfigured()) return NextResponse.json({ ok: true });

  let event: BillingEvent;
  try {
    event = JSON.parse(raw) as BillingEvent;
  } catch {
    return NextResponse.json({ error: "Bad JSON" }, { status: 400 });
  }
  const type = event.type ?? "";
  const d = event.data ?? {};
  const plan = planForProduct(d.product_id);
  if (!plan) return NextResponse.json({ ok: true, ignored: "not a LinkPlz product" });

  const db = supabaseAdmin();
  // Find the LinkPlz user: metadata from our checkout link first, then the checkout email.
  const userId = d.metadata?.user_id;
  const email = d.customer?.email?.toLowerCase();
  if (!userId && !email) return NextResponse.json({ ok: true, ignored: "no user" });
  const base = db.from("profiles").select("id, dodo_subscription_id");
  const { data: rows, error: findError } = await (userId ? base.eq("id", userId) : base.ilike("email", email!)).limit(1);
  if (findError) {
    console.error("[billing] lookup", findError);
    return NextResponse.json({ error: "lookup failed" }, { status: 500 });
  }
  const profile = rows?.[0];
  if (!profile) {
    console.warn("[billing] no matching profile", { type, userId, email });
    return NextResponse.json({ ok: true, ignored: "no matching profile" });
  }

  if (ACTIVATE.includes(type) && (d.status ?? "active") === "active") {
    const { error } = await db
      .from("profiles")
      .update({
        plan,
        plan_renews_at: d.next_billing_date ?? null,
        dodo_subscription_id: d.subscription_id ?? null,
        dodo_customer_id: d.customer?.customer_id ?? null,
      })
      .eq("id", profile.id);
    if (error) throw error;
    console.log("[billing] activated", { user: profile.id, plan, type });
  } else if (DEACTIVATE.includes(type)) {
    // Ignore the end of an old subscription after the user switched to a new one.
    if (profile.dodo_subscription_id && d.subscription_id && profile.dodo_subscription_id !== d.subscription_id) {
      return NextResponse.json({ ok: true, ignored: "superseded subscription" });
    }
    const { error } = await db
      .from("profiles")
      .update({ plan: "free", plan_renews_at: null, dodo_subscription_id: null })
      .eq("id", profile.id);
    if (error) throw error;
    console.log("[billing] downgraded", { user: profile.id, type });
  }
  return NextResponse.json({ ok: true });
}
