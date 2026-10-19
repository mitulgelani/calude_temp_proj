import { NextResponse, type NextRequest } from "next/server";
import { isBackendConfigured } from "@/lib/env";
import { supabaseAdmin } from "@/lib/supabase/admin";

/** Tracked link: counts the click, then forwards to the creator's real URL. */
export async function GET(req: NextRequest, { params }: { params: Promise<{ code: string }> }) {
  const { code } = await params;
  if (!isBackendConfigured() || !/^[a-z0-9]{4,16}$/.test(code)) {
    return NextResponse.redirect(new URL("/", req.url));
  }
  const { data } = await supabaseAdmin().rpc("register_click", { code });
  const target = typeof data === "string" ? data : null;
  if (!target || !/^https?:\/\//i.test(target)) return NextResponse.redirect(new URL("/", req.url));
  return NextResponse.redirect(target, { status: 302 });
}
