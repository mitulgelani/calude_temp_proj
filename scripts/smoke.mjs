// Smoke test: checks key routes respond and saves screenshots to ci-out/.
import { chromium } from "playwright";

const BASE = "http://localhost:3000";
const results = [];

async function check(path, expect = 200, contains) {
  const res = await fetch(BASE + path, { redirect: "manual" });
  const text = await res.text();
  const ok = res.status === expect && (!contains || text.includes(contains));
  results.push(`${ok ? "PASS" : "FAIL"} ${path} -> ${res.status}${contains ? ` (contains "${contains}": ${text.includes(contains)})` : ""}`);
}

await check("/", 200, "Auto-DM everyone");
await check("/pricing", 200, "Creator");
await check("/guides/instagram-comment-to-dm", 200, "comment-to-DM");
await check("/compare/manychat", 200, "ManyChat");
await check("/privacy", 200, "Privacy");
await check("/data-deletion", 200, "Delete your data");
await check("/sitemap.xml", 200, "<urlset");
await check("/robots.txt", 200, "GPTBot");
await check("/llms.txt", 200, "# Hookline");
await check("/llms-full.txt", 200, "Plans");
await check("/opengraph-image", 200);
await check("/dashboard", 200, "Overview");
await check("/dashboard/automations/new", 200, "New automation");
await check("/api/webhooks/instagram?hub.mode=subscribe&hub.verify_token=ci-verify-token&hub.challenge=4242", 200, "4242");
await check("/api/webhooks/instagram?hub.mode=subscribe&hub.verify_token=wrong&hub.challenge=1", 403);
{
  const res = await fetch(BASE + "/api/webhooks/instagram", { method: "POST", body: "{}", headers: { "x-hub-signature-256": "sha256=bad" } });
  results.push(`${res.status === 401 ? "PASS" : "FAIL"} POST webhook with bad signature -> ${res.status}`);
}
await check("/does-not-exist", 404);

const browser = await chromium.launch();
const shots = [
  ["home-desktop", "/", { width: 1440, height: 900 }, true],
  ["home-mobile", "/", { width: 390, height: 844 }, true],
  ["pricing", "/pricing", { width: 1440, height: 900 }, true],
  ["guide", "/guides/instagram-comment-to-dm", { width: 1440, height: 900 }, false],
  ["compare", "/compare/manychat", { width: 1440, height: 900 }, false],
  ["login", "/login?mode=signup", { width: 1440, height: 900 }, false],
  ["dashboard", "/dashboard", { width: 1440, height: 900 }, true],
  ["dashboard-mobile", "/dashboard", { width: 390, height: 844 }, false],
  ["automations", "/dashboard/automations", { width: 1440, height: 900 }, false],
  ["new-automation", "/dashboard/automations/new", { width: 1440, height: 900 }, true],
  ["settings", "/dashboard/settings", { width: 1440, height: 900 }, false],
];
const consoleErrors = [];
for (const [name, path, viewport, full] of shots) {
  const page = await browser.newPage({ viewport });
  page.on("console", (m) => m.type() === "error" && consoleErrors.push(`${path}: ${m.text()}`));
  page.on("pageerror", (e) => consoleErrors.push(`${path}: ${e.message}`));
  await page.goto(BASE + path, { waitUntil: "networkidle" });
  await page.waitForTimeout(name.startsWith("home") ? 6000 : 800);
  await page.screenshot({ path: `ci-out/${name}.png`, fullPage: full });
  await page.close();
}
await browser.close();

console.log(results.join("\n"));
console.log("\nBrowser console errors:\n" + (consoleErrors.join("\n") || "none"));
