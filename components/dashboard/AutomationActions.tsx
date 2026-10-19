"use client";

import { useState, useTransition } from "react";
import { deleteAutomation, rerunAutomation, setAutomationActive } from "@/app/dashboard/actions";

export function AutomationActions({ id, active, canRerun }: { id: string; active: boolean; canRerun: boolean }) {
  const [on, setOn] = useState(active);
  const [pending, start] = useTransition();
  const [note, setNote] = useState<{ ok: boolean; text: string } | null>(null);

  function toggle() {
    const next = !on;
    setOn(next);
    start(async () => {
      const res = await setAutomationActive(id, next);
      if (!res.ok) setOn(!next);
      setNote({ ok: res.ok, text: res.message });
    });
  }

  function rerun() {
    setNote(null);
    start(async () => {
      const res = await rerunAutomation(id);
      setNote({ ok: res.ok, text: res.message });
    });
  }

  function remove() {
    if (!window.confirm("Delete this automation? Its stats are deleted too. This can't be undone.")) return;
    start(async () => {
      const res = await deleteAutomation(id);
      setNote({ ok: res.ok, text: res.message });
    });
  }

  return (
    <div className="flex flex-col items-start gap-2 sm:items-end">
      <div className="flex flex-wrap items-center gap-2">
        <button
          type="button"
          role="switch"
          aria-checked={on}
          onClick={toggle}
          disabled={pending}
          className={`relative h-7 w-12 rounded-full transition-colors ${on ? "bg-mint" : "bg-line"} disabled:opacity-60`}
        >
          <span className="sr-only">{on ? "Pause automation" : "Turn on automation"}</span>
          <span className={`absolute top-1 h-5 w-5 rounded-full bg-white shadow transition-[left] ${on ? "left-6" : "left-1"}`} />
        </button>
        {canRerun ? (
          <button type="button" onClick={rerun} disabled={pending} className="btn btn-ghost btn-sm disabled:opacity-60">
            {pending ? "Working…" : "Re-run last 7 days"}
          </button>
        ) : null}
        <button type="button" onClick={remove} disabled={pending} className="btn btn-sm text-danger hover:bg-[#fdecec] disabled:opacity-60">
          Delete
        </button>
      </div>
      {note ? (
        <p role="status" className={`max-w-xs text-xs sm:text-right ${note.ok ? "text-mint" : "text-ink-soft"}`}>
          {note.text}
        </p>
      ) : null}
    </div>
  );
}
