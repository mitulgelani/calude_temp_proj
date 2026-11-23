"""Loads real pages in a phone-sized Chrome with Pluck's page script and reports what it captured."""
import asyncio, json, os, re, sys
from playwright.async_api import async_playwright

JS = open(os.path.join(os.path.dirname(__file__), "..", "assets", "pluck_page.js")).read()
UA = "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36"
PAGES = [
    "https://www.instagram.com/reel/Df172vGP3bh/",
    "https://www.instagram.com/reel/DgA8hYVMZ2-/",
    "https://www.instagram.com/reels/",
    "https://www.tiktok.com/@scout2015/video/6718335390845095173",
    "https://m.facebook.com/watch/",
]

async def main():
    async with async_playwright() as p:
        b = await p.chromium.launch()
        ctx = await b.new_context(user_agent=UA, viewport={"width": 412, "height": 915}, is_mobile=True, has_touch=True, locale="en-US")
        await ctx.add_init_script("window.Pluck={postMessage:function(m){window.__last=m;}};" + JS)
        for url in PAGES:
            pg = await ctx.new_page()
            hits = []
            async def on_resp(r):
                try:
                    if any(k in r.url for k in ("graphql", "/api/", "query")):
                        t = await r.text()
                        hits.append((r.status, r.url[:90], len(t), ["video_versions" in t, "video_url" in t, "display_url" in t, "image_versions2" in t, "dash" in t]))
                except Exception:
                    pass
            pg.on("response", on_resp)
            try:
                await pg.goto(url, wait_until="domcontentloaded", timeout=45000)
                await pg.wait_for_timeout(12000)
                last = await pg.evaluate("window.__last || null")
                store = await pg.evaluate("JSON.stringify(window.__pluckMedia||{})")
                store = json.loads(store)
                nags = await pg.evaluate("""Array.from(document.querySelectorAll('a,button,div[role=button]')).filter(b=>/open app|open instagram|use the app/i.test(b.innerText||'') && b.offsetParent!==null).length""")
                print(f"\n== {url}\n   final url: {pg.url}\n   title: {await pg.title()!r}")
                print(f"   captured keys: {list(store)[:12]} (total {len(store)})")
                m = re.search(r"/(?:reel|p)/([A-Za-z0-9_-]+)", url)
                if m:
                    node = store.get(m.group(1))
                    print(f"   this post captured: {bool(node)}", json.dumps(node)[:300] if node else "")
                print(f"   scan msg: {(last or '')[:300]}")
                print(f"   visible open-app nags: {nags}")
                body = await pg.evaluate("(document.body.innerText||'').slice(0,300).replace(/\\n/g,' / ')")
                print(f"   body: {body!r}  continued={await pg.evaluate('window.__plContinued||0')}")
                html = await pg.content()
                print(f"   html has: video_versions={html.count('video_versions')} video_url={html.count('video_url')} display_url={html.count('display_url')} image_versions2={html.count('image_versions2')} xdt_api={html.count('xdt_api__v1__media__shortcode__web_info')} len={len(html)}")
                for h in hits[:12]:
                    print("   net:", h)
                await pg.screenshot(path=f"shot_{PAGES.index(url)}.png")
            except Exception as e:
                print(f"\n== {url}\n   ERROR {type(e).__name__}: {str(e)[:200]}")
            await pg.close()
        await b.close()

asyncio.run(main())
