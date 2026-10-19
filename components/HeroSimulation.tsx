"use client";

import { useEffect, useState } from "react";

type Comment = { user: string; text: string; hit?: string; name?: string };

const SCRIPT: Comment[] = [
  { user: "riya.wanders", name: "Riya", text: "LINK please 🙏", hit: "LINK" },
  { user: "arjun.frames", text: "the colour grade on this is unreal" },
  { user: "meera.codes", name: "Meera", text: "link!! need this", hit: "link" },
  { user: "kabir.fit", text: "which lens is this?" },
  { user: "sana.k", name: "Sana", text: "Link 😍", hit: "Link" },
  { user: "dev_travels", name: "Dev", text: "LINK", hit: "LINK" },
];

const STEP_MS = 1900;

function Highlighted({ text, hit, active }: { text: string; hit?: string; active: boolean }) {
  if (!hit) return <>{text}</>;
  const i = text.indexOf(hit);
  if (i < 0) return <>{text}</>;
  return (
    <>
      {text.slice(0, i)}
      <span className={active ? "marker-sweep font-semibold" : "font-semibold"}>{hit}</span>
      {text.slice(i + hit.length)}
    </>
  );
}

function Avatar({ seed }: { seed: string }) {
  const hues = [262, 318, 22, 160, 200, 42];
  const h = hues[seed.length % hues.length];
  return (
    <span
      aria-hidden="true"
      className="grid h-7 w-7 shrink-0 place-items-center rounded-full text-[0.7rem] font-bold text-white"
      style={{ background: `linear-gradient(135deg, hsl(${h} 80% 62%), hsl(${(h + 40) % 360} 85% 52%))` }}
    >
      {seed[0].toUpperCase()}
    </span>
  );
}

export function HeroSimulation() {
  const [step, setStep] = useState(0);
  const [reduced, setReduced] = useState(false);

  useEffect(() => {
    const mq = window.matchMedia("(prefers-reduced-motion: reduce)");
    setReduced(mq.matches);
    if (mq.matches) {
      setStep(SCRIPT.length - 1);
      return;
    }
    const id = window.setInterval(() => setStep((s) => (s + 1) % (SCRIPT.length + 2)), STEP_MS);
    return () => window.clearInterval(id);
  }, []);

  const shown = SCRIPT.slice(0, Math.min(step + 1, SCRIPT.length));
  const visible = shown.slice(-4);
  const hits = shown.filter((c) => c.hit);
  const latestHit = hits[hits.length - 1];
  const sentCount = hits.length;

  return (
    <div className="relative mx-auto w-full max-w-[600px]" aria-label="Animated example: comments with the keyword LINK receive a DM" role="img">
      <div className="grid grid-cols-[1fr] gap-4 sm:grid-cols-[1.05fr_1fr]">
        {/* Phone: Reel + comment sheet */}
        <div className="relative overflow-hidden rounded-[34px] bg-ink p-2 shadow-[0_40px_80px_-30px_rgb(22_19_43/0.55)]">
          <div className="relative h-[470px] overflow-hidden rounded-[27px]">
            <div
              className="absolute inset-0"
              style={{
                background:
                  "radial-gradient(120% 70% at 20% 10%, #ffb36b 0%, transparent 55%), radial-gradient(90% 60% at 90% 30%, #ff5fa2 0%, transparent 60%), linear-gradient(180deg, #5b32ff 0%, #1d1650 100%)",
              }}
            />
            <svg viewBox="0 0 200 120" className="absolute inset-x-0 top-24 w-full opacity-70" aria-hidden="true">
              <path d="M0 90 L40 52 L70 78 L110 30 L150 70 L200 40 L200 120 L0 120Z" fill="#1d1650" />
              <path d="M0 105 L50 75 L95 98 L140 64 L200 92 L200 120 L0 120Z" fill="#120d38" />
            </svg>
            <div className="absolute left-3 right-3 top-3 flex items-center gap-2 text-[0.72rem] font-semibold text-white">
              <span className="grid h-6 w-6 place-items-center rounded-full bg-white/25 text-[0.62rem]">YO</span>
              you.create
              <span className="ml-auto rounded-full bg-white/20 px-2 py-0.5 text-[0.62rem] font-medium">Reels</span>
            </div>
            <p className="absolute left-3 right-10 top-[150px] text-[0.8rem] font-semibold leading-snug text-white drop-shadow">
              Comment <span className="rounded bg-marker px-1 text-ink">LINK</span> and I&apos;ll DM you my Lisbon preset pack
            </p>

            {/* Comment sheet */}
            <div className="absolute inset-x-0 bottom-0 h-[236px] rounded-t-[22px] bg-paper px-3 pt-2">
              <div className="mx-auto mb-2 h-1 w-9 rounded-full bg-line" />
              <p className="mb-2 text-center text-[0.7rem] font-semibold text-ink">Comments</p>
              <ul className="space-y-2.5">
                {visible.map((c, idx) => {
                  const isNewest = idx === visible.length - 1 && !reduced;
                  return (
                    <li key={c.user} className={`flex items-start gap-2 ${isNewest ? "anim-rise" : ""}`}>
                      <Avatar seed={c.user} />
                      <div className="min-w-0 flex-1">
                        <p className="text-[0.68rem] font-semibold text-ink">{c.user}</p>
                        <p className="truncate text-[0.78rem] text-ink-soft">
                          <Highlighted text={c.text} hit={c.hit} active={isNewest} />
                        </p>
                      </div>
                      {c.hit ? (
                        <span className={`mt-1 shrink-0 rounded-full bg-mint/12 px-1.5 py-0.5 text-[0.6rem] font-semibold text-mint ${isNewest ? "anim-pop" : ""}`} style={{ backgroundColor: "rgb(18 168 115 / 0.12)" }}>
                          DM sent
                        </span>
                      ) : null}
                    </li>
                  );
                })}
              </ul>
            </div>
          </div>
        </div>

        {/* Inbox */}
        <div className="flex flex-col gap-3">
          <div className="rounded-[26px] bg-paper p-4 shadow-[0_30px_60px_-34px_rgb(22_19_43/0.45)] ring-1 ring-line">
            <div className="flex items-center gap-2 border-b border-line pb-3">
              {latestHit ? <Avatar seed={latestHit.user} /> : <span className="h-7 w-7 rounded-full bg-mist" />}
              <div className="min-w-0">
                <p className="truncate text-[0.8rem] font-semibold">{latestHit?.user ?? "Waiting for a comment"}</p>
                <p className="text-[0.66rem] text-muted">Instagram DM</p>
              </div>
            </div>
            <div className="min-h-[150px] pt-3">
              {latestHit ? (
                <div key={latestHit.user} className={reduced ? "" : "anim-rise"}>
                  <p className="mb-2 text-center text-[0.62rem] text-muted">Replied to your comment: “{latestHit.text}”</p>
                  <div className="dm-bubble ml-auto max-w-[92%] px-3.5 py-2.5 text-[0.8rem] leading-snug">
                    Hey {latestHit.name}! Here&apos;s the Lisbon preset pack ✨
                    <span className="mt-1.5 block truncate rounded-lg bg-white/18 px-2 py-1 text-[0.72rem] underline decoration-white/60" style={{ backgroundColor: "rgb(255 255 255 / 0.18)" }}>
                      hookline.app/r/lisbon
                    </span>
                  </div>
                  <p className="mt-1.5 text-right text-[0.62rem] text-muted">Delivered · 1.8s after comment</p>
                </div>
              ) : null}
            </div>
          </div>

          <div className="rounded-[22px] bg-ink p-4 text-white">
            <p className="text-[0.7rem] text-white/60">On this Reel so far</p>
            <div className="mt-1 flex items-baseline gap-2">
              <span className="text-4xl font-bold tabular-nums tracking-[-0.04em]">{sentCount}</span>
              <span className="text-sm text-white/70">links sent, 0 typed by you</span>
            </div>
            <div className="mt-3 flex gap-1" aria-hidden="true">
              {SCRIPT.map((c, i) => (
                <span
                  key={c.user}
                  className="h-1.5 flex-1 rounded-full transition-colors duration-500"
                  style={{ background: i < shown.length ? (c.hit ? "#FFE14D" : "rgb(255 255 255 / 0.35)") : "rgb(255 255 255 / 0.1)" }}
                />
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
