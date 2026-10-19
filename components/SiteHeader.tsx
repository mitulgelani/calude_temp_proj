import Link from "next/link";
import { Logo } from "@/components/Logo";

const NAV = [
  { href: "/#how-it-works", label: "How it works" },
  { href: "/pricing", label: "Pricing" },
  { href: "/guides/instagram-comment-to-dm", label: "Guides" },
  { href: "/compare/manychat", label: "Compare" },
];

export function SiteHeader() {
  return (
    <header className="sticky top-0 z-40 border-b border-transparent bg-mist/80 backdrop-blur-xl supports-[backdrop-filter]:bg-mist/70">
      <div className="wrap flex h-16 items-center justify-between gap-6">
        <Logo />
        <nav aria-label="Main" className="hidden items-center gap-7 text-[0.95rem] text-ink-soft md:flex">
          {NAV.map((n) => (
            <Link key={n.href} href={n.href} className="hover:text-ink">
              {n.label}
            </Link>
          ))}
        </nav>
        <div className="hidden items-center gap-2 md:flex">
          <Link href="/login" className="btn btn-sm text-ink-soft hover:text-ink">
            Log in
          </Link>
          <Link href="/login?mode=signup" className="btn btn-primary btn-sm">
            Start free
          </Link>
        </div>
        <details className="group relative md:hidden">
          <summary className="flex h-10 w-10 cursor-pointer list-none items-center justify-center rounded-full ring-1 ring-line [&::-webkit-details-marker]:hidden">
            <span className="sr-only">Open menu</span>
            <svg viewBox="0 0 20 20" className="h-5 w-5" aria-hidden="true">
              <path d="M3 6h14M3 10h14M3 14h14" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
            </svg>
          </summary>
          <div className="absolute right-0 top-12 w-64 rounded-2xl bg-paper p-3 shadow-[0_24px_60px_-20px_rgb(22_19_43/0.35)] ring-1 ring-line">
            {NAV.map((n) => (
              <Link key={n.href} href={n.href} className="block rounded-xl px-3 py-2.5 text-ink-soft hover:bg-mist hover:text-ink">
                {n.label}
              </Link>
            ))}
            <div className="mt-2 grid gap-2 border-t border-line pt-3">
              <Link href="/login" className="btn btn-ghost btn-sm">
                Log in
              </Link>
              <Link href="/login?mode=signup" className="btn btn-primary btn-sm">
                Start free
              </Link>
            </div>
          </div>
        </details>
      </div>
    </header>
  );
}
