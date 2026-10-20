import { NextResponse, type NextRequest } from "next/server";
import { safeEqual } from "@/lib/crypto";
import { drainQueue } from "@/lib/engine";
import { isBackendConfigured } from "@/lib/env";

export const dynamic = "force-dynamic";
export const maxDuration = 60;

/**
 * Sends DMs that were queued by Instagram's hourly limit.
 * Runs daily via Vercel Cron, and opportunistically after every Instagram webhook.
 * On Vercel Pro you can raise the schedule in vercel.json to every few minutes.
 */
export async function GET(req: NextRequest) {
  const secret = process.env.CRON_SECRET;
  const auth = req.headers.get("authorization") ?? "";
  if (!secret || !safeEqual(auth, `Bearer ${secret}`)) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  if (!isBackendConfigured()) return NextResponse.json({ ok: true, skipped: "backend not configured" });
  const result = await drainQueue();
  return NextResponse.json({ ok: true, ...result });
}
