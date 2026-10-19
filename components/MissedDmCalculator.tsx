"use client";

import { useId, useState } from "react";

function Slider({
  label,
  value,
  min,
  max,
  step,
  onChange,
  format,
}: {
  label: string;
  value: number;
  min: number;
  max: number;
  step: number;
  onChange: (v: number) => void;
  format: (v: number) => string;
}) {
  const id = useId();
  const pct = ((value - min) / (max - min)) * 100;
  return (
    <div>
      <div className="flex items-baseline justify-between gap-4">
        <label htmlFor={id} className="text-[0.95rem] text-white/80">
          {label}
        </label>
        <output htmlFor={id} className="text-lg font-semibold tabular-nums text-white">
          {format(value)}
        </output>
      </div>
      <input
        id={id}
        type="range"
        min={min}
        max={max}
        step={step}
        value={value}
        onChange={(e) => onChange(Number(e.target.value))}
        className="mt-3 h-2 w-full cursor-pointer appearance-none rounded-full accent-[#FFE14D]"
        style={{ background: `linear-gradient(90deg, #FFE14D ${pct}%, rgb(255 255 255 / 0.15) ${pct}%)` }}
      />
    </div>
  );
}

export function MissedDmCalculator() {
  const [comments, setComments] = useState(800);
  const [reels, setReels] = useState(8);
  const [seconds, setSeconds] = useState(40);

  const dms = comments * reels;
  const hours = (dms * seconds) / 3600;
  const fmt = new Intl.NumberFormat("en-US");

  return (
    <div className="grid gap-10 rounded-[32px] bg-ink p-7 text-white md:grid-cols-[1.1fr_1fr] md:p-12">
      <div className="space-y-8">
        <Slider label="Keyword comments per Reel" value={comments} min={50} max={5000} step={50} onChange={setComments} format={(v) => fmt.format(v)} />
        <Slider label="Reels with a call to comment, per month" value={reels} min={1} max={30} step={1} onChange={setReels} format={(v) => String(v)} />
        <Slider label="Seconds to copy-paste one reply by hand" value={seconds} min={10} max={120} step={5} onChange={setSeconds} format={(v) => `${v}s`} />
      </div>
      <div className="flex flex-col justify-between gap-8 border-t border-white/10 pt-8 md:border-l md:border-t-0 md:pl-12 md:pt-0">
        <div>
          <p className="text-white/70">Each month you&apos;d otherwise spend</p>
          <p className="mt-1 text-[clamp(3rem,8vw,5.5rem)] font-bold leading-none tracking-[-0.05em] tabular-nums">
            {hours < 10 ? hours.toFixed(1) : fmt.format(Math.round(hours))}
            <span className="ml-2 text-2xl font-semibold tracking-normal text-white/70">hours</span>
          </p>
          <p className="mt-3 text-white/70">
            typing {fmt.format(dms)} DMs. Hookline sends each one in about two seconds, including the ones that arrive at 3am.
          </p>
        </div>
        <p className="text-sm text-white/50">
          {dms > 1000 ? "That's past the Free plan's 1,000 DMs — Creator covers it with unlimited DMs for $9 / ₹399 a month." : "This fits comfortably in the Free plan."}
        </p>
      </div>
    </div>
  );
}
