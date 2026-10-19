import Link from "next/link";
import { notFound } from "next/navigation";
import { ActivityList } from "@/components/dashboard/ActivityList";
import { AutomationForm } from "@/components/dashboard/AutomationForm";
import { getDashboardData } from "@/lib/dashboard";

type Props = { params: Promise<{ id: string }> };

export default async function EditAutomationPage({ params }: Props) {
  const { id } = await params;
  const data = await getDashboardData();
  const automation = data.automations.find((a) => a.id === id);
  if (!automation) notFound();
  const events = data.events.filter((e) => e.automation_id === id);
  const fmt = new Intl.NumberFormat("en-US");

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <Link href="/dashboard/automations" className="text-sm text-muted hover:text-ink">
            Automations
          </Link>
          <h1 className="mt-1 text-3xl font-extrabold tracking-[-0.035em] sm:text-4xl">{automation.name}</h1>
        </div>
        <p className="text-sm text-ink-soft">
          <span className="font-semibold text-ink">{fmt.format(automation.sent_count)}</span> sent ·{" "}
          <span className="font-semibold text-ink">{fmt.format(automation.click_count)}</span> clicks
        </p>
      </div>
      <AutomationForm accounts={data.accounts} initial={automation} plan={data.plan} demo={data.demo} />
      <section className="rounded-[24px] bg-paper p-5 ring-1 ring-line sm:p-6">
        <h2 className="text-lg font-bold">Recent activity for this automation</h2>
        <div className="mt-2">
          <ActivityList events={events} automations={data.automations} />
        </div>
      </section>
    </div>
  );
}
