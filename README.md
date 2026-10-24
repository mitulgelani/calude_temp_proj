# LinkPlz

Instagram comment-to-DM automation for creators. Someone comments a keyword like **LINK** on a Reel, and LinkPlz sends them a DM with your link within seconds, using Meta's official Instagram API with Instagram Login.

**Stack:** Next.js 15 (App Router) · Tailwind CSS 4 · Supabase (Postgres + Auth) · Vercel. Running cost at launch: $0 on free tiers (Vercel Hobby is non-commercial, so move to Pro at $20/month once you charge customers).

Without any environment variables the app runs in **demo mode**: the marketing site is complete and the dashboard shows sample data, so you can deploy first and connect services after.

## What's included

| Area | Details |
| --- | --- |
| Marketing | Landing page with live comment-to-DM simulation, time-saved calculator, pricing (USD/INR, monthly/yearly), FAQ, 3 SEO guides, 2 comparison pages, privacy, terms, data deletion |
| Engine | Instagram webhook (signature-verified), keyword matching, private replies, public comment replies with rotation, follow-to-unlock, DM and Story-reply keywords, retry-safe dedupe, Free-plan quota, re-run on last 7 days, viral-spike queue that stays under Meta's 750 private replies/hour per account and sends the backlog within the 7-day window |
| Dashboard | Overview stats, activity feed, automations list with on/off and re-run, automation builder with live DM preview and keyword tester, contacts with CSV export, settings with account connect/disconnect and plan |
| SEO / AEO / GEO | Metadata + canonicals, `sitemap.xml`, `robots.txt` welcoming AI crawlers, `llms.txt` and `llms-full.txt`, JSON-LD typed with Google's open-source [`schema-dts`](https://github.com/google/schema-dts) (Organization, WebSite, SoftwareApplication, FAQPage, Article, BreadcrumbList), generated Open Graph image |
| Security | AES-256-GCM encrypted tokens, row-level security on every table, tokens never readable from the browser, CSRF state on OAuth, Meta signed_request verification |

## Go live checklist

### 1. Deploy to Vercel (2 minutes)
1. Go to <https://vercel.com/new>, import this GitHub repository, and click **Deploy** (no settings needed).
2. Optional: rename the repo on GitHub first; Vercel follows the rename.

### 2. Supabase (5 minutes)
1. Create a project at <https://supabase.com> (free).
2. SQL Editor → paste `supabase/schema.sql` → Run.
3. Authentication → URL configuration: set Site URL to your Vercel URL and add `https://YOUR-DOMAIN/auth/callback` to redirect URLs.
4. Optional: Authentication → Providers → enable Google.
5. In Vercel → Settings → Environment Variables add `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `ENCRYPTION_KEY` (`openssl rand -base64 32`), `CRON_SECRET`, `NEXT_PUBLIC_SITE_URL`. Redeploy.

### 3. Meta / Instagram app (15 minutes, then App Review)
1. <https://developers.facebook.com> → Create app → type **Business** → add the **Instagram** product → *API setup with Instagram login*.
2. Copy the Instagram app ID and secret into `INSTAGRAM_APP_ID` / `INSTAGRAM_APP_SECRET`. Pick any string for `INSTAGRAM_WEBHOOK_VERIFY_TOKEN`.
3. Business login settings → OAuth redirect URI: `https://YOUR-DOMAIN/api/instagram/callback`.
4. Webhooks → Callback URL `https://YOUR-DOMAIN/api/webhooks/instagram`, verify token as above → subscribe to `comments`, `live_comments`, `messages`, `messaging_postbacks`.
5. App settings: Privacy policy `https://YOUR-DOMAIN/privacy`, Terms `https://YOUR-DOMAIN/terms`, Data deletion callback `https://YOUR-DOMAIN/api/instagram/data-deletion`, Deauthorize callback `https://YOUR-DOMAIN/api/instagram/deauthorize`.
6. Add your own Instagram account as a tester (App roles) — it works immediately for accounts on the app (Standard Access).
7. Submit **App Review** for Advanced Access to `instagram_business_basic`, `instagram_business_manage_comments`, `instagram_business_manage_messages` so other creators can connect. Record a screencast of: login → connect Instagram → create automation → comment on a post → DM arrives.
8. Later: apply for **Meta Tech Provider** verification (business verification) to remove limits and earn the trust badge competitors show.

### 4. Payments (optional)
Payments run on Dodo Payments (live mode). The four live product IDs and the business ID are defaults in `lib/billing.ts`; override them with `DODO_PRODUCT_CREATOR_MONTHLY`, `DODO_PRODUCT_CREATOR_YEARLY`, `DODO_PRODUCT_STUDIO_MONTHLY`, `DODO_PRODUCT_STUDIO_YEARLY` and `DODO_BUSINESS_ID`, and set `DODO_CHECKOUT_BASE=https://test.checkout.dodopayments.com` to use test mode. Paid buttons go to `/api/billing/checkout`, which signs the user in and opens Dodo checkout with their email locked and `metadata_user_id` attached. Put the endpoint's signing secret in `DODO_WEBHOOK_SECRET`. Webhook URL: `https://YOUR-DOMAIN/api/billing/webhook` (subscription events).

### 5. Organic traffic
Add the domain to Google Search Console and Bing Webmaster Tools and submit `/sitemap.xml`. Add guides to `lib/content.ts`; they automatically appear in the sitemap, `llms.txt` and footer.

## Local development
```bash
npm install
cp .env.example .env.local   # optional — empty means demo mode
npm run dev
```

## Open-source references
The engine design follows the patterns used by the most-starred open-source comment-to-DM projects (official private-replies API, webhook → keyword match → one API call, fail-open follow checks, comment-ID dedupe): `ayuuxh2/insta-p8`, `im-anishraj/instagram-comment-to-dm`, `ryanlaiyanip-ctrl/chatmany`. No code was copied.
