import { MarketingShell } from "@/components/MarketingShell";
import { LAST_UPDATED } from "@/lib/site";

export function LegalPage({ title, sections }: { title: string; sections: { heading: string; body: string[] }[] }) {
  return (
    <MarketingShell>
      <article className="wrap max-w-3xl pb-10 pt-12 md:pt-20">
        <h1 className="text-[clamp(2.2rem,5vw,3.4rem)] font-extrabold leading-[1] tracking-[-0.04em]">{title}</h1>
        <p className="mt-3 text-sm text-muted">
          Last updated <time dateTime={LAST_UPDATED}>19 October 2026</time>
        </p>
        <div className="prose-guide mt-6">
          {sections.map((s) => (
            <section key={s.heading}>
              <h2>{s.heading}</h2>
              {s.body.map((p) => (
                <p key={p.slice(0, 48)}>{p}</p>
              ))}
            </section>
          ))}
        </div>
      </article>
    </MarketingShell>
  );
}
