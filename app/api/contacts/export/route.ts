import { NextResponse } from "next/server";
import { isSupabaseConfigured } from "@/lib/env";
import { supabaseServer } from "@/lib/supabase/server";
import { DEMO_CONTACTS } from "@/lib/demo";

export const dynamic = "force-dynamic";

function csvCell(v: unknown): string {
  const s = v == null ? "" : String(v);
  const safe = /^[=+\-@]/.test(s) ? `'${s}` : s; // avoid spreadsheet formula injection
  return /[",\n]/.test(safe) ? `"${safe.replace(/"/g, '""')}"` : safe;
}

export async function GET() {
  let rows: { username: string | null; interactions: number; first_seen_at: string; last_seen_at: string }[] = DEMO_CONTACTS;
  if (isSupabaseConfigured()) {
    const supabase = await supabaseServer();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) return NextResponse.json({ error: "Not signed in" }, { status: 401 });
    const { data } = await supabase
      .from("contacts")
      .select("username,interactions,first_seen_at,last_seen_at")
      .order("last_seen_at", { ascending: false })
      .limit(10000);
    rows = data ?? [];
  }
  const header = "username,interactions,first_seen,last_seen";
  const body = rows
    .map((r) => [r.username ? `@${r.username}` : "", r.interactions, r.first_seen_at, r.last_seen_at].map(csvCell).join(","))
    .join("\n");
  return new Response(`${header}\n${body}\n`, {
    headers: {
      "Content-Type": "text/csv; charset=utf-8",
      "Content-Disposition": `attachment; filename="hookline-contacts.csv"`,
    },
  });
}
