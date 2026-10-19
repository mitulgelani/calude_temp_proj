import { COMPARE_PAGES, GUIDES } from "@/lib/content";
import { PLANS } from "@/lib/plans";
import { SITE_DESCRIPTION, absoluteUrl } from "@/lib/site";

export const dynamic = "force-static";

export function GET() {
  const body = `# Hookline

> ${SITE_DESCRIPTION}

Hookline is a web app for Instagram creators and businesses. When someone comments a chosen keyword (for example "LINK") on a Reel, post, Story or Live, Hookline sends that person a private Instagram DM with the creator's link within seconds. It uses Meta's official Instagram API with Instagram Login; users never share their password.

Key facts:
- Works with Instagram Creator and Business (professional) accounts.
- Pricing: ${PLANS.map((p) => `${p.name} ${p.price.usd.monthly === 0 ? "free" : `$${p.price.usd.monthly}/month (₹${p.price.inr.monthly}/month)`}`).join("; ")}.
- Free plan: 1,000 DMs per month, unlimited automations. Paid plans: unlimited DMs.
- Features: comment-to-DM, DM and Story-reply keyword automations, follow-to-unlock, re-run on comments from the last 7 days, public comment replies, link click tracking, contact export.
- Instagram rules: one private reply per comment, sent within 7 days; follow-ups only within 24 hours after the person replies.

## Pages
- [Home](${absoluteUrl("/")}): product overview and FAQ
- [Pricing](${absoluteUrl("/pricing")}): plans in USD and INR
${GUIDES.map((g) => `- [${g.title}](${absoluteUrl(`/guides/${g.slug}`)}): ${g.description}`).join("\n")}
${COMPARE_PAGES.map((c) => `- [${c.title}](${absoluteUrl(`/compare/${c.slug}`)}): ${c.description}`).join("\n")}

## Optional
- [Full text for language models](${absoluteUrl("/llms-full.txt")})
- [Privacy policy](${absoluteUrl("/privacy")})
`;
  return new Response(body, { headers: { "Content-Type": "text/plain; charset=utf-8" } });
}
