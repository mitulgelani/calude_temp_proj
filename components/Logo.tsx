import Link from "next/link";

export function LinkMark({ className = "h-7 w-7" }: { className?: string }) {
  return (
    <svg viewBox="0 0 32 32" className={className} aria-hidden="true">
      <rect width="32" height="32" rx="9" fill="#16132B" />
      <path d="M7 10.5A3.5 3.5 0 0 1 10.5 7h11a3.5 3.5 0 0 1 3.5 3.5v7a3.5 3.5 0 0 1-3.5 3.5H15.5L11 25.5V21h-.5A3.5 3.5 0 0 1 7 17.5z" fill="#fff" />
      <rect x="10.2" y="12" width="7" height="4" rx="2" fill="none" stroke="#5B32FF" strokeWidth="1.7" />
      <rect x="14.8" y="12" width="7" height="4" rx="2" fill="none" stroke="#FFB800" strokeWidth="1.7" />
    </svg>
  );
}

export function Logo({ href = "/" }: { href?: string }) {
  return (
    <Link href={href} className="flex items-center gap-2.5" aria-label="LinkPlz home">
      <LinkMark />
      <span className="text-[1.3rem] font-bold tracking-[-0.03em]">LinkPlz</span>
    </Link>
  );
}
