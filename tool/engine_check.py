"""Runs the on-device engine against real public links (used by the engine-test workflow)."""
import json, os, sys, tempfile, time, traceback
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "android", "app", "src", "main", "python"))
import pluck_engine as E

URLS = [
    "https://www.instagram.com/reel/Df172vGP3bh/",
    "https://www.instagram.com/p/C9wOqXyy0r6/",
    "https://www.instagram.com/natgeo/",
    "https://www.youtube.com/watch?v=jNQXAC9IVRw",
    "https://vimeo.com/76979871",
    "https://www.tiktok.com/@scout2015/video/6718335390845095173",
    "https://www.pinterest.com/pin/1055599747036549/",
    "https://x.com/NASA/status/1824481470357168303",
]
E.init(tempfile.mkdtemp())
print("yt-dlp", E.version())
for fn in ("ig_graphql", "ig_embed", "ig_post"):
    print("has", fn, hasattr(E, fn))
for u in URLS:
    t = time.time()
    r = json.loads(E.resolve(u))
    dt = time.time() - t
    if "error" in r:
        print(f"FAIL {dt:4.1f}s {u}\n     {r['error']}\n     detail: {r.get('detail','')[:400]}")
    else:
        print(f"OK   {dt:4.1f}s {u}  via={r.get('via')} title={r['title'][:40]!r} items={[ (i['kind'], i['label']) for i in r['items']]}")
# direct sub-extractors for Instagram, to see which path works from this network
sc = "Df172vGP3bh"
for name in ("ig_graphql", "ig_embed", "ig_post"):
    fn = getattr(E, name, None)
    if not fn: continue
    try:
        r = fn(sc, "https://www.instagram.com/reel/%s/" % sc)
        print(f"{name}: OK items={[(i['kind'], i['spec'].get('url','')[:60]) for i in r['items']]}")
    except Exception as e:
        print(f"{name}: FAIL {type(e).__name__}: {str(e)[:300]}")
