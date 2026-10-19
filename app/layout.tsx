import type { Metadata, Viewport } from "next";
import { Bricolage_Grotesque } from "next/font/google";
import type { Organization, WebSite } from "schema-dts";
import type { WithContext } from "schema-dts";
import { JsonLd } from "@/components/JsonLd";
import { SITE_DESCRIPTION, SITE_NAME, SITE_TITLE, SUPPORT_EMAIL, siteUrl } from "@/lib/site";
import "./globals.css";

const bricolage = Bricolage_Grotesque({
  subsets: ["latin"],
  variable: "--font-bricolage",
  display: "swap",
  axes: ["opsz"],
});

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl()),
  title: { default: SITE_TITLE, template: `%s | ${SITE_NAME}` },
  description: SITE_DESCRIPTION,
  applicationName: SITE_NAME,
  keywords: [
    "instagram comment to dm",
    "instagram auto dm",
    "auto dm instagram comments",
    "instagram dm automation",
    "manychat alternative",
    "comment link dm",
    "instagram reels automation",
  ],
  alternates: { canonical: "/" },
  openGraph: {
    type: "website",
    siteName: SITE_NAME,
    title: SITE_TITLE,
    description: SITE_DESCRIPTION,
    url: "/",
    locale: "en_US",
  },
  twitter: { card: "summary_large_image", title: SITE_TITLE, description: SITE_DESCRIPTION },
  robots: { index: true, follow: true, googleBot: { index: true, follow: true, "max-image-preview": "large" } },
  category: "technology",
};

export const viewport: Viewport = {
  themeColor: "#F1F0F7",
  width: "device-width",
  initialScale: 1,
};

const organization: WithContext<Organization> = {
  "@context": "https://schema.org",
  "@type": "Organization",
  name: SITE_NAME,
  url: siteUrl(),
  logo: `${siteUrl()}/icon.svg`,
  email: SUPPORT_EMAIL,
};

const website: WithContext<WebSite> = {
  "@context": "https://schema.org",
  "@type": "WebSite",
  name: SITE_NAME,
  url: siteUrl(),
  description: SITE_DESCRIPTION,
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={bricolage.variable}>
      <body className="min-h-dvh">
        <JsonLd data={[organization, website]} />
        {children}
      </body>
    </html>
  );
}
