import { timeAgo } from "@/lib/dashboard";
import type { AutomationView, EventView } from "@/lib/types";

const STATUS: Record<EventView["status"], { label: string; className: string }> = {
  sent: { label: "DM sent", className: "text-mint" },
  failed: { label: "Not sent", className: "text-danger" },
  skipped: { label: "Skipped", className: "text-muted" },
  matched: { label: "Sending", className: "text-violet" },
};

export function ActivityList({ events, automations }: { events: EventView[]; automations: AutomationView[] }) {
  if (!events.length) {
    return (
      <div className="rounded-2xl border border-dashed border-line px-5 py-10 text-center">
        <p className="font-semibold">No comments matched yet</p>
        <p className="mt-1 text-sm text-ink-soft">Ask a friend to comment your keyword on the post. It shows up here within seconds.</p>
      </div>
    );
  }
  const names = new Map(automations.map((a) => [a.id, a.name]));
  return (
    <ul className="divide-y divide-line">
      {events.map((e) => {
        const s = STATUS[e.status];
        return (
          <li key={e.id} className="flex items-start gap-3 py-3.5">
            <span aria-hidden="true" className="mt-0.5 grid h-8 w-8 shrink-0 place-items-center rounded-full bg-mist text-xs font-bold uppercase">
              {(e.from_username ?? "?")[0]}
            </span>
            <div className="min-w-0 flex-1">
              <p className="truncate text-sm">
                <span className="font-semibold">{e.from_username ? `@${e.from_username}` : "Someone"}</span>{" "}
                <span className="text-ink-soft">{e.kind === "dm" ? "messaged" : "commented"} “{e.text}”</span>
              </p>
              <p className="mt-0.5 text-xs text-muted">
                {names.get(e.automation_id ?? "") ?? "Deleted automation"} · {timeAgo(e.created_at)}
              </p>
              {e.error ? <p className="mt-1 text-xs text-danger">{e.error}</p> : null}
            </div>
            <span className={`shrink-0 text-xs font-semibold ${s.className}`}>{s.label}</span>
          </li>
        );
      })}
    </ul>
  );
}
