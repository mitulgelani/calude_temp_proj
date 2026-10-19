import type { MetadataRoute } from "next";
import { COMPARE_PAGES, GUIDES } from "@/lib/content";
import { LAST_UPDATED, absoluteUrl } from "@/lib/site";

export default function sitemap(): MetadataRoute.Sitemap {
  const lastModified = new Date(LAST_UPDATED);
  return [
    { url: absoluteUrl("/"), lastModified, changeFrequency: "weekly", priority: 1 },
    { url: absoluteUrl("/pricing"), lastModified, changeFrequency: "monthly", priority: 0.9 },
    ...GUIDES.map((g) => ({
      url: absoluteUrl(`/guides/${g.slug}`),
      lastModified,
      changeFrequency: "monthly" as const,
      priority: 0.8,
    })),
    ...COMPARE_PAGES.map((c) => ({
      url: absoluteUrl(`/compare/${c.slug}`),
      lastModified,
      changeFrequency: "monthly" as const,
      priority: 0.7,
    })),
    { url: absoluteUrl("/privacy"), lastModified, changeFrequency: "yearly", priority: 0.2 },
    { url: absoluteUrl("/terms"), lastModified, changeFrequency: "yearly", priority: 0.2 },
    { url: absoluteUrl("/data-deletion"), lastModified, changeFrequency: "yearly", priority: 0.2 },
  ];
}
