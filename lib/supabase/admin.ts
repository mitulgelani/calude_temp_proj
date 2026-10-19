import { createClient } from "@supabase/supabase-js";
import { env } from "@/lib/env";

/** Service-role client for webhooks and background work. Never import from client code. */
export function supabaseAdmin() {
  return createClient(env.supabaseUrl, env.supabaseServiceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}
