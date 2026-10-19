import Link from "next/link";
import { AutomationActions } from "@/components/dashboard/AutomationActions";
import { getDashboardData } from "@/lib/dashboard";
import { DEMO_MEDIA } from "@/lib/demo";

type Props = { searchParams: Promise<{ saved?: string }> };

export default async function AutomationsPage({ searchParams }: Props) {
  const { saved } = await searchParams;
  const data = await getDashboardData();
  const fmt = new Intl.NumberFormat("en-US");

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className="text-3xl font-extrabold tracking-[-0.035em] sm:text-4xl">Automations</h1>
          <p className="mt-1 text-ink-soft">Each one listens for keywords and sends your DM.</p>
        </div>
        <Link href="/dashboard/automations/new" className="btn btn-violet">
          New automation
        </Link>
      </div>

      {saved ? (
        <p role="status" className="rounded-2xl bg-[#e6f7f0] px-4 py-3 text-sm font-medium text-mint">
          “{saved}” is saved and listening for comments.
        </p>
      ) : null}

      {data.automations.length === 0 ? (
        <div className="rounded-[24px] border border-dashed border-line px-6 py-16 text-center">
          <h2 className="text-xl font-bold">Create your first automation</h2>
          <p className="mx-auto mt-2 max-w-md text-ink-soft">
            Pick a Reel, choose a keyword like LINK, and write the DM. It starts answering comments the moment you save.
          </p>
          <Link href="/dashboard/automations/new" className="btn btn-primary mt-6">
            New automation
          </Link>
        </div>
      ) : (
        <ul className="space-y-3">
          {data.automations.map((a) => {
            const caption = data.demo ? DEMO_MEDIA.find((m) => m.id === a.media_id)?.caption : null;
            return (
              <li key={a.id} className="flex flex-col gap-4 rounded-[24px] bg-paper p-5 ring-1 ring-line sm:flex-row sm:items-center sm:justify-between">
                <div className="min-w-0">
                  <Link href={`/dashboard/automations/${a.id}`} className="text-lg font-bold tracking-[-0.01em] hover:underline">
                    {a.name}
                  </Link>
                  <p className="mt-1 text-sm text-ink-soft">
                    {a.trigger === "dm" ? "When someone DMs " : a.media_id ? "When someone comments " : "When someone comments on any post "}
                    {a.match_mode === "any"
                      ? "anything"
                      : a.keywords.map((k, i) => (
                          <span key={k}>
                            {i ? " or " : ""}
                            <span className="rounded bg-marker px-1 font-semibold text-ink">{k}</span>
                          </span>
                        ))}
                    {a.follow_gate ? " · followers only" : ""}
                  </p>
                  {caption || a.media_permalink ? (
                    <p className="mt-1 truncate text-xs text-muted">On: {caption ?? a.media_permalink}</p>
                  ) : null}
                  <p className="mt-2 text-sm">
                    <span className="font-semibold tabular-nums">{fmt.format(a.sent_count)}</span> <span className="text-muted">sent</span>
                    <span className="mx-2 text-line">|</span>
                    <span className="font-semibold tabular-nums">{fmt.format(a.click_count)}</span> <span className="text-muted">clicks</span>
                  </p>
                </div>
                <AutomationActions id={a.id} active={a.is_active} canRerun={a.trigger === "comment"} />
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}
