"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const ITEMS = [
  { href: "/dashboard", label: "Overview", icon: "M3 10.5 10 4l7 6.5V17a1 1 0 0 1-1 1h-4v-5H8v5H4a1 1 0 0 1-1-1z" },
  { href: "/dashboard/automations", label: "Automations", icon: "M11 2 4 11h5l-1 7 7-9h-5z" },
  { href: "/dashboard/contacts", label: "Contacts", icon: "M10 10a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7Zm-6 8a6 6 0 0 1 12 0" },
  { href: "/dashboard/settings", label: "Settings", icon: "M10 12.5a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5ZM10 2v2.5M10 15.5V18M2 10h2.5M15.5 10H18M4.3 4.3l1.8 1.8M13.9 13.9l1.8 1.8M4.3 15.7l1.8-1.8M13.9 6.1l1.8-1.8" },
];

export function DashboardNav() {
  const path = usePathname();
  return (
    <nav aria-label="Dashboard" className="-mx-1 flex gap-1 overflow-x-auto lg:mx-0 lg:mt-4 lg:flex-col">
      {ITEMS.map((item) => {
        const active = item.href === "/dashboard" ? path === "/dashboard" : path.startsWith(item.href);
        return (
          <Link
            key={item.href}
            href={item.href}
            aria-current={active ? "page" : undefined}
            className={`flex shrink-0 items-center gap-2.5 rounded-xl px-3 py-2 text-[0.95rem] font-medium transition-colors ${
              active ? "bg-ink text-white" : "text-ink-soft hover:bg-mist hover:text-ink"
            }`}
          >
            <svg viewBox="0 0 20 20" className="h-[18px] w-[18px]" aria-hidden="true">
              <path d={item.icon} fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
            {item.label}
          </Link>
        );
      })}
    </nav>
  );
}
