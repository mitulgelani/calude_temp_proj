"""
Pluck on-device engine.

Runs inside the Android app through Chaquopy (open-source, free). Uses yt-dlp and instaloader,
both open-source. No servers, no API keys, nothing paid. All functions return JSON strings
with either a result or {"error": "..."} so the Kotlin side never has to parse Python tracebacks.
"""
import json
import os
import re
import sys
import threading
import time
import urllib.request

_FILES = None
_cancelled = set()
_lock = threading.Lock()

UA = ("Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36")

IG_RESERVED = {"p", "reel", "reels", "stories", "explore", "tv", "accounts", "direct", "about", "developer", "legal"}
IG_PROFILE = re.compile(r"^https?://(?:www\.|m\.)?instagram\.com/([A-Za-z0-9._]{1,30})/?(?:\?.*)?$", re.I)
IG_SHORTCODE = re.compile(r"instagram\.com/(?:[A-Za-z0-9._]+/)?(?:p|reel|reels|tv)/([A-Za-z0-9_-]+)", re.I)


class PluckError(Exception):
    pass


# ── setup ────────────────────────────────────────────────────────────────────
def init(files_dir):
    """Called once from Kotlin. A newer yt-dlp downloaded via update_engine() takes priority."""
    global _FILES
    _FILES = files_dir
    z = os.path.join(files_dir, "yt-dlp.zip")
    if os.path.exists(z) and z not in sys.path:
        sys.path.insert(0, z)
    try:
        import certifi
        os.environ.setdefault("SSL_CERT_FILE", certifi.where())
    except Exception:
        pass
    return "ok"


def version():
    try:
        from yt_dlp.version import __version__
        return __version__
    except Exception:
        return "unknown"


def cancel(job_id):
    with _lock:
        _cancelled.add(job_id)


def _is_cancelled(job_id):
    with _lock:
        return job_id in _cancelled


def _cookiefile():
    if _FILES:
        p = os.path.join(_FILES, "cookies.txt")
        if os.path.exists(p):
            return p
    return None


def _ydl_opts(**extra):
    opts = {
        "quiet": True,
        "no_warnings": True,
        "noprogress": True,
        "socket_timeout": 20,
        "retries": 3,
        "http_headers": {"User-Agent": UA},
        "cachedir": os.path.join(_FILES, "ytdlp-cache") if _FILES else False,
    }
    c = _cookiefile()
    if c:
        opts["cookiefile"] = c
    opts.update(extra)
    return opts


# ── detection ────────────────────────────────────────────────────────────────
def detect(url):
    host = re.sub(r"^https?://", "", url.lower()).split("/")[0]
    def on(*hosts):
        return any(host == h or host.endswith("." + h) for h in hosts)
    if on("instagram.com", "instagr.am", "ig.me"):
        return "instagram"
    if on("youtube.com", "youtu.be", "youtube-nocookie.com"):
        return "youtube"
    if on("tiktok.com"):
        return "tiktok"
    if on("facebook.com", "fb.watch", "fb.com"):
        return "facebook"
    if on("pinterest.com", "pin.it") or "pinterest." in host:
        return "pinterest"
    if on("x.com", "twitter.com"):
        return "twitter"
    if on("vimeo.com"):
        return "vimeo"
    if on("dailymotion.com", "dai.ly"):
        return "dailymotion"
    return None


def kind_label(url, src):
    u = url.lower()
    if src == "instagram":
        if "/stories/" in u:
            return "Story"
        if "/reel" in u:
            return "Reel"
        if "/p/" in u:
            return "Post"
        return "Profile photo" if IG_PROFILE.match(url) else "Video"
    if src == "youtube":
        return "Short" if "/shorts/" in u else "Video"
    if src == "facebook":
        return "Reel" if "/reel" in u else "Video"
    if src == "pinterest":
        return "Pin"
    if src == "tiktok":
        return "Photo post" if "/photo/" in u else "Video"
    return "Media"


# ── format picking (pure functions, unit-tested) ─────────────────────────────
def _has_video(f):
    v = f.get("vcodec")
    return v != "none"


def _has_audio(f):
    a = f.get("acodec")
    return a != "none"


def _is_http(f):
    return (f.get("protocol") or "https").split("+")[0] in ("http", "https")


def _size(f):
    return f.get("filesize") or f.get("filesize_approx")


def _rank(f):
    return (f.get("height") or 0, 1 if f.get("ext") == "mp4" else 0, f.get("tbr") or 0, _size(f) or 0)


def pick_items(info, src):
    """Turn a yt-dlp info dict into at most 4 video qualities + 1 audio option."""
    fmts = list(info.get("formats") or [])
    if not fmts and info.get("url"):
        fmts = [info]

    if src == "tiktok":
        clean = [f for f in fmts if "watermark" not in (f.get("format_note") or "").lower()]
        if any(_has_video(f) for f in clean):
            fmts = clean

    progressive = [f for f in fmts if _has_video(f) and _has_audio(f) and _is_http(f)]
    video_only = [f for f in fmts if _has_video(f) and not _has_audio(f) and _is_http(f)
                  and str(f.get("vcodec") or "").startswith("avc1") and f.get("ext") == "mp4"
                  and (f.get("height") or 0) <= 1080]
    audio_only = [f for f in fmts if _has_audio(f) and not _has_video(f) and _is_http(f)]
    aac = [f for f in audio_only if f.get("ext") == "m4a" or str(f.get("acodec") or "").startswith("mp4a")]
    best_aac = max(aac, key=lambda f: f.get("abr") or f.get("tbr") or 0) if aac else None
    best_audio = best_aac or (max(audio_only, key=lambda f: f.get("abr") or f.get("tbr") or 0) if audio_only else None)

    by_height = {}
    for f in progressive:
        h = f.get("height") or 0
        if h not in by_height or _rank(f) > _rank(by_height[h]["f"]):
            by_height[h] = {"f": f, "spec": {"mode": "ytdlp", "format": f["format_id"]}, "bytes": _size(f)}
    top_prog = max(by_height) if by_height else 0
    if best_aac:
        for f in video_only:
            h = f.get("height") or 0
            if h <= top_prog:
                continue
            if h not in by_height or (by_height[h]["spec"]["mode"] == "mux" and _rank(f) > _rank(by_height[h]["f"])):
                b = (_size(f) or 0) + (_size(best_aac) or 0)
                by_height[h] = {"f": f, "spec": {"mode": "mux", "video": f["format_id"], "audio": best_aac["format_id"]}, "bytes": b or None}

    if not by_height:  # last resort: anything with picture + sound, any protocol (HLS etc.)
        for f in fmts:
            if _has_video(f) and _has_audio(f) and f.get("format_id"):
                h = f.get("height") or 0
                if h not in by_height or _rank(f) > _rank(by_height[h]["f"]):
                    by_height[h] = {"f": f, "spec": {"mode": "ytdlp", "format": f["format_id"]}, "bytes": _size(f)}

    items = []
    for h in sorted(by_height, reverse=True)[:4]:
        e = by_height[h]
        q = min(h, e["f"].get("width") or h) if h else 0  # 576x1024 vertical video is "576p", like YouTube labels it
        detail = []
        if src == "tiktok":
            detail.append("No watermark")
        elif q >= 720:
            detail.append("HD")
        items.append({
            "id": "v%d" % h,
            "kind": "video",
            "label": "%dp" % q if q else "Original",
            "ext": "mp4",
            "bytes": e["bytes"],
            "detail": " · ".join(detail) or None,
            "spec": e["spec"],
        })

    if best_audio and (items or src in ("youtube", "tiktok")):
        items.append({
            "id": "a",
            "kind": "audio",
            "label": "Audio",
            "ext": "m4a" if best_audio is best_aac else (best_audio.get("ext") or "m4a"),
            "bytes": _size(best_audio),
            "detail": "%d kbps" % best_audio["abr"] if best_audio.get("abr") else None,
            "spec": {"mode": "ytdlp", "format": best_audio["format_id"], "audio_only": True},
        })

    if not items:  # photo-only pins / posts
        img = _best_image(info)
        if img:
            items.append({"id": "i1", "kind": "image", "label": "Photo", "ext": _img_ext(img), "bytes": None,
                          "thumb": img, "spec": {"mode": "direct", "url": img, "ext": _img_ext(img)}})
    return items


def _best_image(info):
    thumbs = info.get("thumbnails") or []
    if thumbs:
        best = max(thumbs, key=lambda t: ((t.get("width") or 0) * (t.get("height") or 0), t.get("preference") or 0))
        return best.get("url")
    return info.get("thumbnail")


def _img_ext(url):
    m = re.search(r"\.(jpe?g|png|webp|heic)(?:\?|$)", url or "", re.I)
    return (m.group(1).lower().replace("jpeg", "jpg")) if m else "jpg"


def _title(info, src):
    t = (info.get("title") or "").strip()
    d = (info.get("description") or "").strip()
    if src in ("instagram", "tiktok", "facebook") and (not t or t.lower().startswith(("video by", "post by", "reel by")) or t.isdigit()):
        t = d.split("\n")[0] if d else t
    t = re.sub(r"\s+", " ", t)
    return (t[:88] + "…") if len(t) > 90 else t


def _author(info):
    uid = info.get("uploader_id") or info.get("channel_id")
    name = info.get("uploader") or info.get("channel") or info.get("creator")
    if name:
        return name
    if uid and not str(uid).isdigit():
        return "@" + str(uid).lstrip("@")
    return None


def build_info(info, url, src):
    entries = [e for e in (info.get("entries") or []) if e]
    if entries:  # carousel / multi-item post
        items = []
        for n, e in enumerate(entries[:30], 1):
            sub = pick_items(e, src)
            vids = [i for i in sub if i["kind"] == "video"]
            best = vids[0] if vids else (sub[0] if sub else None)
            if not best:
                continue
            best = dict(best)
            best["id"] = "e%d" % n
            best["label"] = ("Video %d" if best["kind"] == "video" else "Photo %d") % n
            best["thumb"] = best.get("thumb") or e.get("thumbnail")
            if best["spec"].get("mode") != "direct":
                best["spec"] = dict(best["spec"], playlist_item=n)
            items.append(best)
        head = entries[0]
        merged = dict(info)
        merged.setdefault("thumbnail", head.get("thumbnail"))
        for k in ("uploader", "uploader_id", "width", "height", "duration"):
            merged.setdefault(k, head.get(k))
        info = merged
    else:
        items = pick_items(info, src)
        for it in items:
            it.setdefault("thumb", info.get("thumbnail"))

    w, h = info.get("width") or 0, info.get("height") or 0
    return {
        "source": src,
        "kind_label": kind_label(url, src),
        "title": _title(info, src),
        "author": _author(info),
        "thumbnail": info.get("thumbnail") or _best_image(info),
        "duration": info.get("duration"),
        "vertical": bool(h and w and h > w) or src in ("tiktok",) or "/shorts/" in url or "/reel" in url,
        "items": items,
    }


# ── Instagram extras (instaloader: posts with photos, profile photos) ────────
def _netscape_cookies(path):
    jar = {}
    try:
        with open(path) as fh:
            for line in fh:
                if line.startswith("#") or not line.strip():
                    continue
                parts = line.rstrip("\n").split("\t")
                if len(parts) == 7 and "instagram" in parts[0]:
                    jar[parts[5]] = parts[6]
    except OSError:
        pass
    return jar


def _loader():
    import instaloader
    L = instaloader.Instaloader(quiet=True, download_pictures=False, download_videos=False,
                                download_video_thumbnails=False, save_metadata=False,
                                max_connection_attempts=1, user_agent=UA)
    c = _cookiefile()
    if c:
        jar = _netscape_cookies(c)
        if jar.get("sessionid"):
            L.context._session.cookies.update(jar)
            L.context.username = jar.get("ds_user_id") or "pluck"
            L.context._session.headers.update({"X-CSRFToken": jar.get("csrftoken", "")})
    return L


def ig_profile(username):
    import instaloader
    p = instaloader.Profile.from_username(_loader().context, username)
    pic = p.profile_pic_url
    return {
        "source": "instagram", "kind_label": "Profile photo", "title": "@" + p.username,
        "author": p.full_name or None, "thumbnail": pic, "duration": None, "vertical": False,
        "items": [{"id": "dp", "kind": "image", "label": "Full-size photo", "ext": "jpg", "bytes": None,
                   "thumb": pic, "spec": {"mode": "direct", "url": pic, "ext": "jpg"}}],
    }


def ig_post(shortcode, url):
    import instaloader
    post = instaloader.Post.from_shortcode(_loader().context, shortcode)
    nodes = []
    if post.typename == "GraphSidecar":
        for n in post.get_sidecar_nodes():
            nodes.append((n.is_video, n.video_url if n.is_video else n.display_url, n.display_url))
    else:
        nodes.append((post.is_video, post.video_url if post.is_video else post.url, post.url))
    items = []
    for i, (is_video, media, thumb) in enumerate(nodes, 1):
        ext = "mp4" if is_video else _img_ext(media)
        items.append({
            "id": "n%d" % i, "kind": "video" if is_video else "image",
            "label": ("Video %d" if is_video else "Photo %d") % i if len(nodes) > 1 else ("Video" if is_video else "Photo"),
            "ext": ext, "bytes": None, "thumb": thumb, "spec": {"mode": "direct", "url": media, "ext": ext},
        })
    caption = (post.caption or "").split("\n")[0].strip()
    return {
        "source": "instagram", "kind_label": kind_label(url, "instagram"),
        "title": (caption[:88] + "…") if len(caption) > 90 else (caption or "Post by @" + post.owner_username),
        "author": "@" + post.owner_username, "thumbnail": nodes[0][2] if nodes else None,
        "duration": post.video_duration if post.is_video else None, "vertical": False, "items": items,
    }


def ig_embed(shortcode, url):
    """Login-free: Instagram's public embed page carries the media URLs for public posts and reels."""
    page = "https://www.instagram.com/p/%s/embed/captioned/" % shortcode
    req = urllib.request.Request(page, headers={"User-Agent": UA, "Accept-Language": "en"})
    raw = urllib.request.urlopen(req, timeout=20).read(3_000_000).decode("utf-8", "ignore")
    t = raw
    for _ in range(4):
        t = t.replace("\\\\", "\\").replace('\\"', '"').replace("\\/", "/")
    t = t.replace("\\u0026", "&").replace("&amp;", "&")
    videos = list(dict.fromkeys(re.findall(r'"video_url"\s*:\s*"(https[^"]+)"', t)))
    images = list(dict.fromkeys(re.findall(r'"display_url"\s*:\s*"(https[^"]+)"', t)))
    if not images:
        m = re.search(r'class="EmbeddedMediaImage"[^>]*src="([^"]+)"', t)
        if m:
            images = [m.group(1)]
    owner = re.search(r'"username"\s*:\s*"([A-Za-z0-9._]+)"', t)
    items = []
    for i, v in enumerate(videos, 1):
        items.append({"id": "ev%d" % i, "kind": "video", "label": "Video %d" % i if len(videos) > 1 else "Original",
                      "ext": "mp4", "bytes": None, "thumb": images[i - 1] if i - 1 < len(images) else None,
                      "spec": {"mode": "direct", "url": v, "ext": "mp4"}})
    if not videos:
        for i, im in enumerate(images[:20], 1):
            items.append({"id": "ei%d" % i, "kind": "image", "label": "Photo %d" % i if len(images) > 1 else "Photo",
                          "ext": _img_ext(im), "bytes": None, "thumb": im,
                          "spec": {"mode": "direct", "url": im, "ext": _img_ext(im)}})
    if not items:
        raise PluckError("Nothing public found in that post.")
    return {"source": "instagram", "kind_label": kind_label(url, "instagram"),
            "title": ("Post by @" + owner.group(1)) if owner else "Instagram " + kind_label(url, "instagram"),
            "author": ("@" + owner.group(1)) if owner else None, "thumbnail": images[0] if images else None,
            "duration": None, "vertical": "/reel" in url.lower(), "items": items}


def og_fallback(url, src):
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept-Language": "en"})
    html = urllib.request.urlopen(req, timeout=20).read(2_000_000).decode("utf-8", "ignore")
    def meta(prop):
        m = re.search(r'<meta[^>]+(?:property|name)=["\']%s["\'][^>]+content=["\']([^"\']+)' % re.escape(prop), html, re.I) \
            or re.search(r'<meta[^>]+content=["\']([^"\']+)["\'][^>]+(?:property|name)=["\']%s["\']' % re.escape(prop), html, re.I)
        return m.group(1).replace("&amp;", "&") if m else None
    video = meta("og:video:secure_url") or meta("og:video")
    image = meta("og:image")
    title = meta("og:title") or ""
    items = []
    if video:
        items.append({"id": "v", "kind": "video", "label": "Original", "ext": "mp4", "bytes": None, "thumb": image,
                      "spec": {"mode": "direct", "url": video, "ext": "mp4"}})
    if image:
        items.append({"id": "i", "kind": "image", "label": "Photo", "ext": _img_ext(image), "bytes": None, "thumb": image,
                      "spec": {"mode": "direct", "url": image, "ext": _img_ext(image)}})
    if not items:
        raise PluckError("Nothing downloadable found in that link.")
    return {"source": src, "kind_label": kind_label(url, src), "title": title[:90], "author": None,
            "thumbnail": image, "duration": None, "vertical": False, "items": items}


def friendly(err, src):
    m = str(err).lower()
    if "cancel" in m:
        return "Cancelled."
    if src == "instagram" and any(k in m for k in ("rate-limit", "429", "checkpoint", "please wait")):
        return "Instagram is slowing requests down right now. Wait a minute and try again."
    if "private" in m or "login" in m:
        return "This one is private or needs a login. Open it in Pluck’s browser while logged in and tap download."
    if "unsupported url" in m:
        return "That link doesn’t point to a video, photo or post."
    if "404" in m or "not found" in m or "unavailable" in m or "removed" in m:
        return "That post was deleted, made private or isn’t available in your country."
    if "429" in m or "too many" in m:
        return "The site is slowing us down. Wait a minute and try again."
    if any(k in m for k in ("timed out", "getaddrinfo", "network", "connection", "resolve host")):
        return "No internet, or the site is slow right now. Try again."
    return "Couldn’t read that link. If it keeps happening, update the engine in Settings."


# ── public: resolve ──────────────────────────────────────────────────────────
def resolve(url):
    src = detect(url)
    if not src:
        return json.dumps({"error": "That link isn’t from a supported app."})
    try:
        return json.dumps(_resolve(url, src))
    except PluckError as e:
        return json.dumps({"error": str(e)})
    except Exception as e:
        return json.dumps({"error": friendly(e, src)})


def _resolve(url, src):
    if src == "instagram":
        if "/stories/" in url.lower() and not _cookiefile():  # Instagram never serves stories anonymously
            raise PluckError("Instagram only shows stories to logged-in accounts. Open Instagram in Pluck’s browser, "
                             "log in there once, then tap download on the story.")
        m = IG_PROFILE.match(url)
        if m and m.group(1).lower() not in IG_RESERVED:
            return ig_profile(m.group(1))
        sc = IG_SHORTCODE.search(url)
        if sc and "/p/" in url.lower():  # posts may be photo-only: instaloader handles photos + carousels
            try:
                return ig_post(sc.group(1), url)
            except Exception:
                pass
    first_error = None
    try:
        import yt_dlp
        with yt_dlp.YoutubeDL(_ydl_opts(skip_download=True)) as y:
            info = y.extract_info(url, download=False)
        out = build_info(info, url, src)
        if out["items"]:
            return out
    except Exception as e:  # noqa: BLE001 — every failure gets a fallback before giving up
        first_error = e
    if src == "instagram":
        sc = IG_SHORTCODE.search(url)
        if sc:
            for fn in (ig_post, ig_embed):
                try:
                    return fn(sc.group(1), url)
                except Exception:
                    pass
    if src in ("pinterest", "facebook", "instagram"):
        try:
            return og_fallback(url, src)
        except Exception:
            pass
    raise PluckError(friendly(first_error or "nothing found", src))


# ── public: download ─────────────────────────────────────────────────────────
def download(url, spec_json, out_dir, base_name, job_id, sink):
    """sink is a Kotlin object with update(done: Long, total: Long). Returns JSON."""
    spec = json.loads(spec_json)
    src = detect(url) or "media"
    try:
        mode = spec.get("mode")
        if mode == "direct":
            return json.dumps({"path": _direct(spec["url"], out_dir, base_name, spec.get("ext") or "bin", job_id, sink)})
        if mode == "mux":
            v = _ytdlp_download(url, spec["video"], spec.get("playlist_item"), out_dir, base_name + ".v", job_id, sink, (0.0, 0.85),
                                "bestvideo[vcodec^=avc1][ext=mp4]")
            a = _ytdlp_download(url, spec["audio"], spec.get("playlist_item"), out_dir, base_name + ".a", job_id, sink, (0.85, 1.0),
                                "bestaudio[ext=m4a]/bestaudio")
            return json.dumps({"mux": True, "video": v, "audio": a, "out": os.path.join(out_dir, base_name + ".mp4")})
        fallback = "bestaudio[ext=m4a]/bestaudio" if spec.get("audio_only") else "best[vcodec!=none][acodec!=none]/best"
        path = _ytdlp_download(url, spec["format"], spec.get("playlist_item"), out_dir, base_name, job_id, sink, (0.0, 1.0), fallback)
        return json.dumps({"path": path})
    except Exception as e:
        return json.dumps({"error": friendly(e, src)})
    finally:
        with _lock:
            _cancelled.discard(job_id)


def _report(sink, frac):
    try:
        sink.update(int(max(0.0, min(1.0, frac)) * 1000), 1000)
    except Exception:
        pass


def _ytdlp_download(url, fmt, playlist_item, out_dir, base, job_id, sink, span, fallback):
    import yt_dlp
    lo, hi = span
    last = [0.0]

    def hook(d):
        if _is_cancelled(job_id):
            raise PluckError("Cancelled")
        if d.get("status") == "downloading":
            total = d.get("total_bytes") or d.get("total_bytes_estimate") or 0
            if total:
                frac = lo + (hi - lo) * (d.get("downloaded_bytes", 0) / total)
                now = time.time()
                if now - last[0] > 0.12:
                    last[0] = now
                    _report(sink, frac)

    opts = _ydl_opts(
        format="%s/%s" % (fmt, fallback),
        outtmpl=os.path.join(out_dir, base + ".%(ext)s"),
        progress_hooks=[hook],
        overwrites=True,
        concurrent_fragment_downloads=4,
        http_chunk_size=10 * 1024 * 1024,
    )
    if playlist_item:
        opts["playlist_items"] = str(playlist_item)
    else:
        opts["noplaylist"] = True
    with yt_dlp.YoutubeDL(opts) as y:
        y.extract_info(url, download=True)
    if _is_cancelled(job_id):
        raise PluckError("Cancelled")
    found = [f for f in os.listdir(out_dir) if f.startswith(base + ".") and not f.endswith((".part", ".ytdl", ".temp"))]
    if not found:
        raise PluckError("Download finished but the file is missing.")
    found.sort(key=lambda f: os.path.getmtime(os.path.join(out_dir, f)), reverse=True)
    _report(sink, hi)
    return os.path.join(out_dir, found[0])


def _direct(media_url, out_dir, base, ext, job_id, sink):
    path = os.path.join(out_dir, "%s.%s" % (base, ext))
    req = urllib.request.Request(media_url, headers={"User-Agent": UA, "Referer": "https://www.instagram.com/"})
    with urllib.request.urlopen(req, timeout=30) as r, open(path + ".part", "wb") as out:
        total = int(r.headers.get("Content-Length") or 0)
        done, last = 0, 0.0
        while True:
            if _is_cancelled(job_id):
                raise PluckError("Cancelled")
            chunk = r.read(256 * 1024)
            if not chunk:
                break
            out.write(chunk)
            done += len(chunk)
            if total and time.time() - last > 0.12:
                last = time.time()
                _report(sink, done / total)
    os.replace(path + ".part", path)
    _report(sink, 1.0)
    return path
