import { randomBytes } from "crypto";
import { NextResponse, type NextRequest } from "next/server";
import { parseSignedRequest } from "@/lib/crypto";
import { deleteInstagramAccount } from "@/lib/deletion";
import { env, isBackendConfigured } from "@/lib/env";
import { absoluteUrl } from "@/lib/site";

export const dynamic = "force-dynamic";

/** Meta's data deletion request callback. Must return { url, confirmation_code }. */
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
  const confirmation = randomBytes(8).toString("hex");
  return NextResponse.json({
    url: absoluteUrl(`/data-deletion?confirmation=${confirmation}`),
    confirmation_code: confirmation,
  });
}
