import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import type { Article, WithContext } from "schema-dts";
import { FaqList, faqJsonLd } from "@/components/FaqList";
import { JsonLd } from "@/components/JsonLd";
import { MarketingShell } from "@/components/MarketingShell";
import { GUIDES, getGuide } from "@/lib/content";
import { LAST_UPDATED, SITE_NAME, absoluteUrl } from "@/lib/site";

type Props = { params: Promise<{ slug: string }> };

export function generateStaticParams() {
  return GUIDES.map((g) => ({ slug: g.slug }));
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const guide = getGuide((await params).slug);
  if (!guide) return {};
  return {
    title: guide.title,
    description: guide.description,
    alternates: { canonical: `/guides/${guide.slug}` },
    openGraph: { title: guide.title, description: guide.description, type: "article", publishedTime: LAST_UPDATED },
  };
}

export default async function GuidePage({ params }: Props) {
  const guide = getGuide((await params).slug);
  if (!guide) notFound();

  const article: WithContext<Article> = {
    "@context": "https://schema.org",
    "@type": "Article",
    headline: guide.title,
    description: guide.description,
    datePublished: LAST_UPDATED,
    dateModified: LAST_UPDATED,
    mainEntityOfPage: absoluteUrl(`/guides/${guide.slug}`),
    author: { "@type": "Organization", name: SITE_NAME },
    publisher: { "@type": "Organization", name: SITE_NAME, logo: { "@type": "ImageObject", url: absoluteUrl("/icon.svg") } },
  };

  const others = GUIDES.filter((g) => g.slug !== guide.slug);

  return (
    <MarketingShell>
      <JsonLd data={guide.faqs.length ? [article, faqJsonLd(guide.faqs)] : article} />
      <article className="wrap max-w-3xl pb-10 pt-12 md:pt-20">
        <p className="text-sm text-muted">
          Guide · {guide.readMinutes} min read · updated <time dateTime={LAST_UPDATED}>October 2026</time>
        </p>
        <h1 className="mt-3 text-[clamp(2.2rem,5vw,3.6rem)] font-extrabold leading-[1] tracking-[-0.045em]">{guide.title}</h1>
        <p className="mt-5 text-xl leading-relaxed text-ink-soft">{guide.description}</p>

        <nav aria-label="In this guide" className="mt-10 rounded-[22px] bg-paper p-6 ring-1 ring-line">
          <p className="font-semibold">In this guide</p>
          <ol className="mt-3 list-decimal space-y-1.5 pl-5 text-ink-soft">
            {guide.sections.map((s) => (
              <li key={s.heading}>
                <a href={`#${slugify(s.heading)}`} className="hover:text-ink hover:underline">
                  {s.heading}
                </a>
              </li>
            ))}
          </ol>
        </nav>

        <div className="prose-guide mt-6">
          {guide.sections.map((s) => (
            <section key={s.heading} aria-labelledby={slugify(s.heading)}>
              <h2 id={slugify(s.heading)} className="scroll-mt-24">
                {s.heading}
              </h2>
              {s.body.map((p) => (
                <p key={p.slice(0, 40)}>{p}</p>
              ))}
            </section>
          ))}
        </div>

        {guide.faqs.length ? (
          <section className="mt-14">
            <h2 className="mb-4 text-2xl font-bold tracking-[-0.02em]">Frequently asked</h2>
            <FaqList faqs={guide.faqs} />
          </section>
        ) : null}

        <aside className="mt-14 rounded-[28px] bg-ink p-8 text-white">
          <p className="text-2xl font-bold tracking-[-0.02em]">Set this up in two minutes</p>
          <p className="mt-2 text-white/75">Hookline is free for your first 1,000 DMs every month.</p>
          <Link href="/login?mode=signup" className="btn btn-violet mt-6">
            Start free
          </Link>
        </aside>

        <section className="mt-14">
          <h2 className="text-xl font-bold">More guides</h2>
          <ul className="mt-4 space-y-3">
            {others.map((g) => (
              <li key={g.slug}>
                <Link href={`/guides/${g.slug}`} className="text-lg text-violet hover:underline">
                  {g.title}
                </Link>
              </li>
            ))}
          </ul>
        </section>
      </article>
    </MarketingShell>
  );
}

function slugify(s: string) {
  return s
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/(^-|-$)/g, "");
}
