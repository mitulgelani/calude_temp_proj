"use client";

import { useState } from "react";
import { supabaseBrowser } from "@/lib/supabase/client";

export function LoginForm({ next, signup }: { next: string; signup: boolean }) {
  const [email, setEmail] = useState("");
  const [status, setStatus] = useState<"idle" | "sending" | "sent" | "error">("idle");
  const [message, setMessage] = useState("");

  const redirectTo = () => `${window.location.origin}/auth/callback?next=${encodeURIComponent(next)}`;

  async function sendLink(e: React.FormEvent) {
    e.preventDefault();
    setStatus("sending");
    const { error } = await supabaseBrowser().auth.signInWithOtp({
      email,
      options: { emailRedirectTo: redirectTo(), shouldCreateUser: true },
    });
    if (error) {
      setStatus("error");
      setMessage(error.message);
    } else {
      setStatus("sent");
    }
  }

  async function google() {
    const { error } = await supabaseBrowser().auth.signInWithOAuth({
      provider: "google",
      options: { redirectTo: redirectTo() },
    });
    if (error) {
      setStatus("error");
      setMessage(error.message);
    }
  }

  if (status === "sent") {
    return (
      <div className="mt-8 rounded-2xl bg-paper p-5 ring-1 ring-line" role="status">
        <p className="font-semibold">Check your inbox</p>
        <p className="mt-1.5 text-sm text-ink-soft">
          We sent a sign-in link to <strong>{email}</strong>. Open it on this device to continue.
        </p>
      </div>
    );
  }

  return (
    <div className="mt-8 space-y-4">
      <button type="button" onClick={google} className="btn btn-ghost w-full bg-paper">
        <svg viewBox="0 0 24 24" className="h-5 w-5" aria-hidden="true">
          <path fill="#4285F4" d="M22.5 12.3c0-.8-.1-1.5-.2-2.2H12v4.2h5.9a5 5 0 0 1-2.2 3.3v2.7h3.6c2-1.9 3.2-4.7 3.2-8z" />
          <path fill="#34A853" d="M12 23c3 0 5.5-1 7.3-2.7l-3.6-2.7c-1 .7-2.2 1.1-3.7 1.1-2.9 0-5.3-1.9-6.2-4.5H2.1v2.8A11 11 0 0 0 12 23z" />
          <path fill="#FBBC05" d="M5.8 14.2a6.6 6.6 0 0 1 0-4.3V7.1H2.1a11 11 0 0 0 0 9.9l3.7-2.8z" />
          <path fill="#EA4335" d="M12 5.4c1.6 0 3.1.6 4.2 1.7l3.2-3.2A11 11 0 0 0 2.1 7.1l3.7 2.8C6.7 7.3 9.1 5.4 12 5.4z" />
        </svg>
        Continue with Google
      </button>
      <div className="flex items-center gap-3 text-xs text-muted">
        <span className="h-px flex-1 bg-line" />
        or use your email
        <span className="h-px flex-1 bg-line" />
      </div>
      <form onSubmit={sendLink} className="space-y-3">
        <label htmlFor="email" className="label">
          Email
        </label>
        <input
          id="email"
          type="email"
          required
          autoComplete="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          className="field"
          placeholder="you@example.com"
        />
        <button type="submit" disabled={status === "sending"} className="btn btn-primary w-full disabled:opacity-60">
          {status === "sending" ? "Sending link…" : signup ? "Create account" : "Email me a sign-in link"}
        </button>
        {status === "error" ? (
          <p role="alert" className="text-sm text-danger">
            {message}
          </p>
        ) : null}
      </form>
    </div>
  );
}
