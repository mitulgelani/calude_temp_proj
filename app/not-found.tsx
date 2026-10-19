import Link from "next/link";
import { MarketingShell } from "@/components/MarketingShell";

export default function NotFound() {
  return (
    <MarketingShell>
      <section className="wrap py-28">
        <h1 className="text-[clamp(2.5rem,6vw,4.5rem)] font-extrabold leading-none tracking-[-0.045em]">This page didn&apos;t get the DM.</h1>
        <p className="mt-5 max-w-[46ch] text-lg text-ink-soft">The address may be mistyped, or the page has moved.</p>
        <Link href="/" className="btn btn-primary mt-8">
          Go to the home page
        </Link>
      </section>
    </MarketingShell>
  );
}
