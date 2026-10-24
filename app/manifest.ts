import type { MetadataRoute } from "next";

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "LinkPlz",
    short_name: "LinkPlz",
    description: "Instagram comment-to-DM automation for creators.",
    start_url: "/dashboard",
    display: "standalone",
    background_color: "#F1F0F7",
    theme_color: "#16132B",
    icons: [{ src: "/icon.svg", sizes: "any", type: "image/svg+xml" }],
  };
}
