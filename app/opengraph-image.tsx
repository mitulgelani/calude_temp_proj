import { ImageResponse } from "next/og";

export const alt = "Hookline — auto-DM everyone who comments on your Reels";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

export default function OpengraphImage() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
          background: "#F1F0F7",
          padding: 72,
          color: "#16132B",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 18, fontSize: 40, fontWeight: 700 }}>
          <div style={{ width: 56, height: 56, borderRadius: 16, background: "#16132B", display: "flex" }} />
          Hookline
        </div>
        <div style={{ display: "flex", fontSize: 84, fontWeight: 800, lineHeight: 1, letterSpacing: -3, maxWidth: 980 }}>
          Auto-DM everyone who comments on your Reels.
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 20, fontSize: 30 }}>
          <div style={{ display: "flex", background: "#FFE14D", padding: "10px 22px", borderRadius: 999, fontWeight: 700 }}>
            comment LINK
          </div>
          <div style={{ display: "flex", color: "#6C6884" }}>then</div>
          <div
            style={{
              display: "flex",
              background: "linear-gradient(135deg, #5B32FF, #B13CFF)",
              color: "#fff",
              padding: "14px 26px",
              borderRadius: 28,
            }}
          >
            Here&apos;s your link
          </div>
        </div>
      </div>
    ),
    size,
  );
}
