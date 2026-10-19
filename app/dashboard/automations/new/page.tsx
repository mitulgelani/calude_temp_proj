import Link from "next/link";
import { AutomationForm } from "@/components/dashboard/AutomationForm";
import { getDashboardData } from "@/lib/dashboard";

export default async function NewAutomationPage() {
  const data = await getDashboardData();
  return (
    <div className="space-y-6">
      <div>
        <Link href="/dashboard/automations" className="text-sm text-muted hover:text-ink">
          Automations
        </Link>
        <h1 className="mt-1 text-3xl font-extrabold tracking-[-0.035em] sm:text-4xl">New automation</h1>
      </div>
      <AutomationForm accounts={data.accounts} plan={data.plan} demo={data.demo} />
    </div>
  );
}
