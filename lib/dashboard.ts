import { redirect } from "next/navigation";
import { cache } from "react";
import { DEMO_DATA } from "@/lib/demo";
import { isSupabaseConfigured } from "@/lib/env";
import { supabaseServer } from "@/lib/supabase/server";
import type { AccountView, AutomationView, DashboardData, EventView } from "@/lib/types";

export const ACCOUNT_COLUMNS = "id,ig_user_id,username,name,profile_picture_url,token_expires_at,webhook_subscribed";

/** Loads everything the dashboard shows. Falls back to sample data when Supabase isn't configured yet. */
export const getDashboardData = cache(async (): Promise<DashboardData> => {
  if (!isSupabaseConfigured()) return DEMO_DATA;

  const supabase = await supabaseServer();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login?next=/dashboard");

  const monthStart = new Date();
  monthStart.setUTCDate(1);
  monthStart.setUTCHours(0, 0, 0, 0);

  const [profile, accounts, automations, events, sent] = await Promise.all([
    supabase.from("profiles").select("plan").eq("id", user.id).maybeSingle(),
    supabase.from("ig_accounts").select(ACCOUNT_COLUMNS).order("created_at"),
    supabase.from("automations").select("*").order("created_at", { ascending: false }),
    supabase
      .from("events")
      .select("id,automation_id,kind,from_username,text,status,error,created_at")
      .order("created_at", { ascending: false })
      .limit(30),
    supabase
      .from("events")
      .select("id", { count: "exact", head: true })
      .eq("status", "sent")
      .gte("created_at", monthStart.toISOString()),
  ]);

  return {
    demo: false,
    email: user.email ?? null,
    plan: (profile.data?.plan as string | undefined) ?? "free",
    accounts: (accounts.data ?? []) as unknown as AccountView[],
    automations: (automations.data ?? []) as unknown as AutomationView[],
    events: (events.data ?? []) as unknown as EventView[],
    sentThisMonth: sent.count ?? 0,
  };
});

export function timeAgo(iso: string): string {
  const s = Math.max(1, Math.round((Date.now() - new Date(iso).getTime()) / 1000));
  if (s < 60) return `${s}s ago`;
  const m = Math.round(s / 60);
  if (m < 60) return `${m}m ago`;
  const h = Math.round(m / 60);
  if (h < 24) return `${h}h ago`;
  return `${Math.round(h / 24)}d ago`;
}
