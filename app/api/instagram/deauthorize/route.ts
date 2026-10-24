import { NextResponse, type NextRequest } from "next/server";
import { parseSignedRequest } from "@/lib/crypto";
import { deleteInstagramAccount } from "@/lib/deletion";
import { env, isBackendConfigured } from "@/lib/env";

export const dynamic = "force-dynamic";

/** Meta calls this when someone removes LinkPlz from their Instagram account. */
export async function POST(req: NextRequest) {
  const form = await req.formData().catch(() => null);
  const signed = form?.get("signed_request");
  if (typeof signed !== "string") return NextResponse.json({ error: "Missing signed_request" }, { status: 400 });
  const payload = parseSignedRequest(signed, env.igAppSecret);
  const userId = payload?.user_id;
  if (!payload || (typeof userId !== "string" && typeof userId !== "number")) {
    return NextResponse.json({ error: "Invalid signed_request" }, { status: 400 });
  }
  if (isBackendConfigured()) await deleteInstagramAccount(String(userId));
  return NextResponse.json({ ok: true });
}
