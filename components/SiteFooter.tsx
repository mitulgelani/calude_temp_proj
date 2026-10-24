import Link from "next/link";
import { LinkMark } from "@/components/Logo";
import { COMPARE_PAGES, GUIDES } from "@/lib/content";
import { SUPPORT_EMAIL } from "@/lib/site";

export function SiteFooter() {
  return (
    <footer className="mt-24 bg-ink text-white/70">
      <div className="wrap grid gap-12 py-16 md:grid-cols-[1.4fr_1fr_1fr_1fr]">
        <div className="max-w-xs">
          <div className="flex items-center gap-2.5 text-white">
            <LinkMark className="h-7 w-7" />
            <span className="text-lg font-bold tracking-[-0.03em]">LinkPlz</span>
          </div>
          <p className="mt-4 text-sm leading-relaxed">
            Instagram comment-to-DM automation for creators. Built on Meta&apos;s official Instagram API.
          </p>
          <a href={`mailto:${SUPPORT_EMAIL}`} className="mt-4 inline-block text-sm text-white hover:underline">
            {SUPPORT_EMAIL}
          </a>
        </div>
        <FooterCol
          title="Product"
          links={[
            { href: "/#how-it-works", label: "How it works" },
            { href: "/pricing", label: "Pricing" },
            { href: "/login?mode=signup", label: "Start free" },
            { href: "/dashboard", label: "Dashboard" },
          ]}
        />
        <FooterCol
          title="Learn"
          links={[
            ...GUIDES.map((g) => ({ href: `/guides/${g.slug}`, label: g.title.split(":")[0].replace(/\s*\(.*\)$/, "") })),
            ...COMPARE_PAGES.map((c) => ({ href: `/compare/${c.slug}`, label: `LinkPlz vs ${c.competitor}` })),
          ]}
        />
        <FooterCol
          title="Legal"
          links={[
            { href: "/privacy", label: "Privacy policy" },
            { href: "/terms", label: "Terms of service" },
            { href: "/data-deletion", label: "Data deletion" },
          ]}
        />
      </div>
      <div className="wrap flex flex-col gap-2 border-t border-white/10 py-6 text-xs sm:flex-row sm:justify-between">
        <p>© {new Date().getFullYear()} LinkPlz. All rights reserved.</p>
        <p>Instagram is a trademark of Meta Platforms, Inc. LinkPlz is not affiliated with or endorsed by Meta.</p>
      </div>
    </footer>
  );
}

function FooterCol({ title, links }: { title: string; links: { href: string; label: string }[] }) {
  return (
    <div>
      <h2 className="text-sm font-semibold text-white">{title}</h2>
      <ul className="mt-4 space-y-2.5 text-sm">
        {links.map((l) => (
          <li key={l.href}>
            <Link href={l.href} className="hover:text-white">
              {l.label}
            </Link>
          </li>
        ))}
      </ul>
    </div>
  );
}
