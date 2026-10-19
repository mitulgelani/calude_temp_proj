import type { MatchMode } from "@/lib/match";

export type AccountView = {
  id: string;
  ig_user_id: string;
  username: string | null;
  name: string | null;
  profile_picture_url: string | null;
  token_expires_at: string | null;
  webhook_subscribed: boolean;
};

export type AutomationView = {
  id: string;
  ig_account_id: string;
  name: string;
  trigger: "comment" | "dm";
  media_id: string | null;
  media_permalink: string | null;
  media_thumbnail: string | null;
  match_mode: MatchMode;
  keywords: string[];
  dm_message: string;
  link_url: string | null;
  follow_gate: boolean;
  opener_message: string | null;
  public_replies: string[];
  short_code: string;
  is_active: boolean;
  sent_count: number;
  click_count: number;
  created_at: string;
};

export type EventView = {
  id: string;
  automation_id: string | null;
  kind: "comment" | "dm";
  from_username: string | null;
  text: string | null;
  status: "matched" | "sent" | "failed" | "skipped";
  error: string | null;
  created_at: string;
};

export type ContactView = {
  username: string | null;
  interactions: number;
  first_seen_at: string;
  last_seen_at: string;
};

export type MediaView = {
  id: string;
  caption: string;
  thumbnail: string | null;
  permalink: string | null;
  type: string;
  timestamp: string | null;
};

export type DashboardData = {
  demo: boolean;
  email: string | null;
  plan: string;
  accounts: AccountView[];
  automations: AutomationView[];
  events: EventView[];
  sentThisMonth: number;
};
