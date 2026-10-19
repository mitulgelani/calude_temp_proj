import { NextResponse, type NextRequest } from "next/server";
import { decrypt } from "@/lib/crypto";
import { isBackendConfigured } from "@/lib/env";
import { listMedia } from "@/lib/instagram";
import { supabaseAdmin } from "@/lib/supabase/admin";
import { supabaseServer } from "@/lib/supabase/server";
import { DEMO_MEDIA } from "@/lib/demo";

export const dynamic = "force-dynamic";

/** Recent posts and Reels for the automation post picker. */
export async function GET(req: NextRequest) {
  const accountId = req.nextUrl.searchParams.get("account");
  if (!isBackendConfigured()) return NextResponse.json({ media: DEMO_MEDIA });
  if (!accountId) return NextResponse.json({ error: "Missing account" }, { status: 400 });

  const supabase = await supabaseServer();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "Not signed in" }, { status: 401 });

  const { data: account } = await supabaseAdmin()
    .from("ig_accounts")
    .select("ig_user_id,access_token_enc,user_id")
    .eq("id", accountId)
    .maybeSingle();
  if (!account || account.user_id !== user.id) return NextResponse.json({ error: "Not found" }, { status: 404 });

  try {
    const media = await listMedia(account.ig_user_id, decrypt(account.access_token_enc));
    return NextResponse.json({
      media: media.map((m) => ({
        id: m.id,
        caption: m.caption ?? "",
        thumbnail: m.thumbnail_url ?? m.media_url ?? null,
        permalink: m.permalink ?? null,
        type: m.media_type ?? "",
        timestamp: m.timestamp ?? null,
      })),
    });
  } catch (e) {
    return NextResponse.json({ error: e instanceof Error ? e.message : "Instagram error" }, { status: 502 });
  }
}
