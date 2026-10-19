import type { Faq } from "@/lib/content";

export function FaqList({ faqs }: { faqs: Faq[] }) {
  return (
    <div className="divide-y divide-line border-y border-line">
      {faqs.map((f) => (
        <details key={f.q} className="group py-5">
          <summary className="flex cursor-pointer list-none items-start justify-between gap-6 text-lg font-semibold tracking-[-0.01em] [&::-webkit-details-marker]:hidden">
            <h3>{f.q}</h3>
            <span
              aria-hidden="true"
              className="mt-1 grid h-7 w-7 shrink-0 place-items-center rounded-full ring-1 ring-line transition-transform group-open:rotate-45"
            >
              <svg viewBox="0 0 12 12" className="h-3 w-3">
                <path d="M6 1v10M1 6h10" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" />
              </svg>
            </span>
          </summary>
          <p className="mt-3 max-w-[68ch] text-[1.02rem] leading-relaxed text-ink-soft">{f.a}</p>
        </details>
      ))}
    </div>
  );
}

export function faqJsonLd(faqs: Faq[]) {
  return {
    "@context": "https://schema.org" as const,
    "@type": "FAQPage" as const,
    mainEntity: faqs.map((f) => ({
      "@type": "Question" as const,
      name: f.q,
      acceptedAnswer: { "@type": "Answer" as const, text: f.a },
    })),
  };
}
