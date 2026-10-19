import { createCipheriv, createDecipheriv, createHash, createHmac, randomBytes, timingSafeEqual } from "crypto";
import { env } from "@/lib/env";

function key(): Buffer {
  if (env.encryptionKey) {
    const raw = Buffer.from(env.encryptionKey, "base64");
    if (raw.length === 32) return raw;
    return createHash("sha256").update(env.encryptionKey).digest();
  }
  // Fallback so a fresh deploy still works; set ENCRYPTION_KEY in production.
  return createHash("sha256").update(`hookline:${env.igAppSecret}`).digest();
}

/** AES-256-GCM. Output: base64(iv).base64(tag).base64(ciphertext) */
export function encrypt(plain: string): string {
  const iv = randomBytes(12);
  const cipher = createCipheriv("aes-256-gcm", key(), iv);
  const data = Buffer.concat([cipher.update(plain, "utf8"), cipher.final()]);
  return [iv, cipher.getAuthTag(), data].map((b) => b.toString("base64")).join(".");
}

export function decrypt(payload: string): string {
  const [iv, tag, data] = payload.split(".").map((p) => Buffer.from(p, "base64"));
  const decipher = createDecipheriv("aes-256-gcm", key(), iv);
  decipher.setAuthTag(tag);
  return Buffer.concat([decipher.update(data), decipher.final()]).toString("utf8");
}

export function safeEqual(a: string, b: string): boolean {
  const ab = Buffer.from(a);
  const bb = Buffer.from(b);
  return ab.length === bb.length && timingSafeEqual(ab, bb);
}

/** Verifies Meta's X-Hub-Signature-256 header against the raw request body. */
export function verifyMetaSignature(rawBody: string, header: string | null, appSecret: string): boolean {
  if (!header || !appSecret) return false;
  const expected = `sha256=${createHmac("sha256", appSecret).update(rawBody, "utf8").digest("hex")}`;
  return safeEqual(expected, header);
}

/** Parses Meta's signed_request (deauthorize and data-deletion callbacks). */
export function parseSignedRequest(signed: string, appSecret: string): Record<string, unknown> | null {
  const [sig, payload] = signed.split(".");
  if (!sig || !payload) return null;
  const expected = createHmac("sha256", appSecret).update(payload).digest("base64url");
  if (!safeEqual(expected, sig)) return null;
  try {
    return JSON.parse(Buffer.from(payload, "base64url").toString("utf8"));
  } catch {
    return null;
  }
}

export function shortCode(length = 7): string {
  const alphabet = "abcdefghjkmnpqrstuvwxyz23456789";
  const bytes = randomBytes(length);
  return Array.from(bytes, (b) => alphabet[b % alphabet.length]).join("");
}
