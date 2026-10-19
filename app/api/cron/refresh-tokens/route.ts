import { NextResponse, type NextRequest } from "next/server";
import { decrypt, encrypt, safeEqual } from "@/lib/crypto";
import { isBackendConfigured } from "@/lib/env";
import { refreshToken } from "@/lib/instagram";
import { supabaseAdmin } from "@/lib/supabase/admin";

export const dynamic = "force-dynamic";
export const maxDuration = 60;

/** Daily Vercel cron: Instagram long-lived tokens last 60 days, so refresh the ones expiring within 15. */
export async function GET(req: NextRequest) {
  const secret = process.env.CRON_SECRET;
  const auth = req.headers.get("authorization") ?? "";
  if (!secret || !safeEqual(auth, `Bearer ${secret}`)) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  if (!isBackendConfigured()) return NextResponse.json({ ok: true, refreshed: 0 });

  const db = supabaseAdmin();
  const soon = new Date(Date.now() + 15 * 86_400_000).toISOString();
  const { data: accounts } = await db.from("ig_accounts").select("id,access_token_enc").lt("token_expires_at", soon).limit(200);

  let refreshed = 0;
  for (const a of accounts ?? []) {
    try {
      const next = await refreshToken(decrypt(a.access_token_enc));
      await db
        .from("ig_accounts")
        .update({
          access_token_enc: encrypt(next.accessToken),
          token_expires_at: new Date(Date.now() + next.expiresIn * 1000).toISOString(),
          updated_at: new Date().toISOString(),
        })
        .eq("id", a.id);
      refreshed++;
    } catch (e) {
      console.error("[refresh-tokens]", a.id, e);
    }
  }
  return NextResponse.json({ ok: true, refreshed });
}
