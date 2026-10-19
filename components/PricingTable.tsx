"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { SUPPORT_EMAIL } from "@/lib/site";
import { PLANS, checkoutUrl, formatPrice, type Billing, type Currency } from "@/lib/plans";

function Toggle<T extends string>({
  value,
  options,
  onChange,
  label,
}: {
  value: T;
  options: { value: T; label: string }[];
  onChange: (v: T) => void;
  label: string;
}) {
  return (
    <div role="radiogroup" aria-label={label} className="inline-flex rounded-full bg-paper p-1 ring-1 ring-line">
      {options.map((o) => (
        <button
          key={o.value}
          type="button"
          role="radio"
          aria-checked={value === o.value}
          onClick={() => onChange(o.value)}
          className={`rounded-full px-4 py-2 text-sm font-semibold transition-colors ${
            value === o.value ? "bg-ink text-white" : "text-ink-soft hover:text-ink"
          }`}
        >
          {o.label}
        </button>
      ))}
    </div>
  );
}

export function PricingTable() {
  const [currency, setCurrency] = useState<Currency>("usd");
  const [billing, setBilling] = useState<Billing>("monthly");

  useEffect(() => {
    try {
      const tz = Intl.DateTimeFormat().resolvedOptions().timeZone;
      if (tz === "Asia/Kolkata" || tz === "Asia/Calcutta") setCurrency("inr");
    } catch {
      /* keep USD */
    }
  }, []);

  return (
    <div>
      <div className="flex flex-wrap items-center gap-3">
        <Toggle
          label="Billing period"
          value={billing}
          onChange={setBilling}
          options={[
            { value: "monthly", label: "Monthly" },
            { value: "yearly", label: "Yearly · 2 months free" },
          ]}
        />
        <Toggle
          label="Currency"
          value={currency}
          onChange={setCurrency}
          options={[
            { value: "usd", label: "USD" },
            { value: "inr", label: "INR" },
          ]}
        />
      </div>

      <div className="mt-8 grid gap-4 lg:grid-cols-3">
        {PLANS.map((plan) => {
          const price = plan.price[currency][billing];
          const href = plan.id === "free" ? "/login?mode=signup" : checkoutUrl(plan.id, billing) ?? `/login?mode=signup&plan=${plan.id}`;
          const featured = plan.featured;
          return (
            <section
              key={plan.id}
              aria-labelledby={`plan-${plan.id}`}
              className={`relative flex flex-col rounded-[28px] p-7 ${
                featured ? "bg-ink text-white shadow-[0_40px_80px_-40px_rgb(91_50_255/0.8)]" : "bg-paper ring-1 ring-line"
              }`}
            >
              <div className="flex items-center justify-between gap-3">
                <h3 id={`plan-${plan.id}`} className="text-xl font-bold tracking-[-0.02em]">
                  {plan.name}
                </h3>
                {featured ? <span className="rounded-full bg-marker px-2.5 py-1 text-xs font-bold text-ink">Most creators pick this</span> : null}
              </div>
              <p className={`mt-1.5 text-sm ${featured ? "text-white/70" : "text-muted"}`}>{plan.blurb}</p>
              <p className="mt-6 flex items-baseline gap-1.5">
                <span className="text-5xl font-bold tracking-[-0.05em] tabular-nums">{formatPrice(price, currency)}</span>
                <span className={`text-sm ${featured ? "text-white/60" : "text-muted"}`}>{plan.id === "free" ? "forever" : "/ month"}</span>
              </p>
              <p className={`mt-1 h-5 text-xs ${featured ? "text-white/60" : "text-muted"}`}>
                {billing === "yearly" && price > 0 ? `${formatPrice(price * 12, currency)} billed once a year` : ""}
              </p>
              <Link href={href} className={`btn mt-6 w-full ${featured ? "btn-violet" : "btn-primary"}`}>
                {plan.cta}
              </Link>
              <ul className={`mt-7 space-y-3 text-[0.94rem] ${featured ? "text-white/85" : "text-ink-soft"}`}>
                {plan.features.map((f) => (
                  <li key={f} className="flex gap-2.5">
                    <svg viewBox="0 0 16 16" className={`mt-1 h-4 w-4 shrink-0 ${featured ? "text-marker" : "text-violet"}`} aria-hidden="true">
                      <path d="M3 8.5l3 3 7-7" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
                    </svg>
                    {f}
                  </li>
                ))}
              </ul>
            </section>
          );
        })}
      </div>
      <p className="mt-5 text-sm text-muted">
        Prices are per workspace. Cancel any time from your dashboard. Running more than five accounts?{" "}
        <a href={`mailto:${SUPPORT_EMAIL}?subject=Agency%20plan`} className="font-semibold text-ink underline underline-offset-2">
          Talk to us about an agency plan
        </a>
        .
      </p>
    </div>
  );
}
