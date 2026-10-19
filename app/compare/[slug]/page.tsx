import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { JsonLd } from "@/components/JsonLd";
import { MarketingShell } from "@/components/MarketingShell";
import { COMPARE_PAGES, getCompare } from "@/lib/content";
import { LAST_UPDATED, absoluteUrl } from "@/lib/site";

type Props = { params: Promise<{ slug: string }> };

export function generateStaticParams() {
  return COMPARE_PAGES.map((c) => ({ slug: c.slug }));
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const page = getCompare((await params).slug);
  if (!page) return {};
  return {
    title: page.title,
    description: page.description,
    alternates: { canonical: `/compare/${page.slug}` },
    openGraph: { title: page.title, description: page.description, type: "article" },
  };
}

export default async function ComparePage({ params }: Props) {
  const page = getCompare((await params).slug);
  if (!page) notFound();

  const breadcrumbs = {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    itemListElement: [
      { "@type": "ListItem", position: 1, name: "Home", item: absoluteUrl("/") },
      { "@type": "ListItem", position: 2, name: `Hookline vs ${page.competitor}`, item: absoluteUrl(`/compare/${page.slug}`) },
    ],
  };

  return (
    <MarketingShell>
      <JsonLd data={breadcrumbs} />
      <article className="wrap max-w-4xl pb-10 pt-12 md:pt-20">
        <p className="text-sm text-muted">
          Comparison · updated <time dateTime={LAST_UPDATED}>October 2026</time>
        </p>
        <h1 className="mt-3 text-[clamp(2.3rem,5.5vw,4rem)] font-extrabold leading-[0.98] tracking-[-0.045em]">{page.title}</h1>
        <p className="mt-6 max-w-[62ch] text-lg leading-relaxed text-ink-soft">{page.intro}</p>

        <div className="mt-12 overflow-x-auto rounded-[24px] bg-paper ring-1 ring-line">
          <table className="w-full min-w-[560px] text-left text-[0.95rem]">
            <caption className="sr-only">
              Feature comparison between Hookline and {page.competitor}
            </caption>
            <thead>
              <tr className="border-b border-line">
                <th scope="col" className="px-5 py-4 font-semibold text-muted">
                  Feature
                </th>
                <th scope="col" className="px-5 py-4 font-bold">
                  Hookline
                </th>
                <th scope="col" className="px-5 py-4 font-bold">
                  {page.competitor}
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-line">
              {page.rows.map((r) => (
                <tr key={r.label}>
                  <th scope="row" className="px-5 py-4 font-medium">
                    {r.label}
                  </th>
                  <td className="px-5 py-4 text-ink-soft">{r.hookline}</td>
                  <td className="px-5 py-4 text-ink-soft">{r.them}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        <h2 className="mt-14 text-2xl font-bold tracking-[-0.02em]">Which should you choose?</h2>
        <p className="mt-3 max-w-[62ch] text-lg leading-relaxed text-ink-soft">{page.verdict}</p>
        <p className="mt-6 text-sm text-muted">
          Competitor details come from their public website and may change. Check {page.competitor}&apos;s site for current pricing.
        </p>
        <div className="mt-10 flex flex-wrap gap-3">
          <Link href="/login?mode=signup" className="btn btn-violet">
            Try Hookline free
          </Link>
          <Link href="/pricing" className="btn btn-ghost">
            See pricing
          </Link>
        </div>
      </article>
    </MarketingShell>
  );
}
