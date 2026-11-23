# Pluck — all-in-one downloader (Flutter)

Save Instagram Reels, posts, carousels, stories and profile photos; YouTube videos and Shorts (up to 1080p) and audio; TikTok videos without the watermark; Facebook videos and Reels; Pinterest video and image pins; and WhatsApp / WhatsApp Business statuses.

**100% free, no APIs, no server.** Everything runs on the phone:

| Piece | What it does | Cost |
|---|---|---|
| [yt-dlp](https://github.com/yt-dlp/yt-dlp) (Unlicense) | Reads links and downloads media from all 5 sites | Free |
| [instaloader](https://github.com/instaloader/instaloader) (MIT) | Instagram photo posts, carousels, profile photos | Free |
| [Chaquopy](https://chaquo.com/chaquopy/) (MIT) | Runs that Python code inside the Android app | Free |
| Android `MediaMuxer` | Merges HD video + audio (no ffmpeg needed) | Built into Android |
| Android Storage Access Framework | Reads WhatsApp's status folder | Built into Android |

When a site changes, open **Settings → Download engine → Update**. The app pulls the newest yt-dlp release from GitHub for free; no app update is needed.

---

## Get an APK (no setup on your computer)

1. Create an empty GitHub repo and push this folder to it.
2. Open the **Actions** tab. **Build APK** runs by itself on every push (or click *Run workflow*).
3. After about 10–15 minutes, open **Releases**, download `pluck-N.apk` and install it on your phone.

For a Google Play build, run the workflow with **"Google Play build" ticked**. That hides YouTube, which Play doesn't allow.

## Build locally

Needs Flutter (stable), JDK 17 and **Python 3.12** on PATH.

```bash
python tool/setup.py          # creates the Android scaffolding + adds Chaquopy (run once)
flutter run                   # on a connected Android phone
flutter build apk --release   # build/app/outputs/flutter-apk/app-release.apk
```

If Gradle can't find the Chaquopy plugin version, run `CHAQUOPY_VERSION=17.0.0 python tool/setup.py` again on a fresh clone.

---

## Project map

```
lib/
  core/tokens.dart        all colours, type, spacing, radii, motion (the design system)
  core/sources.dart       the 6 apps, link detection, how-to guides
  core/config.dart        build flags (PLUCK_YOUTUBE)
  data/native_bridge.dart Dart ↔ Kotlin channel
  data/downloader.dart    download → gallery → library
  features/home           "Portal" link card, clipboard detection, share-to-Pluck
  features/result         format picker + liquid progress button
  features/source         per-app screens (Reels / Posts / Stories / Profile photo …)
  features/status         WhatsApp statuses grid + full-screen viewer
  features/library        everything saved, filters, share/delete
  features/settings       gallery toggle, Instagram connect, engine update
android/app/src/main/
  kotlin/.../MainActivity.kt   engine host, HD merge, SAF, cookies, share intent
  python/pluck_engine.py       on-device extraction (yt-dlp + instaloader)
tool/setup.py                  one-time Gradle wiring
.github/workflows/build-apk.yml  free cloud APK builds
```

## Things to know before you ship

- **Google Play:** Play removes apps that download from YouTube. Build with `--dart-define=PLUCK_YOUTUBE=false` for Play. Downloaders for the other platforms also get reported often. Many apps in this category ship as a direct APK, or keep the Play version to WhatsApp statuses only.
- **Instagram stories** need a logged-in session. The user taps *Connect Instagram* once in Settings, and the cookie stays in the app's private storage. Public Reels and posts usually work without logging in. Instagram rate-limits anonymous requests, so heavy users should connect.
- **App size:** bundling Python makes the APK about 35–60 MB. Ship an App Bundle (`flutter build appbundle`) so each phone downloads only its own CPU's files.
- **Android only.** iOS doesn't allow an embedded engine like this or reading WhatsApp's folder.
- **Monograms, not logos.** The app uses "IG / YT / TT" type tiles instead of brand logos. That keeps it clear of trademark takedowns.
