import Link from "next/link";
import type { SoftwareApplication, WithContext } from "schema-dts";
import { FaqList, faqJsonLd } from "@/components/FaqList";
import { HeroSimulation } from "@/components/HeroSimulation";
import { JsonLd } from "@/components/JsonLd";
import { MarketingShell } from "@/components/MarketingShell";
import { MissedDmCalculator } from "@/components/MissedDmCalculator";
import { PricingTable } from "@/components/PricingTable";
import { HOME_FAQS } from "@/lib/content";
import { SITE_DESCRIPTION, SITE_NAME, siteUrl } from "@/lib/site";

const app: WithContext<SoftwareApplication> = {
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  name: SITE_NAME,
  applicationCategory: "BusinessApplication",
  operatingSystem: "Web",
  url: siteUrl(),
  description: SITE_DESCRIPTION,
  offers: [
    { "@type": "Offer", name: "Free", price: "0", priceCurrency: "USD" },
    { "@type": "Offer", name: "Creator", price: "9", priceCurrency: "USD" },
    { "@type": "Offer", name: "Studio", price: "29", priceCurrency: "USD" },
  ],
  featureList: [
    "Auto-DM people who comment a keyword on Reels and posts",
    "Keyword replies to DMs and Story replies",
    "Follow-to-unlock links",
    "Re-run on comments from the last 7 days",
    "Public comment replies",
    "Link click tracking",
  ],
};

const STEPS = [
  {
    title: "Connect Instagram",
    body: "Log in on Instagram's own page and approve access. Hookline never sees your password.",
    art: (
      <div className="flex items-center gap-3">
        <span className="grid h-11 w-11 place-items-center rounded-2xl bg-[linear-gradient(135deg,#ffb36b,#ff5fa2_55%,#5b32ff)] text-white">
          <svg viewBox="0 0 24 24" className="h-6 w-6" aria-hidden="true">
            <rect x="3.5" y="3.5" width="17" height="17" rx="5" fill="none" stroke="currentColor" strokeWidth="2" />
            <circle cx="12" cy="12" r="4" fill="none" stroke="currentColor" strokeWidth="2" />
            <circle cx="17.2" cy="6.8" r="1.2" fill="currentColor" />
          </svg>
        </span>
        <span className="h-px flex-1 border-t-2 border-dashed border-line" />
        <span className="rounded-full bg-mint px-3 py-1 text-xs font-semibold text-white">Connected</span>
      </div>
    ),
  },
  {
    title: "Choose a post and a keyword",
    body: "Pick a Reel, or let it run on every post. Add the word you'll tell people to comment.",
    art: (
      <div className="flex flex-wrap gap-2">
        {["LINK", "GUIDE", "PRESET"].map((k, i) => (
          <span key={k} className={`rounded-full px-3 py-1.5 text-sm font-semibold ${i === 0 ? "bg-marker text-ink" : "bg-mist text-ink-soft"}`}>
            {k}
          </span>
        ))}
      </div>
    ),
  },
  {
    title: "Write the DM once",
    body: "Your message and link go out to every matching comment, around the clock, within seconds.",
    art: (
      <div className="dm-bubble ml-auto w-fit max-w-full px-4 py-2.5 text-sm">Here&apos;s the guide you asked for 📩</div>
    ),
  },
];

const FEATURES = [
  {
    title: "Comment to DM",
    body: "Every comment containing your keyword gets a private reply with your link. Case, emoji and typos like “link!!” still match.",
  },
  {
    title: "Follow to unlock",
    body: "Ask people to follow before the link arrives. Followers get it instantly, everyone else gets a friendly nudge first.",
  },
  {
    title: "Re-run missed comments",
    body: "Set up an automation after your Reel took off? Send the DM to matching comments from the last seven days in one click.",
  },
  {
    title: "Public replies that don't look robotic",
    body: "Reply under the comment so other viewers see it works. Rotate a few versions so your comments stay natural.",
  },
  {
    title: "DM and Story keywords",
    body: "The same automation answers when someone DMs you a keyword or replies to your Story with one.",
  },
  {
    title: "Clicks, not just sends",
    body: "Every link is tracked, so you see which Reel actually drove traffic and who your most engaged followers are.",
  },
];

export default function HomePage() {
  return (
    <MarketingShell>
      <JsonLd data={[app, faqJsonLd(HOME_FAQS)]} />

      {/* Hero */}
      <section className="wrap grid items-center gap-12 pb-20 pt-10 md:pt-16 lg:grid-cols-[1fr_1.05fr] lg:gap-10">
        <div>
          <h1 className="max-w-[13ch] text-[clamp(2.7rem,6.4vw,5rem)] font-extrabold leading-[0.96] tracking-[-0.035em]">
            Auto-DM everyone who comments on your Reels.
          </h1>
          <p className="mt-6 max-w-[46ch] text-lg leading-relaxed text-ink-soft md:text-xl">
            Tell viewers to comment a word like LINK. Hookline sends each of them your link in their DMs within seconds, on Instagram&apos;s official API.
          </p>
          <div className="mt-8 flex flex-wrap items-center gap-3">
            <Link href="/login?mode=signup" className="btn btn-violet px-6 py-4 text-base">
              Start free
            </Link>
            <Link href="/dashboard" className="btn btn-ghost px-6 py-4 text-base">
              Try the live demo
            </Link>
          </div>
          <p className="mt-5 text-sm text-muted">1,000 DMs a month free. No card needed. Set up in about two minutes.</p>
        </div>
        <HeroSimulation />
      </section>

      {/* Reassurance */}
      <section aria-label="How Hookline connects" className="border-y border-line bg-paper">
        <div className="wrap grid gap-6 py-8 text-[0.95rem] text-ink-soft sm:grid-cols-3">
          <p>
            <strong className="block text-ink">Official Instagram API</strong>
            The same private-reply feature Instagram built for businesses.
          </p>
          <p>
            <strong className="block text-ink">No password, ever</strong>
            You log in on Instagram and can revoke access in one tap.
          </p>
          <p>
            <strong className="block text-ink">Works on Creator and Business accounts</strong>
            Switching is free in Instagram&apos;s settings.
          </p>
        </div>
      </section>

      {/* How it works */}
      <section id="how-it-works" className="wrap scroll-mt-24 py-24">
        <h2 className="max-w-[20ch] text-[clamp(2rem,4.5vw,3.25rem)] font-bold leading-[1.02] tracking-[-0.04em]">
          Three steps, then it runs on its own.
        </h2>
        <ol className="mt-12 grid gap-4 md:grid-cols-3">
          {STEPS.map((s, i) => (
            <li key={s.title} className="flex flex-col rounded-[28px] bg-paper p-6 ring-1 ring-line">
              <span className="text-sm font-semibold text-violet">Step {i + 1}</span>
              <h3 className="mt-2 text-xl font-bold tracking-[-0.02em]">{s.title}</h3>
              <p className="mt-2 text-ink-soft">{s.body}</p>
              <div className="mt-auto pt-8">{s.art}</div>
            </li>
          ))}
        </ol>
      </section>

      {/* Features */}
      <section className="bg-paper py-24">
        <div className="wrap grid gap-12 lg:grid-cols-[0.8fr_1.2fr]">
          <div className="lg:sticky lg:top-28 lg:self-start">
            <h2 className="text-[clamp(2rem,4.5vw,3.25rem)] font-bold leading-[1.02] tracking-[-0.04em]">
              Everything that happens after the comment.
            </h2>
            <p className="mt-5 max-w-[40ch] text-lg text-ink-soft">
              The DM is the start. Hookline also handles the follow ask, the public reply and the people who commented before you were ready.
            </p>
          </div>
          <dl className="divide-y divide-line border-y border-line">
            {FEATURES.map((f) => (
              <div key={f.title} className="grid gap-2 py-7 sm:grid-cols-[0.8fr_1.2fr] sm:gap-8">
                <dt className="text-lg font-bold tracking-[-0.01em]">{f.title}</dt>
                <dd className="text-ink-soft">{f.body}</dd>
              </div>
            ))}
          </dl>
        </div>
      </section>

      {/* Follow to unlock spotlight */}
      <section className="wrap grid items-center gap-12 py-24 lg:grid-cols-2">
        <div className="order-2 lg:order-1">
          <div className="mx-auto max-w-sm space-y-3 rounded-[30px] bg-paper p-5 ring-1 ring-line">
            <div className="dm-bubble ml-auto w-fit max-w-[85%] px-4 py-2.5 text-sm">Hey! Reply to this message with anything and I&apos;ll send the link right over 👇</div>
            <div className="w-fit max-w-[80%] rounded-[22px] rounded-bl-md bg-mist px-4 py-2.5 text-sm">yes pls!</div>
            <p className="py-1 text-center text-xs text-muted">Hookline checks: follows you? Yes</p>
            <div className="dm-bubble ml-auto w-fit max-w-[85%] px-4 py-2.5 text-sm">
              Here&apos;s the 30-day workout plan 💪
              <span className="mt-1.5 block rounded-lg px-2 py-1 text-xs underline" style={{ backgroundColor: "rgb(255 255 255 / 0.18)" }}>
                hookline.app/r/plan30
              </span>
            </div>
          </div>
        </div>
        <div className="order-1 lg:order-2">
          <h2 className="text-[clamp(2rem,4.5vw,3.25rem)] font-bold leading-[1.02] tracking-[-0.04em]">Turn the people who want your link into followers.</h2>
          <p className="mt-5 max-w-[46ch] text-lg text-ink-soft">
            With follow-to-unlock on, Hookline starts a conversation instead of dropping the link. When they reply, it checks whether they follow you, then delivers the link or asks them to follow first.
          </p>
          <p className="mt-4 max-w-[46ch] text-ink-soft">
            The reply also opens Instagram&apos;s 24-hour messaging window, so you can keep the conversation going by hand.
          </p>
        </div>
      </section>

      {/* Calculator */}
      <section className="wrap py-12">
        <h2 className="mb-8 max-w-[22ch] text-[clamp(2rem,4.5vw,3.25rem)] font-bold leading-[1.02] tracking-[-0.04em]">
          What replying by hand actually costs you.
        </h2>
        <MissedDmCalculator />
      </section>

      {/* Pricing */}
      <section id="pricing" className="wrap scroll-mt-24 py-24">
        <h2 className="max-w-[20ch] text-[clamp(2rem,4.5vw,3.25rem)] font-bold leading-[1.02] tracking-[-0.04em]">
          Priced like a tool, not a percentage of your audience.
        </h2>
        <p className="mb-10 mt-4 max-w-[52ch] text-lg text-ink-soft">
          Flat monthly plans. Paid plans send unlimited DMs, so a Reel going viral never turns into a surprise bill.
        </p>
        <PricingTable />
      </section>

      {/* FAQ */}
      <section className="wrap grid gap-10 py-16 lg:grid-cols-[0.7fr_1.3fr]">
        <h2 className="text-[clamp(2rem,4.5vw,3.25rem)] font-bold leading-[1.02] tracking-[-0.04em]">Questions creators ask first</h2>
        <FaqList faqs={HOME_FAQS} />
      </section>

      {/* Final CTA */}
      <section className="wrap pt-16">
        <div className="relative overflow-hidden rounded-[36px] bg-violet px-7 py-16 text-white md:px-16">
          <div aria-hidden="true" className="pointer-events-none absolute -right-20 -top-24 h-80 w-80 rounded-full bg-orchid opacity-60 blur-3xl" />
          <h2 className="relative max-w-[18ch] text-[clamp(2.2rem,5vw,3.8rem)] font-extrabold leading-[0.98] tracking-[-0.045em]">
            Post your next Reel with “comment LINK” in it.
          </h2>
          <p className="relative mt-5 max-w-[44ch] text-lg text-white/80">Set up the automation now and every comment gets answered while you sleep.</p>
          <div className="relative mt-8 flex flex-wrap gap-3">
            <Link href="/login?mode=signup" className="btn bg-white px-6 py-4 text-base text-ink hover:bg-marker">
              Start free
            </Link>
            <Link href="/guides/instagram-comment-to-dm" className="btn px-6 py-4 text-base text-white ring-1 ring-white/40 hover:ring-white">
              Read the setup guide
            </Link>
          </div>
        </div>
      </section>
    </MarketingShell>
  );
}
