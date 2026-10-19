import { randomBytes } from "crypto";
import { NextResponse, type NextRequest } from "next/server";
import { isInstagramConfigured, isSupabaseConfigured } from "@/lib/env";
import { authorizeUrl } from "@/lib/instagram";
import { supabaseServer } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

export async function GET(req: NextRequest) {
  if (!isSupabaseConfigured() || !isInstagramConfigured()) {
    return NextResponse.redirect(new URL("/dashboard/settings?error=setup", req.url));
  }
  const supabase = await supabaseServer();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return NextResponse.redirect(new URL("/login?next=/dashboard/settings", req.url));

  const state = randomBytes(16).toString("hex");
  const res = NextResponse.redirect(authorizeUrl(state));
  res.cookies.set("ig_oauth_state", state, {
    httpOnly: true,
    secure: true,
    sameSite: "lax",
    path: "/",
    maxAge: 600,
  });
  return res;
}
