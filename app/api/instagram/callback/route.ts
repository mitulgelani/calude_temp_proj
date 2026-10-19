import { NextResponse, type NextRequest } from "next/server";
import { encrypt } from "@/lib/crypto";
import { isBackendConfigured } from "@/lib/env";
import { exchangeCode, getMe, subscribeWebhooks, toLongLived } from "@/lib/instagram";
import { supabaseAdmin } from "@/lib/supabase/admin";
import { supabaseServer } from "@/lib/supabase/server";
import { PLANS } from "@/lib/plans";

export const dynamic = "force-dynamic";

function back(req: NextRequest, query: string) {
  const res = NextResponse.redirect(new URL(`/dashboard/settings?${query}`, req.url));
  res.cookies.delete("ig_oauth_state");
  return res;
}

export async function GET(req: NextRequest) {
  const p = req.nextUrl.searchParams;
  if (p.get("error")) return back(req, "error=denied");
  const code = p.get("code");
  const state = p.get("state");
  if (!code || !state || state !== req.cookies.get("ig_oauth_state")?.value) return back(req, "error=state");
  if (!isBackendConfigured()) return back(req, "error=setup");

  const supabase = await supabaseServer();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return NextResponse.redirect(new URL("/login", req.url));

  try {
    const short = await exchangeCode(code);
    const long = await toLongLived(short.accessToken);
    const me = await getMe(long.accessToken);
    const db = supabaseAdmin();

    // Plan limit on connected accounts.
    const { data: profile } = await db.from("profiles").select("plan").eq("id", user.id).maybeSingle();
    const limit = PLANS.find((pl) => pl.id === (profile?.plan ?? "free"))?.accounts ?? 1;
    const { data: existing } = await db.from("ig_accounts").select("id,ig_user_id,user_id").eq("user_id", user.id);
    const alreadyMine = (existing ?? []).some((a) => a.ig_user_id === me.user_id);
    if (!alreadyMine && (existing?.length ?? 0) >= limit) return back(req, "error=limit");

    const { data: owner } = await db.from("ig_accounts").select("user_id").eq("ig_user_id", me.user_id).maybeSingle();
    if (owner && owner.user_id !== user.id) return back(req, "error=taken");

    const subscribed = await subscribeWebhooks(me.user_id, long.accessToken).catch(() => false);
    const { error } = await db.from("ig_accounts").upsert(
      {
        user_id: user.id,
        ig_user_id: me.user_id,
        username: me.username,
        name: me.name ?? null,
        profile_picture_url: me.profile_picture_url ?? null,
        access_token_enc: encrypt(long.accessToken),
        token_expires_at: new Date(Date.now() + long.expiresIn * 1000).toISOString(),
        webhook_subscribed: subscribed,
        updated_at: new Date().toISOString(),
      },
      { onConflict: "ig_user_id" },
    );
    if (error) throw error;
    return back(req, `connected=${encodeURIComponent(me.username)}`);
  } catch (e) {
    console.error("[instagram callback]", e);
    return back(req, "error=exchange");
  }
}
