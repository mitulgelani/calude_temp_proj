import { NextResponse, type NextRequest } from "next/server";
import { checkoutLink, productFor } from "@/lib/billing";
import { isSupabaseConfigured } from "@/lib/env";
import { siteUrl } from "@/lib/site";
import { supabaseServer } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

/** /api/billing/checkout?plan=creator&billing=monthly → Dodo hosted checkout for the signed-in user. */
export async function GET(req: NextRequest) {
  const plan = req.nextUrl.searchParams.get("plan") ?? "";
  const billing = req.nextUrl.searchParams.get("billing") === "yearly" ? "yearly" : "monthly";
  const productId = productFor(plan, billing);
  if (!productId) return NextResponse.redirect(new URL("/pricing", req.url));

  const self = `/api/billing/checkout?plan=${encodeURIComponent(plan)}&billing=${billing}`;
  if (!isSupabaseConfigured()) return NextResponse.redirect(new URL("/pricing", req.url));

  const supabase = await supabaseServer();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user?.email) {
    const login = new URL("/login", req.url);
    login.searchParams.set("mode", "signup");
    login.searchParams.set("plan", plan);
    login.searchParams.set("next", self);
    return NextResponse.redirect(login);
  }

  const url = checkoutLink({
    productId,
    email: user.email,
    userId: user.id,
    returnUrl: `${siteUrl()}/dashboard/settings?upgraded=1#plan`,
  });
  return NextResponse.redirect(url);
}
