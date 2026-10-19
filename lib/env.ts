export const env = {
  supabaseUrl: process.env.NEXT_PUBLIC_SUPABASE_URL ?? "",
  supabaseAnonKey: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? "",
  supabaseServiceKey: process.env.SUPABASE_SERVICE_ROLE_KEY ?? "",
  igAppId: process.env.INSTAGRAM_APP_ID ?? "",
  igAppSecret: process.env.INSTAGRAM_APP_SECRET ?? "",
  igVerifyToken: process.env.INSTAGRAM_WEBHOOK_VERIFY_TOKEN ?? "",
  igApiVersion: process.env.INSTAGRAM_API_VERSION ?? "v25.0",
  encryptionKey: process.env.ENCRYPTION_KEY ?? "",
  billingWebhookSecret: process.env.DODO_WEBHOOK_SECRET ?? "",
};

/** Supabase (auth + database) is configured. Without it the app runs in demo mode. */
export function isSupabaseConfigured(): boolean {
  return Boolean(env.supabaseUrl && env.supabaseAnonKey);
}

/** Server-side work (webhooks) also needs the service role key. */
export function isBackendConfigured(): boolean {
  return isSupabaseConfigured() && Boolean(env.supabaseServiceKey);
}

export function isInstagramConfigured(): boolean {
  return Boolean(env.igAppId && env.igAppSecret);
}
