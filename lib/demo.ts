import type { AccountView, AutomationView, ContactView, DashboardData, EventView, MediaView } from "@/lib/types";

const now = Date.now();
const ago = (mins: number) => new Date(now - mins * 60_000).toISOString();

export const DEMO_ACCOUNT: AccountView = {
  id: "demo-account",
  ig_user_id: "17841400000000000",
  username: "you.create",
  name: "You Create",
  profile_picture_url: null,
  token_expires_at: new Date(now + 55 * 86_400_000).toISOString(),
  webhook_subscribed: true,
};

export const DEMO_MEDIA: MediaView[] = [
  { id: "m1", caption: "Comment LINK for my Lisbon preset pack 🇵🇹", thumbnail: null, permalink: null, type: "VIDEO", timestamp: ago(60 * 20) },
  { id: "m2", caption: "The 3 apps I use to edit every Reel — comment APPS", thumbnail: null, permalink: null, type: "VIDEO", timestamp: ago(60 * 70) },
  { id: "m3", caption: "My exact morning routine. Comment PLAN for the PDF", thumbnail: null, permalink: null, type: "CAROUSEL_ALBUM", timestamp: ago(60 * 140) },
  { id: "m4", caption: "Golden hour in Sintra", thumbnail: null, permalink: null, type: "IMAGE", timestamp: ago(60 * 220) },
];

export const DEMO_AUTOMATIONS: AutomationView[] = [
  {
    id: "demo-1",
    ig_account_id: DEMO_ACCOUNT.id,
    name: "Lisbon preset pack",
    trigger: "comment",
    media_id: "m1",
    media_permalink: null,
    media_thumbnail: null,
    match_mode: "contains",
    keywords: ["LINK", "LINKS", "PRESET"],
    dm_message: "Hey {username}! Here's the Lisbon preset pack you asked for ✨",
    link_url: "https://example.com/lisbon-presets",
    follow_gate: true,
    opener_message: null,
    public_replies: ["Sent! Check your DMs 📩", "Just sent it over 💌", "In your inbox now ✨"],
    short_code: "lisbon1",
    is_active: true,
    sent_count: 2841,
    click_count: 1906,
    created_at: ago(60 * 24 * 3),
  },
  {
    id: "demo-2",
    ig_account_id: DEMO_ACCOUNT.id,
    name: "Editing apps list",
    trigger: "comment",
    media_id: "m2",
    media_permalink: null,
    media_thumbnail: null,
    match_mode: "contains",
    keywords: ["APPS"],
    dm_message: "Here are the three apps I edit every Reel with 👇",
    link_url: "https://example.com/apps",
    follow_gate: false,
    opener_message: null,
    public_replies: ["Check your DMs!"],
    short_code: "apps22",
    is_active: true,
    sent_count: 1204,
    click_count: 733,
    created_at: ago(60 * 24 * 6),
  },
  {
    id: "demo-3",
    ig_account_id: DEMO_ACCOUNT.id,
    name: "Collab enquiries",
    trigger: "dm",
    media_id: null,
    media_permalink: null,
    media_thumbnail: null,
    match_mode: "contains",
    keywords: ["COLLAB", "BRAND", "PR"],
    dm_message: "Thanks for reaching out! My media kit and rates are here, and I reply to every brand within 48 hours.",
    link_url: "https://example.com/media-kit",
    follow_gate: false,
    opener_message: null,
    public_replies: [],
    short_code: "collab9",
    is_active: false,
    sent_count: 37,
    click_count: 29,
    created_at: ago(60 * 24 * 12),
  },
];

const names = ["riya.wanders", "meera.codes", "sana.k", "dev_travels", "aanya.eats", "kabir.fit", "zoe.makes", "ishaan.dev"];
const texts = ["LINK please 🙏", "link!!", "Link 😍", "LINK", "preset pls", "APPS", "apps 🙌", "link plz"];

export const DEMO_EVENTS: EventView[] = names.map((n, i): EventView => ({
  id: `e${i}`,
  automation_id: i < 5 ? "demo-1" : "demo-2",
  kind: "comment",
  from_username: n,
  text: texts[i],
  status: i === 6 ? "failed" : "sent",
  error: i === 6 ? "The comment is older than 7 days" : null,
  created_at: ago(i * 3 + 1),
}));

export const DEMO_CONTACTS: ContactView[] = names.map((n, i) => ({
  username: n,
  interactions: 1 + ((i * 7) % 5),
  first_seen_at: ago(60 * 24 * (i + 1)),
  last_seen_at: ago(i * 3 + 1),
}));

export const DEMO_DATA: DashboardData = {
  demo: true,
  email: "demo@hookline.app",
  plan: "creator",
  accounts: [DEMO_ACCOUNT],
  automations: DEMO_AUTOMATIONS,
  events: DEMO_EVENTS,
  sentThisMonth: 4082,
};
