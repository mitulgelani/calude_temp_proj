import Link from "next/link";
import { ActivityList } from "@/components/dashboard/ActivityList";
import { getDashboardData } from "@/lib/dashboard";
import { FREE_DM_LIMIT } from "@/lib/plans";

export default async function OverviewPage() {
  const data = await getDashboardData();
  const active = data.automations.filter((a) => a.is_active).length;
  const clicks = data.automations.reduce((n, a) => n + a.click_count, 0);
  const sentAll = data.automations.reduce((n, a) => n + a.sent_count, 0);
  const ctr = sentAll ? Math.round((clicks / sentAll) * 100) : 0;
  const free = data.plan === "free";
  const usage = Math.min(100, Math.round((data.sentThisMonth / FREE_DM_LIMIT) * 100));
  const fmt = new Intl.NumberFormat("en-US");
  const account = data.accounts[0];

  return (
    <div className="space-y-8">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className="text-3xl font-extrabold tracking-[-0.035em] sm:text-4xl">
            {account?.username ? `@${account.username}` : "Your workspace"}
          </h1>
          <p className="mt-1 text-ink-soft">
            {active ? `${active} automation${active === 1 ? " is" : "s are"} answering comments right now.` : "No automations are running yet."}
          </p>
        </div>
        <Link href="/dashboard/automations/new" className="btn btn-violet">
          New automation
        </Link>
      </div>

      {!data.accounts.length ? (
        <section className="flex flex-col gap-4 rounded-[24px] bg-ink p-6 text-white sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h2 className="text-xl font-bold">Connect your Instagram account</h2>
            <p className="mt-1 text-white/70">You&apos;ll log in on Instagram&apos;s own page. It takes about 30 seconds.</p>
          </div>
          <a href="/api/instagram/connect" className="btn bg-white text-ink hover:bg-marker">
            Connect Instagram
          </a>
        </section>
      ) : null}

      <section aria-label="This month" className="grid grid-cols-2 gap-3 lg:grid-cols-4">
        <div className="rounded-[22px] bg-paper p-5 ring-1 ring-line">
          <p className="text-sm text-muted">DMs sent this month</p>
          <p className="mt-1 text-2xl font-bold tabular-nums tracking-[-0.03em] sm:text-3xl">{fmt.format(data.sentThisMonth)}</p>
          {free ? (
            <div className="mt-3">
              <div className="h-1.5 rounded-full bg-mist" role="progressbar" aria-valuenow={usage} aria-valuemin={0} aria-valuemax={100} aria-label="Free plan usage">
                <div className={`h-1.5 rounded-full ${usage > 85 ? "bg-danger" : "bg-violet"}`} style={{ width: `${usage}%` }} />
              </div>
              <p className="mt-1.5 text-xs text-muted">
                {fmt.format(FREE_DM_LIMIT - Math.min(FREE_DM_LIMIT, data.sentThisMonth))} left on Free
              </p>
            </div>
          ) : (
            <p className="mt-3 text-xs text-muted">Unlimited on your plan</p>
          )}
        </div>
        <Stat label="Link clicks" value={fmt.format(clicks)} note="Across all automations" />
        <Stat label="Click-through rate" value={`${ctr}%`} note="Clicks per DM sent" />
        <Stat label="Active automations" value={String(active)} note={`${data.automations.length} in total`} />
      </section>

      <div className="grid gap-6 lg:grid-cols-[1.4fr_1fr]">
        <section className="rounded-[24px] bg-paper p-5 ring-1 ring-line sm:p-6">
          <h2 className="text-lg font-bold">Latest activity</h2>
          <div className="mt-2">
            <ActivityList events={data.events.slice(0, 8)} automations={data.automations} />
          </div>
        </section>
        <section className="rounded-[24px] bg-paper p-5 ring-1 ring-line sm:p-6">
          <div className="flex items-center justify-between">
            <h2 className="text-lg font-bold">Top automations</h2>
            <Link href="/dashboard/automations" className="text-sm font-semibold text-violet hover:underline">
              See all
            </Link>
          </div>
          {data.automations.length ? (
            <ul className="mt-3 space-y-3">
              {[...data.automations]
                .sort((a, b) => b.sent_count - a.sent_count)
                .slice(0, 4)
                .map((a) => (
                  <li key={a.id}>
                    <Link href={`/dashboard/automations/${a.id}`} className="block rounded-2xl bg-mist p-4 hover:ring-1 hover:ring-line">
                      <div className="flex items-center justify-between gap-3">
                        <p className="truncate font-semibold">{a.name}</p>
                        <span className={`h-2 w-2 shrink-0 rounded-full ${a.is_active ? "bg-mint" : "bg-line"}`} aria-label={a.is_active ? "On" : "Paused"} />
                      </div>
                      <p className="mt-1 text-sm text-ink-soft">
                        {fmt.format(a.sent_count)} sent · {fmt.format(a.click_count)} clicks
                      </p>
                    </Link>
                  </li>
                ))}
            </ul>
          ) : (
            <p className="mt-3 text-sm text-ink-soft">Your automations will show up here with their send and click counts.</p>
          )}
        </section>
      </div>
    </div>
  );
}

function Stat({ label, value, note }: { label: string; value: string; note: string }) {
  return (
    <div className="rounded-[22px] bg-paper p-5 ring-1 ring-line">
      <p className="text-sm text-muted">{label}</p>
      <p className="mt-1 text-2xl font-bold tabular-nums tracking-[-0.03em] sm:text-3xl">{value}</p>
      <p className="mt-3 text-xs text-muted">{note}</p>
    </div>
  );
}
