import { env } from "@/lib/env";
import { siteUrl } from "@/lib/site";

/**
 * Instagram API with Instagram Login (graph.instagram.com).
 * Docs: developers.facebook.com/documentation/instagram-platform
 */
const GRAPH = "https://graph.instagram.com";

export const IG_SCOPES = [
  "instagram_business_basic",
  "instagram_business_manage_comments",
  "instagram_business_manage_messages",
];

export const WEBHOOK_FIELDS = ["comments", "live_comments", "messages", "messaging_postbacks"];

export class InstagramError extends Error {
  code?: number;
  constructor(message: string, code?: number) {
    super(message);
    this.code = code;
  }
}

function v(path: string) {
  return `${GRAPH}/${env.igApiVersion}${path}`;
}

async function call<T>(url: string, init?: RequestInit): Promise<T> {
  const res = await fetch(url, { ...init, cache: "no-store" });
  const text = await res.text();
  let json: unknown = null;
  try {
    json = text ? JSON.parse(text) : null;
  } catch {
    json = null;
  }
  if (!res.ok) {
    const err = (json as { error?: { message?: string; code?: number; error_message?: string } } | null)?.error;
    const message =
      err?.message ?? (json as { error_message?: string } | null)?.error_message ?? `Instagram API error ${res.status}`;
    throw new InstagramError(message, err?.code);
  }
  return json as T;
}

export function redirectUri(): string {
  return `${siteUrl()}/api/instagram/callback`;
}

export function authorizeUrl(state: string): string {
  const params = new URLSearchParams({
    client_id: env.igAppId,
    redirect_uri: redirectUri(),
    response_type: "code",
    scope: IG_SCOPES.join(","),
    state,
    enable_fb_login: "0",
    force_reauth: "true",
  });
  return `https://www.instagram.com/oauth/authorize?${params.toString()}`;
}

export async function exchangeCode(code: string): Promise<{ accessToken: string; userId: string }> {
  const body = new URLSearchParams({
    client_id: env.igAppId,
    client_secret: env.igAppSecret,
    grant_type: "authorization_code",
    redirect_uri: redirectUri(),
    code: code.replace(/#_$/, ""),
  });
  type Short = { access_token?: string; user_id?: string | number; data?: { access_token: string; user_id: string | number }[] };
  const json = await call<Short>("https://api.instagram.com/oauth/access_token", { method: "POST", body });
  const row = json.data?.[0] ?? json;
  if (!row.access_token) throw new InstagramError("Instagram did not return an access token");
  return { accessToken: row.access_token, userId: String(row.user_id) };
}

export async function toLongLived(shortToken: string): Promise<{ accessToken: string; expiresIn: number }> {
  const params = new URLSearchParams({
    grant_type: "ig_exchange_token",
    client_secret: env.igAppSecret,
    access_token: shortToken,
  });
  const json = await call<{ access_token: string; expires_in: number }>(`${GRAPH}/access_token?${params}`);
  return { accessToken: json.access_token, expiresIn: json.expires_in };
}

export async function refreshToken(token: string): Promise<{ accessToken: string; expiresIn: number }> {
  const params = new URLSearchParams({ grant_type: "ig_refresh_token", access_token: token });
  const json = await call<{ access_token: string; expires_in: number }>(`${GRAPH}/refresh_access_token?${params}`);
  return { accessToken: json.access_token, expiresIn: json.expires_in };
}

export type IgProfile = {
  user_id: string;
  username: string;
  name?: string;
  profile_picture_url?: string;
  account_type?: string;
};

export async function getMe(token: string): Promise<IgProfile> {
  const params = new URLSearchParams({
    fields: "user_id,username,name,profile_picture_url,account_type",
    access_token: token,
  });
  const json = await call<IgProfile & { data?: IgProfile[] }>(v(`/me?${params}`));
  const row = json.data?.[0] ?? json;
  return { ...row, user_id: String(row.user_id) };
}

export async function subscribeWebhooks(igUserId: string, token: string): Promise<boolean> {
  const params = new URLSearchParams({ subscribed_fields: WEBHOOK_FIELDS.join(","), access_token: token });
  const json = await call<{ success?: boolean }>(v(`/${igUserId}/subscribed_apps?${params}`), { method: "POST" });
  return Boolean(json.success);
}

export type IgMedia = {
  id: string;
  caption?: string;
  media_type?: string;
  media_url?: string;
  thumbnail_url?: string;
  permalink?: string;
  timestamp?: string;
};

export async function listMedia(igUserId: string, token: string, limit = 24): Promise<IgMedia[]> {
  const params = new URLSearchParams({
    fields: "id,caption,media_type,media_url,thumbnail_url,permalink,timestamp",
    limit: String(limit),
    access_token: token,
  });
  const json = await call<{ data: IgMedia[] }>(v(`/${igUserId}/media?${params}`));
  return json.data ?? [];
}

export type IgComment = {
  id: string;
  text?: string;
  timestamp?: string;
  username?: string;
  from?: { id: string; username?: string };
};

export async function listComments(mediaId: string, token: string): Promise<IgComment[]> {
  const params = new URLSearchParams({
    fields: "id,text,timestamp,username,from",
    limit: "50",
    access_token: token,
  });
  const json = await call<{ data: IgComment[] }>(v(`/${mediaId}/comments?${params}`));
  return json.data ?? [];
}

/** One private reply per comment, within 7 days of the comment. */
export async function sendPrivateReply(igUserId: string, token: string, commentId: string, text: string) {
  return call<{ recipient_id?: string; message_id?: string }>(v(`/${igUserId}/messages`), {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
    body: JSON.stringify({ recipient: { comment_id: commentId }, message: { text } }),
  });
}

/** Regular DM; only allowed inside the 24-hour window after the person messaged you. */
export async function sendMessage(igUserId: string, token: string, igsid: string, text: string) {
  return call<{ recipient_id?: string; message_id?: string }>(v(`/${igUserId}/messages`), {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
    body: JSON.stringify({ recipient: { id: igsid }, message: { text } }),
  });
}

export async function replyToComment(commentId: string, token: string, message: string) {
  const params = new URLSearchParams({ message, access_token: token });
  return call<{ id: string }>(v(`/${commentId}/replies?${params}`), { method: "POST" });
}

export async function getUserProfile(igsid: string, token: string) {
  const params = new URLSearchParams({ fields: "username,is_user_follow_business", access_token: token });
  return call<{ username?: string; is_user_follow_business?: boolean }>(v(`/${igsid}?${params}`));
}
