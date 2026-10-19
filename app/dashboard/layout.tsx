import type { Metadata } from "next";
import Link from "next/link";
import { DashboardNav } from "@/components/dashboard/DashboardNav";
import { Logo } from "@/components/Logo";
import { signOut } from "@/app/dashboard/actions";
import { getDashboardData } from "@/lib/dashboard";
import { planLabel } from "@/lib/plans";

export const metadata: Metadata = {
  title: "Dashboard",
  robots: { index: false, follow: false },
};

export default async function DashboardLayout({ children }: { children: React.ReactNode }) {
  const data = await getDashboardData();

  return (
    <div className="min-h-dvh lg:grid lg:grid-cols-[248px_1fr]">
      <aside className="border-b border-line bg-paper lg:sticky lg:top-0 lg:h-dvh lg:border-b-0 lg:border-r">
        <div className="flex h-full flex-col gap-4 p-4 lg:p-5">
          <div className="flex items-center justify-between">
            <Logo href="/dashboard" />
            <span className="rounded-full bg-mist px-2.5 py-1 text-xs font-semibold text-ink-soft lg:hidden">{planLabel(data.plan)}</span>
          </div>
          <DashboardNav />
          <div className="mt-auto hidden space-y-3 lg:block">
            <div className="rounded-2xl bg-mist p-4">
              <p className="text-xs text-muted">Plan</p>
              <p className="font-semibold">{planLabel(data.plan)}</p>
              {data.plan === "free" ? (
                <Link href="/dashboard/settings#plan" className="mt-2 inline-block text-sm font-semibold text-violet hover:underline">
                  Upgrade for unlimited DMs
                </Link>
              ) : null}
            </div>
            <form action={signOut}>
              <button type="submit" className="w-full rounded-xl px-3 py-2 text-left text-sm text-muted hover:bg-mist hover:text-ink">
                {data.demo ? "Leave demo" : "Sign out"}
                {data.email ? <span className="block truncate text-xs">{data.email}</span> : null}
              </button>
            </form>
          </div>
        </div>
      </aside>
      <div className="min-w-0">
        {data.demo ? (
          <div className="bg-ink px-4 py-2.5 text-center text-sm text-white">
            You&apos;re exploring the demo workspace with sample data.{" "}
            <Link href="/login?mode=signup" className="font-semibold text-marker underline underline-offset-2">
              Create your account
            </Link>{" "}
            to connect your own Instagram.
          </div>
        ) : null}
        <main className="mx-auto w-full max-w-6xl px-4 py-8 sm:px-8 lg:py-10">{children}</main>
      </div>
    </div>
  );
}
