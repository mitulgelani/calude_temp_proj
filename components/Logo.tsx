import Link from "next/link";

export function HookMark({ className = "h-7 w-7" }: { className?: string }) {
  return (
    <svg viewBox="0 0 32 32" className={className} aria-hidden="true">
      <rect width="32" height="32" rx="9" fill="#16132B" />
      <path
        d="M19.5 7.5v10.25a5.25 5.25 0 0 1-10.5 0V15.5"
        fill="none"
        stroke="#fff"
        strokeWidth="3"
        strokeLinecap="round"
      />
      <path d="M9 15.5l-2.6 2.9M9 15.5l2.6 2.9" stroke="#FFE14D" strokeWidth="2.6" strokeLinecap="round" />
      <circle cx="19.5" cy="7.5" r="2.4" fill="#FFE14D" />
    </svg>
  );
}

export function Logo({ href = "/" }: { href?: string }) {
  return (
    <Link href={href} className="flex items-center gap-2.5" aria-label="Hookline home">
      <HookMark />
      <span className="text-[1.3rem] font-bold tracking-[-0.03em]">Hookline</span>
    </Link>
  );
}
