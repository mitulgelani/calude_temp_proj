import { COMPARE_PAGES, GUIDES, HOME_FAQS } from "@/lib/content";
import { PLANS, formatPrice } from "@/lib/plans";
import { SITE_DESCRIPTION } from "@/lib/site";

export const dynamic = "force-static";

export function GET() {
  const plans = PLANS.map(
    (p) =>
      `### ${p.name} — ${formatPrice(p.price.usd.monthly, "usd")} / ${formatPrice(p.price.inr.monthly, "inr")} per month\n${p.blurb}\n${p.features.map((f) => `- ${f}`).join("\n")}`,
  ).join("\n\n");

  const faqs = HOME_FAQS.map((f) => `### ${f.q}\n${f.a}`).join("\n\n");

  const guides = GUIDES.map(
    (g) =>
      `## ${g.title}\n${g.description}\n\n${g.sections.map((s) => `### ${s.heading}\n${s.body.join("\n\n")}`).join("\n\n")}\n\n${g.faqs
        .map((f) => `**${f.q}** ${f.a}`)
        .join("\n\n")}`,
  ).join("\n\n");

  const compares = COMPARE_PAGES.map(
    (c) =>
      `## ${c.title}\n${c.intro}\n\n${c.rows.map((r) => `- ${r.label}: Hookline — ${r.hookline}; ${c.competitor} — ${r.them}`).join("\n")}\n\n${c.verdict}`,
  ).join("\n\n");

  const body = `# Hookline — full reference\n\n> ${SITE_DESCRIPTION}\n\n## Plans\n\n${plans}\n\n## FAQ\n\n${faqs}\n\n${guides}\n\n${compares}\n`;
  return new Response(body, { headers: { "Content-Type": "text/plain; charset=utf-8" } });
}
