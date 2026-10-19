import type { Metadata } from "next";
import Link from "next/link";
import { LoginForm } from "@/app/login/LoginForm";
import { Logo } from "@/components/Logo";
import { isSupabaseConfigured } from "@/lib/env";

export const metadata: Metadata = {
  title: "Log in or start free",
  robots: { index: false, follow: true },
  alternates: { canonical: "/login" },
};

type Props = { searchParams: Promise<{ mode?: string; next?: string; error?: string; plan?: string }> };

export default async function LoginPage({ searchParams }: Props) {
  const sp = await searchParams;
  const signup = sp.mode === "signup";
  const configured = isSupabaseConfigured();

  return (
    <div className="grid min-h-dvh lg:grid-cols-[1fr_1fr]">
      <div className="flex flex-col px-6 py-8 sm:px-12">
        <Logo />
        <div className="mx-auto flex w-full max-w-sm flex-1 flex-col justify-center py-16">
          <h1 className="text-4xl font-extrabold tracking-[-0.04em]">{signup ? "Start free" : "Welcome back"}</h1>
          <p className="mt-3 text-ink-soft">
            {signup
              ? "Create your account, connect Instagram and send your first automated DM in minutes."
              : "Log in to manage your automations."}
          </p>
          {sp.error ? (
            <p role="alert" className="mt-5 rounded-xl bg-[#fdecec] px-4 py-3 text-sm text-danger">
              That sign-in link has expired or was already used. Request a new one below.
            </p>
          ) : null}
          {configured ? (
            <LoginForm next={sp.next ?? "/dashboard"} signup={signup} />
          ) : (
            <div className="mt-8 rounded-2xl bg-paper p-5 ring-1 ring-line">
              <p className="font-semibold">Accounts open once the database is connected.</p>
              <p className="mt-1.5 text-sm text-ink-soft">Until then you can explore the full dashboard with sample data.</p>
              <Link href="/dashboard" className="btn btn-primary mt-4 w-full">
                Open the demo dashboard
              </Link>
            </div>
          )}
          <p className="mt-8 text-sm text-muted">
            {signup ? "Already have an account? " : "New to Hookline? "}
            <Link href={signup ? "/login" : "/login?mode=signup"} className="font-semibold text-ink underline underline-offset-2">
              {signup ? "Log in" : "Start free"}
            </Link>
          </p>
          <p className="mt-3 text-xs text-muted">
            By continuing you agree to our{" "}
            <Link href="/terms" className="underline">
              terms
            </Link>{" "}
            and{" "}
            <Link href="/privacy" className="underline">
              privacy policy
            </Link>
            .
          </p>
        </div>
      </div>
      <aside className="relative hidden overflow-hidden bg-ink p-12 text-white lg:flex lg:flex-col lg:justify-end">
        <div aria-hidden="true" className="absolute -left-24 top-10 h-96 w-96 rounded-full bg-violet opacity-50 blur-3xl" />
        <div aria-hidden="true" className="absolute right-0 top-40 h-72 w-72 rounded-full bg-orchid opacity-40 blur-3xl" />
        <div className="relative max-w-md space-y-3">
          <div className="w-fit max-w-[85%] rounded-[22px] rounded-bl-md bg-white/10 px-4 py-2.5 text-sm">
            <span className="font-semibold">aanya.eats</span> commented: <span className="rounded bg-marker px-1 text-ink">RECIPE</span> pls!
          </div>
          <div className="dm-bubble ml-auto w-fit max-w-[85%] px-4 py-2.5 text-sm">Here&apos;s the 10-minute dal recipe 🍲</div>
          <p className="pt-6 text-3xl font-bold leading-tight tracking-[-0.03em]">Every comment answered, even the ones at 3am.</p>
        </div>
      </aside>
    </div>
  );
}
