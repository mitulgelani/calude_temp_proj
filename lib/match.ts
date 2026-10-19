export type MatchMode = "contains" | "exact" | "any";

function clean(s: string): string {
  return s
    .normalize("NFKD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase()
    .replace(/[^\p{L}\p{N}\s]/gu, " ")
    .replace(/\s+/g, " ")
    .trim();
}

/** Does a comment or DM trigger this automation? Case, accents, emoji and punctuation are ignored. */
export function matchesKeywords(text: string, mode: MatchMode, keywords: string[]): boolean {
  if (mode === "any") return true;
  const t = clean(text);
  if (!t) return false;
  return keywords.some((k) => {
    const kw = clean(k);
    if (!kw) return false;
    if (mode === "exact") return t === kw;
    return ` ${t} `.includes(` ${kw} `);
  });
}

export function parseKeywords(input: string): string[] {
  return Array.from(
    new Set(
      input
        .split(/[,\n]/)
        .map((k) => k.trim())
        .filter(Boolean)
        .slice(0, 20),
    ),
  );
}

export function fillTemplate(template: string, vars: { username?: string }): string {
  return template.replace(/\{username\}/g, vars.username ? `@${vars.username}` : "").replace(/\s{2,}/g, " ").trim();
}
