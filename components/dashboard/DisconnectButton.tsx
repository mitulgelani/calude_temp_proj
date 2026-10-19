"use client";

import { useState, useTransition } from "react";
import { disconnectAccount } from "@/app/dashboard/actions";

export function DisconnectButton({ id, username }: { id: string; username: string | null }) {
  const [pending, start] = useTransition();
  const [note, setNote] = useState("");
  return (
    <div className="text-right">
      <button
        type="button"
        disabled={pending}
        onClick={() => {
          if (!window.confirm(`Disconnect @${username ?? "this account"}? Its automations, activity and contacts are deleted.`)) return;
          start(async () => setNote((await disconnectAccount(id)).message));
        }}
        className="btn btn-sm text-danger hover:bg-[#fdecec] disabled:opacity-60"
      >
        {pending ? "Disconnecting…" : "Disconnect"}
      </button>
      {note ? <p className="mt-1 max-w-[16rem] text-xs text-ink-soft">{note}</p> : null}
    </div>
  );
}
