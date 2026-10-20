import { after, NextResponse, type NextRequest } from "next/server";
import { verifyMetaSignature } from "@/lib/crypto";
import { env, isBackendConfigured } from "@/lib/env";
import { drainQueue, handleComment, handleMessaging, type CommentValue, type MessagingEvent } from "@/lib/engine";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";
export const maxDuration = 60;

/** Meta calls this once with hub.* params when you save the webhook URL in the App Dashboard. */
export function GET(req: NextRequest) {
  const p = req.nextUrl.searchParams;
  const mode = p.get("hub.mode");
  const token = p.get("hub.verify_token");
  const challenge = p.get("hub.challenge") ?? "";
  if (mode === "subscribe" && env.igVerifyToken && token === env.igVerifyToken) {
    return new Response(challenge, { status: 200, headers: { "Content-Type": "text/plain" } });
  }
  return new Response("Forbidden", { status: 403 });
}

type WebhookBody = {
  object?: string;
  entry?: {
    id: string;
    time?: number;
    changes?: { field: string; value: CommentValue }[];
    messaging?: MessagingEvent[];
  }[];
};

export async function POST(req: NextRequest) {
  const raw = await req.text();
  if (!verifyMetaSignature(raw, req.headers.get("x-hub-signature-256"), env.igAppSecret)) {
    return NextResponse.json({ error: "Invalid signature" }, { status: 401 });
  }
  if (!isBackendConfigured()) return NextResponse.json({ ok: true, skipped: "backend not configured" });

  let body: WebhookBody;
  try {
    body = JSON.parse(raw) as WebhookBody;
  } catch {
    return NextResponse.json({ error: "Bad JSON" }, { status: 400 });
  }

  // Answer Meta immediately (it retries slow endpoints), then do the work.
  after(async () => {
    for (const entry of body.entry ?? []) {
      for (const change of entry.changes ?? []) {
        if (change.field === "comments" || change.field === "live_comments") {
          const result = await handleComment(entry.id, change.value).catch((e: unknown) => `error: ${String(e)}`);
          console.log("[webhook] comment", change.value?.id, result);
        }
      }
      for (const m of entry.messaging ?? []) {
        const result = await handleMessaging(entry.id, m).catch((e: unknown) => `error: ${String(e)}`);
        console.log("[webhook] message", m.message?.mid ?? m.postback?.mid, result);
      }
    }
    // Send a few DMs that were held back by Instagram's hourly limit.
    await drainQueue(15).catch((e: unknown) => console.error("[webhook] drain", e));
  });

  return NextResponse.json({ ok: true });
}
