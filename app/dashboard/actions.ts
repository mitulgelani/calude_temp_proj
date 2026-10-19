"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { decrypt, shortCode } from "@/lib/crypto";
import { handleComment } from "@/lib/engine";
import { isBackendConfigured, isSupabaseConfigured } from "@/lib/env";
import { listComments, listMedia } from "@/lib/instagram";
import { parseKeywords, type MatchMode } from "@/lib/match";
import { supabaseAdmin } from "@/lib/supabase/admin";
import { supabaseServer } from "@/lib/supabase/server";

export type ActionState = { ok: boolean; message: string; errors?: Record<string, string> };

const DEMO_MESSAGE = "This is the demo workspace, so nothing was saved. Connect Supabase to go live.";

async function requireUser() {
  const supabase = await supabaseServer();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");
  return { supabase, user };
}

async function currentPlan(userId: string): Promise<string> {
  const { data } = await supabaseAdmin().from("profiles").select("plan").eq("id", userId).maybeSingle();
  return (data?.plan as string | undefined) ?? "free";
}

export async function saveAutomation(_prev: ActionState, form: FormData): Promise<ActionState> {
  if (!isSupabaseConfigured()) return { ok: false, message: DEMO_MESSAGE };
  const { supabase, user } = await requireUser();

  const id = String(form.get("id") ?? "");
  const name = String(form.get("name") ?? "").trim();
  const accountId = String(form.get("ig_account_id") ?? "");
  const trigger = form.get("trigger") === "dm" ? "dm" : "comment";
  const mediaId = String(form.get("media_id") ?? "").trim() || null;
  const mediaThumb = String(form.get("media_thumbnail") ?? "").trim() || null;
  const mediaPermalink = String(form.get("media_permalink") ?? "").trim() || null;
  const modeRaw = String(form.get("match_mode") ?? "contains");
  const matchMode: MatchMode = modeRaw === "exact" || modeRaw === "any" ? modeRaw : "contains";
  const keywords = parseKeywords(String(form.get("keywords") ?? ""));
  const dmMessage = String(form.get("dm_message") ?? "").trim();
  const linkUrl = String(form.get("link_url") ?? "").trim() || null;
  const followGate = form.get("follow_gate") === "on";
  const opener = String(form.get("opener_message") ?? "").trim() || null;
  const publicReplies = String(form.get("public_replies") ?? "")
    .split("\n")
    .map((s) => s.trim())
    .filter(Boolean)
    .slice(0, 10);

  const errors: Record<string, string> = {};
  if (!name) errors.name = "Give the automation a name you'll recognise.";
  if (!accountId) errors.ig_account_id = "Connect an Instagram account first.";
  if (matchMode !== "any" && keywords.length === 0) errors.keywords = "Add at least one keyword, or choose “Any comment”.";
  if (!dmMessage) errors.dm_message = "Write the message people will receive.";
  if (dmMessage.length > 900) errors.dm_message = "Keep the message under 900 characters; Instagram caps DMs at 1,000 including the link.";
  if (linkUrl && !/^https?:\/\/\S+\.\S+/i.test(linkUrl)) errors.link_url = "Use a full link starting with https://";
  if (followGate && (await currentPlan(user.id)) === "free") errors.follow_gate = "Follow-to-unlock is on the Creator plan.";
  if (Object.keys(errors).length) return { ok: false, message: "Check the highlighted fields.", errors };

  const { data: account } = await supabase.from("ig_accounts").select("id").eq("id", accountId).maybeSingle();
  if (!account) return { ok: false, message: "That Instagram account isn't connected to your workspace." };

  const row = {
    user_id: user.id,
    ig_account_id: accountId,
    name: name.slice(0, 80),
    trigger,
    media_id: trigger === "comment" ? mediaId : null,
    media_thumbnail: trigger === "comment" ? mediaThumb : null,
    media_permalink: trigger === "comment" ? mediaPermalink : null,
    match_mode: matchMode,
    keywords,
    dm_message: dmMessage,
    link_url: linkUrl,
    follow_gate: followGate,
    opener_message: opener,
    public_replies: trigger === "comment" ? publicReplies : [],
    updated_at: new Date().toISOString(),
  };

  const { error } = id
    ? await supabase.from("automations").update(row).eq("id", id)
    : await supabase.from("automations").insert({ ...row, short_code: shortCode() });
  if (error) return { ok: false, message: `Couldn't save: ${error.message}` };

  revalidatePath("/dashboard", "layout");
  redirect(`/dashboard/automations?saved=${encodeURIComponent(name)}`);
}

export async function setAutomationActive(id: string, active: boolean): Promise<ActionState> {
  if (!isSupabaseConfigured()) return { ok: false, message: DEMO_MESSAGE };
  const { supabase } = await requireUser();
  const { error } = await supabase.from("automations").update({ is_active: active }).eq("id", id);
  revalidatePath("/dashboard", "layout");
  return error ? { ok: false, message: error.message } : { ok: true, message: active ? "Automation turned on" : "Automation paused" };
}

export async function deleteAutomation(id: string): Promise<ActionState> {
  if (!isSupabaseConfigured()) return { ok: false, message: DEMO_MESSAGE };
  const { supabase } = await requireUser();
  const { error } = await supabase.from("automations").delete().eq("id", id);
  revalidatePath("/dashboard", "layout");
  return error ? { ok: false, message: error.message } : { ok: true, message: "Automation deleted" };
}

/** Sends the DM to matching comments from the last 7 days (Instagram's private-reply window). */
export async function rerunAutomation(id: string): Promise<ActionState> {
  if (!isBackendConfigured()) return { ok: false, message: DEMO_MESSAGE };
  const { supabase, user } = await requireUser();
  if ((await currentPlan(user.id)) === "free") return { ok: false, message: "Re-running past comments is on the Creator plan." };

  const { data: automation } = await supabase.from("automations").select("id,ig_account_id,media_id,trigger").eq("id", id).maybeSingle();
  if (!automation || automation.trigger !== "comment") return { ok: false, message: "Only comment automations can be re-run." };

  const { data: account } = await supabaseAdmin()
    .from("ig_accounts")
    .select("ig_user_id,access_token_enc")
    .eq("id", automation.ig_account_id)
    .maybeSingle();
  if (!account) return { ok: false, message: "The Instagram account is no longer connected." };

  const token = decrypt(account.access_token_enc);
  const cutoff = Date.now() - 7 * 86_400_000 + 10 * 60_000;
  const started = Date.now();
  let sent = 0;
  let checked = 0;
  try {
    const mediaIds: string[] = automation.media_id
      ? [automation.media_id]
      : (await listMedia(account.ig_user_id, token, 10)).map((m) => m.id);
    for (const mediaId of mediaIds) {
      const comments = await listComments(mediaId, token);
      for (const c of comments) {
        if (Date.now() - started > 45_000) break;
        if (!c.from?.id || (c.timestamp && new Date(c.timestamp).getTime() < cutoff)) continue;
        checked++;
        const result = await handleComment(account.ig_user_id, {
          id: c.id,
          text: c.text,
          from: { id: c.from.id, username: c.from.username ?? c.username },
          media: { id: mediaId },
        });
        if (result === "sent") sent++;
      }
    }
  } catch (e) {
    return { ok: false, message: e instanceof Error ? e.message : "Instagram returned an error" };
  }
  revalidatePath("/dashboard", "layout");
  return { ok: true, message: sent ? `Sent ${sent} DM${sent === 1 ? "" : "s"} to people who commented earlier.` : `Checked ${checked} recent comments; everyone who matched already has their DM.` };
}

export async function disconnectAccount(id: string): Promise<ActionState> {
  if (!isSupabaseConfigured()) return { ok: false, message: DEMO_MESSAGE };
  const { supabase } = await requireUser();
  const { error } = await supabase.from("ig_accounts").delete().eq("id", id);
  revalidatePath("/dashboard", "layout");
  return error ? { ok: false, message: error.message } : { ok: true, message: "Instagram account disconnected and its data deleted" };
}

export async function signOut() {
  if (isSupabaseConfigured()) {
    const supabase = await supabaseServer();
    await supabase.auth.signOut();
  }
  redirect("/");
}
