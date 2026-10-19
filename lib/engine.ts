import { supabaseAdmin } from "@/lib/supabase/admin";
import { decrypt } from "@/lib/crypto";
import { FREE_DM_LIMIT } from "@/lib/plans";
import { siteUrl } from "@/lib/site";
import { fillTemplate, matchesKeywords, type MatchMode } from "@/lib/match";
import { getUserProfile, replyToComment, sendMessage, sendPrivateReply } from "@/lib/instagram";

export const DEFAULT_OPENER = "Hey! Reply to this message with anything and I'll send the link right over 👇";
export const DEFAULT_FOLLOW_PROMPT =
  "Almost there — follow {account} first, then reply \"done\" here and the link is yours.";

type Account = {
  id: string;
  user_id: string;
  ig_user_id: string;
  username: string | null;
  access_token_enc: string;
};

type Automation = {
  id: string;
  user_id: string;
  ig_account_id: string;
  trigger: "comment" | "dm";
  media_id: string | null;
  match_mode: MatchMode;
  keywords: string[];
  dm_message: string;
  link_url: string | null;
  follow_gate: boolean;
  opener_message: string | null;
  public_replies: string[] | null;
  short_code: string;
  created_at: string;
};

export type CommentValue = {
  id: string;
  text?: string;
  from?: { id: string; username?: string };
  media?: { id: string; media_product_type?: string };
  parent_id?: string;
};

export type MessagingEvent = {
  sender?: { id: string };
  recipient?: { id: string };
  timestamp?: number;
  message?: { mid?: string; text?: string; is_echo?: boolean; quick_reply?: { payload?: string } };
  postback?: { mid?: string; title?: string; payload?: string };
};

function errorMessage(e: unknown): string {
  return e instanceof Error ? e.message.slice(0, 500) : "Unknown error";
}

export function trackedLink(a: Pick<Automation, "short_code" | "link_url">): string | null {
  if (!a.link_url) return null;
  return `${siteUrl()}/r/${a.short_code}`;
}

export function composeDm(a: Automation, username?: string): string {
  const message = fillTemplate(a.dm_message, { username });
  const link = trackedLink(a);
  return link ? `${message}\n\n${link}` : message;
}

async function loadAccount(igUserId: string): Promise<Account | null> {
  const { data } = await supabaseAdmin()
    .from("ig_accounts")
    .select("id,user_id,ig_user_id,username,access_token_enc")
    .eq("ig_user_id", igUserId)
    .maybeSingle();
  return (data as Account | null) ?? null;
}

async function underQuota(userId: string): Promise<boolean> {
  const db = supabaseAdmin();
  const { data: profile } = await db.from("profiles").select("plan").eq("id", userId).maybeSingle();
  if (profile?.plan && profile.plan !== "free") return true;
  const start = new Date();
  start.setUTCDate(1);
  start.setUTCHours(0, 0, 0, 0);
  const { count } = await db
    .from("events")
    .select("id", { count: "exact", head: true })
    .eq("user_id", userId)
    .eq("status", "sent")
    .gte("created_at", start.toISOString());
  return (count ?? 0) < FREE_DM_LIMIT;
}

async function rememberContact(account: Account, igsid: string | undefined, username: string | undefined) {
  if (!igsid) return;
  const db = supabaseAdmin();
  const now = new Date().toISOString();
  const { data: existing } = await db
    .from("contacts")
    .select("id,interactions")
    .eq("ig_account_id", account.id)
    .eq("igsid", igsid)
    .maybeSingle();
  if (existing) {
    await db
      .from("contacts")
      .update({ last_seen_at: now, interactions: (existing.interactions ?? 0) + 1, ...(username ? { username } : {}) })
      .eq("id", existing.id);
  } else {
    await db.from("contacts").insert({
      user_id: account.user_id,
      ig_account_id: account.id,
      igsid,
      username: username ?? null,
      first_seen_at: now,
      last_seen_at: now,
    });
  }
}

/** Picks the automation for a comment: post-specific rules win over "any post" rules. */
function pickAutomation(automations: Automation[], mediaId: string | undefined, text: string): Automation | null {
  const candidates = automations.filter(
    (a) => (!a.media_id || a.media_id === mediaId) && matchesKeywords(text, a.match_mode, a.keywords ?? []),
  );
  candidates.sort((a, b) => Number(Boolean(b.media_id)) - Number(Boolean(a.media_id)));
  return candidates[0] ?? null;
}

export async function handleComment(igUserId: string, value: CommentValue): Promise<string> {
  if (!value?.id || !value.from?.id) return "ignored: malformed";
  if (value.from.id === igUserId) return "ignored: own comment";

  const account = await loadAccount(igUserId);
  if (!account) return "ignored: unknown account";

  const db = supabaseAdmin();
  const { data: rows } = await db
    .from("automations")
    .select("*")
    .eq("ig_account_id", account.id)
    .eq("is_active", true)
    .eq("trigger", "comment");

  const automation = pickAutomation((rows ?? []) as Automation[], value.media?.id, value.text ?? "");
  if (!automation) return "ignored: no match";

  // Unique (ig_account_id, external_id) makes Meta's webhook retries harmless.
  const { data: event, error: insertError } = await db
    .from("events")
    .insert({
      user_id: account.user_id,
      ig_account_id: account.id,
      automation_id: automation.id,
      kind: "comment",
      external_id: value.id,
      media_id: value.media?.id ?? null,
      from_id: value.from.id,
      from_username: value.from.username ?? null,
      text: (value.text ?? "").slice(0, 1000),
      status: "matched",
    })
    .select("id")
    .single();
  if (insertError || !event) return "ignored: duplicate";

  if (!(await underQuota(account.user_id))) {
    await db.from("events").update({ status: "skipped", error: "Monthly DM limit reached on the Free plan" }).eq("id", event.id);
    return "skipped: quota";
  }

  const token = decrypt(account.access_token_enc);
  try {
    const firstMessage = automation.follow_gate
      ? automation.opener_message || DEFAULT_OPENER
      : composeDm(automation, value.from.username);
    const sent = await sendPrivateReply(igUserId, token, value.id, firstMessage);

    if (automation.follow_gate && sent.recipient_id) {
      await db.from("conversations").upsert(
        {
          ig_account_id: account.id,
          automation_id: automation.id,
          igsid: sent.recipient_id,
          comment_id: value.id,
          stage: "awaiting_reply",
          updated_at: new Date().toISOString(),
        },
        { onConflict: "ig_account_id,igsid,automation_id" },
      );
    }

    const replies = (automation.public_replies ?? []).filter(Boolean);
    if (replies.length) {
      const reply = fillTemplate(replies[Math.floor(Math.random() * replies.length)], { username: value.from.username });
      await replyToComment(value.id, token, reply).catch(() => undefined);
    }

    await db.from("events").update({ status: "sent", recipient_id: sent.recipient_id ?? null }).eq("id", event.id);
    await db.rpc("increment_sent", { a_id: automation.id });
    await rememberContact(account, sent.recipient_id, value.from.username);
    return "sent";
  } catch (e) {
    await db.from("events").update({ status: "failed", error: errorMessage(e) }).eq("id", event.id);
    return `failed: ${errorMessage(e)}`;
  }
}

export async function handleMessaging(igUserId: string, m: MessagingEvent): Promise<string> {
  const senderId = m.sender?.id;
  if (!senderId || senderId === igUserId || m.message?.is_echo) return "ignored";
  const text = m.message?.text ?? m.postback?.title ?? m.postback?.payload ?? "";
  const mid = m.message?.mid ?? m.postback?.mid ?? `${senderId}:${m.timestamp ?? Date.now()}`;

  const account = await loadAccount(igUserId);
  if (!account) return "ignored: unknown account";
  const db = supabaseAdmin();
  const token = decrypt(account.access_token_enc);

  // 1. Someone replying to a follow-to-unlock opener.
  const { data: convo } = await db
    .from("conversations")
    .select("id,automation_id,stage")
    .eq("ig_account_id", account.id)
    .eq("igsid", senderId)
    .in("stage", ["awaiting_reply", "awaiting_follow"])
    .order("updated_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  if (convo) {
    const { data: automation } = await db.from("automations").select("*").eq("id", convo.automation_id).maybeSingle();
    if (automation) {
      let follows = true;
      let username: string | undefined;
      try {
        const profile = await getUserProfile(senderId, token);
        username = profile.username;
        // Fail open: if Instagram doesn't return follow status, deliver anyway.
        follows = profile.is_user_follow_business !== false;
      } catch {
        follows = true;
      }
      try {
        if (follows) {
          await sendMessage(igUserId, token, senderId, composeDm(automation as Automation, username));
          await db.from("conversations").update({ stage: "done", updated_at: new Date().toISOString() }).eq("id", convo.id);
        } else {
          const handle = account.username ? `@${account.username}` : "this account";
          await sendMessage(igUserId, token, senderId, DEFAULT_FOLLOW_PROMPT.replace("{account}", handle));
          await db
            .from("conversations")
            .update({ stage: "awaiting_follow", updated_at: new Date().toISOString() })
            .eq("id", convo.id);
        }
        await rememberContact(account, senderId, username);
        return follows ? "sent: unlocked" : "sent: follow prompt";
      } catch (e) {
        return `failed: ${errorMessage(e)}`;
      }
    }
  }

  // 2. Keyword automations on DMs (this also covers text replies to Stories).
  const { data: rows } = await db
    .from("automations")
    .select("*")
    .eq("ig_account_id", account.id)
    .eq("is_active", true)
    .eq("trigger", "dm");
  const automation = ((rows ?? []) as Automation[]).find((a) => matchesKeywords(text, a.match_mode, a.keywords ?? []));
  if (!automation) return "ignored: no match";

  const { data: event, error } = await db
    .from("events")
    .insert({
      user_id: account.user_id,
      ig_account_id: account.id,
      automation_id: automation.id,
      kind: "dm",
      external_id: mid,
      from_id: senderId,
      text: text.slice(0, 1000),
      status: "matched",
    })
    .select("id")
    .single();
  if (error || !event) return "ignored: duplicate";

  if (!(await underQuota(account.user_id))) {
    await db.from("events").update({ status: "skipped", error: "Monthly DM limit reached on the Free plan" }).eq("id", event.id);
    return "skipped: quota";
  }

  try {
    await sendMessage(igUserId, token, senderId, composeDm(automation));
    await db.from("events").update({ status: "sent", recipient_id: senderId }).eq("id", event.id);
    await db.rpc("increment_sent", { a_id: automation.id });
    await rememberContact(account, senderId, undefined);
    return "sent";
  } catch (e) {
    await db.from("events").update({ status: "failed", error: errorMessage(e) }).eq("id", event.id);
    return `failed: ${errorMessage(e)}`;
  }
}
