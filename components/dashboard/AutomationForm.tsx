"use client";

import Link from "next/link";
import { useActionState, useEffect, useState } from "react";
import { saveAutomation, type ActionState } from "@/app/dashboard/actions";
import { fillTemplate, matchesKeywords, type MatchMode } from "@/lib/match";
import type { AccountView, AutomationView, MediaView } from "@/lib/types";

const INITIAL: ActionState = { ok: false, message: "" };

export function AutomationForm({
  accounts,
  initial,
  plan,
  demo,
}: {
  accounts: AccountView[];
  initial?: AutomationView;
  plan: string;
  demo: boolean;
}) {
  const [state, formAction, pending] = useActionState(saveAutomation, INITIAL);

  const [accountId, setAccountId] = useState(initial?.ig_account_id ?? accounts[0]?.id ?? "");
  const [trigger, setTrigger] = useState<"comment" | "dm">(initial?.trigger ?? "comment");
  const [mediaId, setMediaId] = useState<string | null>(initial?.media_id ?? null);
  const [media, setMedia] = useState<MediaView[] | null>(null);
  const [mediaError, setMediaError] = useState("");
  const [mode, setMode] = useState<MatchMode>(initial?.match_mode ?? "contains");
  const [keywords, setKeywords] = useState<string[]>(initial?.keywords ?? []);
  const [draft, setDraft] = useState("");
  const [message, setMessage] = useState(initial?.dm_message ?? "Hey {username}! Here's the link you asked for ✨");
  const [link, setLink] = useState(initial?.link_url ?? "");
  const [followGate, setFollowGate] = useState(initial?.follow_gate ?? false);
  const [opener, setOpener] = useState(initial?.opener_message ?? "");
  const [replies, setReplies] = useState((initial?.public_replies ?? ["Sent! Check your DMs 📩", "Just sent it over 💌"]).join("\n"));
  const [testComment, setTestComment] = useState("LINK please!");
  const [host, setHost] = useState("hookline.app");

  useEffect(() => setHost(window.location.host), []);

  useEffect(() => {
    if (trigger !== "comment" || !accountId) return;
    let cancelled = false;
    setMedia(null);
    setMediaError("");
    fetch(`/api/instagram/media?account=${encodeURIComponent(accountId)}`)
      .then((r) => r.json())
      .then((json: { media?: MediaView[]; error?: string }) => {
        if (cancelled) return;
        if (json.error) setMediaError(json.error);
        setMedia(json.media ?? []);
      })
      .catch(() => !cancelled && setMediaError("Couldn't load your posts. You can still run this on any post."));
    return () => {
      cancelled = true;
    };
  }, [accountId, trigger]);

  function addKeyword(raw: string) {
    const parts = raw
      .split(",")
      .map((k) => k.trim())
      .filter(Boolean);
    if (!parts.length) return;
    setKeywords((prev) => Array.from(new Set([...prev, ...parts])).slice(0, 20));
    setDraft("");
  }

  const selected = media?.find((m) => m.id === mediaId) ?? null;
  const isMatch = matchesKeywords(testComment, mode, draft.trim() ? [...keywords, draft.trim()] : keywords);
  const preview = fillTemplate(message, { username: "riya.wanders" });
  const err = state.errors ?? {};
  const freePlan = plan === "free";

  if (!accounts.length) {
    return (
      <div className="rounded-[24px] bg-ink p-8 text-white">
        <h2 className="text-2xl font-bold">Connect Instagram first</h2>
        <p className="mt-2 text-white/75">Automations run on a connected Creator or Business account.</p>
        <a href="/api/instagram/connect" className="btn mt-6 bg-white text-ink hover:bg-marker">
          Connect Instagram
        </a>
      </div>
    );
  }

  return (
    <form action={formAction} className="grid gap-8 lg:grid-cols-[1.25fr_1fr]">
      {initial ? <input type="hidden" name="id" value={initial.id} /> : null}
      <input type="hidden" name="keywords" value={[...keywords, ...(draft.trim() ? [draft.trim()] : [])].join(",")} />
      <input type="hidden" name="media_id" value={trigger === "comment" ? mediaId ?? "" : ""} />
      <input type="hidden" name="media_thumbnail" value={selected?.thumbnail ?? initial?.media_thumbnail ?? ""} />
      <input type="hidden" name="media_permalink" value={selected?.permalink ?? initial?.media_permalink ?? ""} />

      <div className="space-y-6">
        <Section title="Name and account">
          <div>
            <label htmlFor="name" className="label">
              Name
            </label>
            <input id="name" name="name" className="field" defaultValue={initial?.name ?? ""} placeholder="Lisbon preset pack" maxLength={80} aria-invalid={Boolean(err.name)} />
            <FieldError text={err.name} />
          </div>
          {accounts.length > 1 ? (
            <div>
              <label htmlFor="ig_account_id" className="label">
                Instagram account
              </label>
              <select id="ig_account_id" name="ig_account_id" className="field" value={accountId} onChange={(e) => setAccountId(e.target.value)}>
                {accounts.map((a) => (
                  <option key={a.id} value={a.id}>
                    @{a.username}
                  </option>
                ))}
              </select>
            </div>
          ) : (
            <input type="hidden" name="ig_account_id" value={accountId} />
          )}
        </Section>

        <Section title="When should it reply?">
          <fieldset>
            <legend className="sr-only">Trigger</legend>
            <div className="grid gap-2 sm:grid-cols-2">
              <Choice name="trigger" value="comment" checked={trigger === "comment"} onChange={() => setTrigger("comment")} title="Someone comments" body="On a Reel, post or Live" />
              <Choice name="trigger" value="dm" checked={trigger === "dm"} onChange={() => setTrigger("dm")} title="Someone DMs you" body="Includes replies to your Stories" />
            </div>
          </fieldset>

          {trigger === "comment" ? (
            <div>
              <p className="label">Which post?</p>
              <div className="grid grid-cols-3 gap-2 sm:grid-cols-4">
                <button
                  type="button"
                  onClick={() => setMediaId(null)}
                  aria-pressed={mediaId === null}
                  className={`flex aspect-[4/5] flex-col justify-end rounded-2xl p-2.5 text-left text-xs font-semibold ring-2 transition ${
                    mediaId === null ? "bg-ink text-white ring-violet" : "bg-mist text-ink-soft ring-transparent hover:ring-line"
                  }`}
                >
                  Any post or Reel
                </button>
                {media === null && !mediaError
                  ? Array.from({ length: 3 }).map((_, i) => <span key={i} className="aspect-[4/5] animate-pulse rounded-2xl bg-mist" />)
                  : (media ?? []).slice(0, 11).map((m) => (
                      <button
                        key={m.id}
                        type="button"
                        onClick={() => setMediaId(m.id)}
                        aria-pressed={mediaId === m.id}
                        title={m.caption}
                        className={`relative aspect-[4/5] overflow-hidden rounded-2xl text-left ring-2 transition ${mediaId === m.id ? "ring-violet" : "ring-transparent hover:ring-line"}`}
                      >
                        {m.thumbnail ? (
                          // eslint-disable-next-line @next/next/no-img-element
                          <img src={m.thumbnail} alt="" className="h-full w-full object-cover" loading="lazy" />
                        ) : (
                          <span className="flex h-full w-full items-end bg-[linear-gradient(160deg,#ffb36b,#ff5fa2_45%,#5b32ff)] p-2 text-[0.68rem] font-semibold leading-tight text-white">
                            <span className="line-clamp-4">{m.caption || "Untitled post"}</span>
                          </span>
                        )}
                        {m.type === "VIDEO" ? <span className="absolute right-1.5 top-1.5 rounded-full bg-black/50 px-1.5 py-0.5 text-[0.6rem] text-white">Reel</span> : null}
                      </button>
                    ))}
              </div>
              {mediaError ? <p className="hint">{mediaError}</p> : <p className="hint">Rules on a specific post win over “Any post” rules.</p>}
            </div>
          ) : null}

          <fieldset>
            <legend className="label">Match</legend>
            <div className="grid gap-2 sm:grid-cols-3">
              <Choice name="match_mode" value="contains" checked={mode === "contains"} onChange={() => setMode("contains")} title="Contains a keyword" body="“link pls” matches LINK" />
              <Choice name="match_mode" value="exact" checked={mode === "exact"} onChange={() => setMode("exact")} title="Exactly the keyword" body="Only “link” matches" />
              <Choice name="match_mode" value="any" checked={mode === "any"} onChange={() => setMode("any")} title={trigger === "dm" ? "Any message" : "Any comment"} body="Good for giveaways" />
            </div>
          </fieldset>

          {mode !== "any" ? (
            <div>
              <label htmlFor="kw" className="label">
                Keywords
              </label>
              <div className={`field flex flex-wrap items-center gap-1.5 ${err.keywords ? "border-danger" : ""}`}>
                {keywords.map((k) => (
                  <span key={k} className="inline-flex items-center gap-1 rounded-full bg-marker px-2.5 py-1 text-sm font-semibold">
                    {k}
                    <button type="button" onClick={() => setKeywords((p) => p.filter((x) => x !== k))} className="text-ink-soft hover:text-ink" aria-label={`Remove ${k}`}>
                      ×
                    </button>
                  </span>
                ))}
                <input
                  id="kw"
                  value={draft}
                  onChange={(e) => setDraft(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === "Enter" || e.key === ",") {
                      e.preventDefault();
                      addKeyword(draft);
                    } else if (e.key === "Backspace" && !draft && keywords.length) {
                      setKeywords((p) => p.slice(0, -1));
                    }
                  }}
                  onBlur={() => addKeyword(draft)}
                  placeholder={keywords.length ? "Add another" : "LINK, GUIDE, PRESET"}
                  className="min-w-[8rem] flex-1 bg-transparent py-1 outline-none"
                />
              </div>
              <FieldError text={err.keywords} />
              {!err.keywords ? <p className="hint">Press Enter after each. Capitals, emoji and punctuation don&apos;t matter.</p> : null}
            </div>
          ) : null}
        </Section>

        <Section title="What do they receive?">
          <div>
            <label htmlFor="dm_message" className="label">
              DM message
            </label>
            <textarea
              id="dm_message"
              name="dm_message"
              rows={4}
              className="field resize-y"
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              maxLength={900}
              aria-invalid={Boolean(err.dm_message)}
            />
            <FieldError text={err.dm_message} />
            {!err.dm_message ? <p className="hint">Use {"{username}"} to greet them by name. {900 - message.length} characters left.</p> : null}
          </div>
          <div>
            <label htmlFor="link_url" className="label">
              Link
            </label>
            <input id="link_url" name="link_url" type="url" inputMode="url" className="field" value={link} onChange={(e) => setLink(e.target.value)} placeholder="https://" aria-invalid={Boolean(err.link_url)} />
            <FieldError text={err.link_url} />
            {!err.link_url ? <p className="hint">Sent as a short tracked link so you can see clicks.</p> : null}
          </div>

          <div className="rounded-2xl bg-mist p-4">
            <label className="flex cursor-pointer items-start justify-between gap-4">
              <span>
                <span className="block font-semibold">Only send the link to followers</span>
                <span className="mt-0.5 block text-sm text-ink-soft">
                  Hookline sends a short opener first. When they reply, followers get the link and everyone else is asked to follow.
                  {freePlan ? " Available on the Creator plan." : ""}
                </span>
              </span>
              <input type="checkbox" name="follow_gate" checked={followGate} onChange={(e) => setFollowGate(e.target.checked)} className="mt-1 h-5 w-5 shrink-0 accent-[#5B32FF]" />
            </label>
            <FieldError text={err.follow_gate} />
            {followGate ? (
              <div className="mt-4">
                <label htmlFor="opener_message" className="label">
                  Opener message
                </label>
                <textarea
                  id="opener_message"
                  name="opener_message"
                  rows={2}
                  className="field"
                  value={opener}
                  onChange={(e) => setOpener(e.target.value)}
                  placeholder="Hey! Reply to this message with anything and I'll send the link right over 👇"
                />
              </div>
            ) : null}
          </div>

          {trigger === "comment" ? (
            <div>
              <label htmlFor="public_replies" className="label">
                Public replies under the comment
              </label>
              <textarea id="public_replies" name="public_replies" rows={3} className="field" value={replies} onChange={(e) => setReplies(e.target.value)} placeholder={"Sent! Check your DMs 📩"} />
              <p className="hint">One per line. Hookline picks one at random each time. Leave empty to reply only in DMs.</p>
            </div>
          ) : null}
        </Section>

        {state.message && !state.ok ? (
          <p role="alert" className={`rounded-2xl px-4 py-3 text-sm ${demo ? "bg-[#fff6cc] text-ink" : "bg-[#fdecec] text-danger"}`}>
            {state.message}
          </p>
        ) : null}

        <div className="flex flex-wrap items-center gap-3">
          <button type="submit" disabled={pending} className="btn btn-violet disabled:opacity-60">
            {pending ? "Saving…" : initial ? "Save changes" : "Save and turn on"}
          </button>
          <Link href="/dashboard/automations" className="btn btn-ghost">
            Cancel
          </Link>
        </div>
      </div>

      {/* Live preview */}
      <aside className="lg:sticky lg:top-8 lg:self-start" aria-label="Preview">
        <div className="rounded-[30px] bg-paper p-5 ring-1 ring-line">
          <p className="text-sm font-semibold">Preview</p>
          <label htmlFor="test_comment" className="mt-4 block text-xs text-muted">
            Try a {trigger === "dm" ? "message" : "comment"}
          </label>
          <input id="test_comment" value={testComment} onChange={(e) => setTestComment(e.target.value)} className="field mt-1.5" />
          <p className={`mt-2 text-sm font-semibold ${isMatch ? "text-mint" : "text-muted"}`} aria-live="polite">
            {isMatch ? "Matches, so this person gets the DM" : "No match, nothing is sent"}
          </p>

          <div className="mt-5 rounded-[24px] bg-mist p-4">
            <p className="text-center text-[0.7rem] text-muted">riya.wanders · Instagram DM</p>
            <div className={`mt-3 space-y-2 transition-opacity ${isMatch ? "opacity-100" : "opacity-40"}`}>
              {followGate ? (
                <>
                  <Bubble>{opener || "Hey! Reply to this message with anything and I'll send the link right over 👇"}</Bubble>
                  <div className="w-fit max-w-[80%] rounded-[20px] rounded-bl-md bg-paper px-3.5 py-2 text-sm">yes please!</div>
                </>
              ) : null}
              <Bubble>
                <span className="whitespace-pre-wrap">{preview || "Your message appears here"}</span>
                {link ? (
                  <span className="mt-1.5 block truncate rounded-lg px-2 py-1 text-xs underline" style={{ backgroundColor: "rgb(255 255 255 / 0.18)" }}>
                    {host}/r/{initial?.short_code ?? "abc1234"}
                  </span>
                ) : null}
              </Bubble>
            </div>
          </div>
          {trigger === "comment" && replies.trim() ? (
            <p className="mt-4 text-sm text-ink-soft">
              <span className="font-semibold text-ink">you.create</span> replied publicly: {replies.split("\n").find(Boolean)}
            </p>
          ) : null}
        </div>
      </aside>
    </form>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="space-y-4 rounded-[24px] bg-paper p-5 ring-1 ring-line sm:p-6">
      <h2 className="text-lg font-bold tracking-[-0.01em]">{title}</h2>
      {children}
    </section>
  );
}

function Choice({ name, value, checked, onChange, title, body }: { name: string; value: string; checked: boolean; onChange: () => void; title: string; body: string }) {
  return (
    <label className={`cursor-pointer rounded-2xl p-3.5 ring-2 transition ${checked ? "bg-paper ring-violet" : "bg-mist ring-transparent hover:ring-line"}`}>
      <input type="radio" name={name} value={value} checked={checked} onChange={onChange} className="sr-only" />
      <span className="block text-sm font-semibold">{title}</span>
      <span className="mt-0.5 block text-xs text-ink-soft">{body}</span>
    </label>
  );
}

function Bubble({ children }: { children: React.ReactNode }) {
  return <div className="dm-bubble ml-auto w-fit max-w-[88%] px-3.5 py-2.5 text-sm leading-snug">{children}</div>;
}

function FieldError({ text }: { text?: string }) {
  return text ? (
    <p role="alert" className="mt-1.5 text-sm text-danger">
      {text}
    </p>
  ) : null;
}
