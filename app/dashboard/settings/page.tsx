import { DisconnectButton } from "@/components/dashboard/DisconnectButton";
import { getDashboardData } from "@/lib/dashboard";
import { env, isBackendConfigured, isInstagramConfigured, isSupabaseConfigured } from "@/lib/env";
import { customerPortalUrl } from "@/lib/billing";
import { PLANS, checkoutUrl, formatPrice, planLabel } from "@/lib/plans";

type Props = { searchParams: Promise<{ connected?: string; error?: string; upgraded?: string }> };

const ERRORS: Record<string, string> = {
  denied: "Instagram access wasn't approved, so nothing was connected.",
  state: "The connection link expired. Start again from this page.",
  exchange: "Instagram didn't accept the connection. Make sure it's a Creator or Business account and try again.",
  limit: "Your plan's account limit is reached. Upgrade to Studio to connect up to five accounts.",
  taken: "That Instagram account is already connected to another LinkPlz workspace.",
  setup: "Instagram connections aren't switched on yet: the app's Instagram and database keys still need to be added.",
};

export default async function SettingsPage({ searchParams }: Props) {
  const sp = await searchParams;
  const data = await getDashboardData();
  const limit = PLANS.find((p) => p.id === data.plan)?.accounts ?? 1;

  const checklist = [
    { done: isSupabaseConfigured(), label: "Database and sign-in (Supabase URL and anon key)" },
    { done: isBackendConfigured(), label: "Background processing (Supabase service role key)" },
    { done: isInstagramConfigured(), label: "Instagram app (app ID and secret)" },
    { done: Boolean(env.igVerifyToken), label: "Webhook verify token" },
  ];
  const ready = checklist.every((c) => c.done);

  return (
    <div className="space-y-8">
      <h1 className="text-3xl font-extrabold tracking-[-0.035em] sm:text-4xl">Settings</h1>

      {sp.connected ? (
        <p role="status" className="rounded-2xl bg-[#e6f7f0] px-4 py-3 text-sm font-medium text-mint">
          @{sp.connected} is connected. Create an automation to start sending DMs.
        </p>
      ) : null}
      {sp.error ? (
        <p role="alert" className="rounded-2xl bg-[#fdecec] px-4 py-3 text-sm text-danger">
          {ERRORS[sp.error] ?? "Something went wrong connecting Instagram. Try again."}
        </p>
      ) : null}

      <section className="rounded-[24px] bg-paper p-5 ring-1 ring-line sm:p-6">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <h2 className="text-lg font-bold">Instagram accounts</h2>
            <p className="text-sm text-ink-soft">
              {data.accounts.length} of {limit} on the {planLabel(data.plan)} plan
            </p>
          </div>
          {data.accounts.length < limit ? (
            <a href="/api/instagram/connect" className="btn btn-primary btn-sm">
              Connect Instagram
            </a>
          ) : null}
        </div>
        <ul className="mt-4 divide-y divide-line">
          {data.accounts.map((a) => {
            const days = a.token_expires_at ? Math.round((new Date(a.token_expires_at).getTime() - Date.now()) / 86_400_000) : null;
            return (
              <li key={a.id} className="flex items-center justify-between gap-4 py-4">
                <div className="flex min-w-0 items-center gap-3">
                  {a.profile_picture_url ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={a.profile_picture_url} alt="" className="h-10 w-10 rounded-full object-cover" />
                  ) : (
                    <span className="grid h-10 w-10 place-items-center rounded-full bg-[linear-gradient(135deg,#ffb36b,#ff5fa2,#5b32ff)] font-bold text-white">
                      {(a.username ?? "?")[0].toUpperCase()}
                    </span>
                  )}
                  <div className="min-w-0">
                    <p className="truncate font-semibold">@{a.username}</p>
                    <p className="text-xs text-muted">
                      {a.webhook_subscribed ? "Receiving comments" : "Not receiving comments yet; reconnect to fix"}
                      {days !== null ? ` · access renews in ${days} days` : ""}
                    </p>
                  </div>
                </div>
                <DisconnectButton id={a.id} username={a.username} />
              </li>
            );
          })}
        </ul>
        <p className="mt-4 text-xs text-muted">
          In Instagram, make sure Settings → Messages and story replies → Message controls → Connected tools → Allow access to messages is on.
        </p>
      </section>

      <section id="plan" className="scroll-mt-8 rounded-[24px] bg-paper p-5 ring-1 ring-line sm:p-6">
        <h2 className="text-lg font-bold">Plan</h2>
        <p className="text-sm text-ink-soft">You&apos;re on {planLabel(data.plan)}.</p>
        <div className="mt-4 grid gap-3 md:grid-cols-2">
          {PLANS.filter((p) => p.id !== "free").map((p) => {
            const current = p.id === data.plan;
            const href = checkoutUrl(p.id, "monthly");
            return (
              <div key={p.id} className={`rounded-2xl p-4 ${current ? "bg-ink text-white" : "bg-mist"}`}>
                <p className="font-semibold">{p.name}</p>
                <p className={`text-sm ${current ? "text-white/70" : "text-ink-soft"}`}>
                  {formatPrice(p.price.usd.monthly, "usd")} or {formatPrice(p.price.inr.monthly, "inr")} a month · {p.features[0]}
                </p>
                {current ? (
                  <p className="mt-3 text-sm font-semibold text-marker">Current plan</p>
                ) : href ? (
                  <a href={href} className="btn btn-primary btn-sm mt-3">
                    Upgrade to {p.name}
                  </a>
                ) : (
                  <p className="mt-3 text-xs text-muted">Checkout opens once payments are connected.</p>
                )}
              </div>
            );
          })}
        </div>
        {sp.upgraded && data.plan === "free" ? (
          <p className="mt-3 rounded-xl bg-mist p-3 text-sm" role="status">
            Payment received. Your plan updates within a minute; refresh this page if it still says Free.
          </p>
        ) : null}
        <p className="mt-3 text-xs text-muted">
          Payments are handled by Dodo Payments.{" "}
          {data.plan !== "free" ? (
            <a href={customerPortalUrl()} className="underline" target="_blank" rel="noopener noreferrer">
              Manage or cancel your subscription
            </a>
          ) : (
            "Cancel any time."
          )}
        </p>
      </section>

      {!ready ? (
        <section className="rounded-[24px] bg-[#fff6cc] p-5 sm:p-6">
          <h2 className="text-lg font-bold">Finish setting up this workspace</h2>
          <p className="mt-1 text-sm text-ink-soft">These keys are added as environment variables in your hosting dashboard. The README lists where each one comes from.</p>
          <ul className="mt-4 space-y-2 text-sm">
            {checklist.map((c) => (
              <li key={c.label} className="flex items-center gap-2.5">
                <span className={`grid h-5 w-5 place-items-center rounded-full text-[0.65rem] font-bold ${c.done ? "bg-mint text-white" : "bg-white text-muted ring-1 ring-line"}`}>
                  {c.done ? "✓" : ""}
                </span>
                {c.label}
              </li>
            ))}
          </ul>
        </section>
      ) : null}
    </div>
  );
}
