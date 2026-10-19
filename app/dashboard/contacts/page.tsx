import { timeAgo } from "@/lib/dashboard";
import { DEMO_CONTACTS } from "@/lib/demo";
import { isSupabaseConfigured } from "@/lib/env";
import { supabaseServer } from "@/lib/supabase/server";
import type { ContactView } from "@/lib/types";

export default async function ContactsPage() {
  let contacts: ContactView[] = DEMO_CONTACTS;
  if (isSupabaseConfigured()) {
    const supabase = await supabaseServer();
    const { data } = await supabase
      .from("contacts")
      .select("username,interactions,first_seen_at,last_seen_at")
      .order("last_seen_at", { ascending: false })
      .limit(200);
    contacts = (data ?? []) as unknown as ContactView[];
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className="text-3xl font-extrabold tracking-[-0.035em] sm:text-4xl">Contacts</h1>
          <p className="mt-1 text-ink-soft">Everyone who received a DM from your automations.</p>
        </div>
        <a href="/api/contacts/export" className="btn btn-ghost" download>
          Export CSV
        </a>
      </div>
      {contacts.length === 0 ? (
        <div className="rounded-[24px] border border-dashed border-line px-6 py-16 text-center">
          <h2 className="text-xl font-bold">No contacts yet</h2>
          <p className="mx-auto mt-2 max-w-md text-ink-soft">People appear here the first time one of your automations sends them a DM.</p>
        </div>
      ) : (
        <div className="overflow-x-auto rounded-[24px] bg-paper ring-1 ring-line">
          <table className="w-full min-w-[520px] text-left text-sm">
            <thead>
              <tr className="border-b border-line text-muted">
                <th scope="col" className="px-5 py-3.5 font-medium">
                  Instagram
                </th>
                <th scope="col" className="px-5 py-3.5 font-medium">
                  DMs received
                </th>
                <th scope="col" className="px-5 py-3.5 font-medium">
                  First seen
                </th>
                <th scope="col" className="px-5 py-3.5 font-medium">
                  Last seen
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-line">
              {contacts.map((c, i) => (
                <tr key={`${c.username}-${i}`}>
                  <td className="px-5 py-3.5 font-semibold">{c.username ? `@${c.username}` : "Unknown"}</td>
                  <td className="px-5 py-3.5 tabular-nums">{c.interactions}</td>
                  <td className="px-5 py-3.5 text-ink-soft">{timeAgo(c.first_seen_at)}</td>
                  <td className="px-5 py-3.5 text-ink-soft">{timeAgo(c.last_seen_at)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
