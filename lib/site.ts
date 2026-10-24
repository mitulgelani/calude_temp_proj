export const SITE_NAME = "LinkPlz";
export const SITE_TITLE = "LinkPlz — Instagram Comment-to-DM Automation for Creators";
export const SITE_DESCRIPTION =
  "Auto-DM everyone who comments a keyword on your Instagram Reels, posts and Stories. Free plan, built on Meta's official Instagram API, set up in two minutes.";
export const SUPPORT_EMAIL = process.env.NEXT_PUBLIC_SUPPORT_EMAIL || "hello@linkplz.online";
export const LAST_UPDATED = "2026-10-19";

export function siteUrl(): string {
  const explicit = process.env.NEXT_PUBLIC_SITE_URL;
  if (explicit) return explicit.replace(/\/$/, "");
  const vercel = process.env.VERCEL_PROJECT_PRODUCTION_URL;
  if (vercel) return `https://${vercel}`;
  return "http://localhost:3000";
}

export function absoluteUrl(path = "/"): string {
  return `${siteUrl()}${path.startsWith("/") ? path : `/${path}`}`;
}
