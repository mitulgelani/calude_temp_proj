import { supabaseAdmin } from "@/lib/supabase/admin";

/** Removes an Instagram account and everything attached to it (automations, events, contacts cascade). */
export async function deleteInstagramAccount(igUserId: string): Promise<boolean> {
  const { error, count } = await supabaseAdmin()
    .from("ig_accounts")
    .delete({ count: "exact" })
    .eq("ig_user_id", igUserId);
  return !error && (count ?? 0) > 0;
}
