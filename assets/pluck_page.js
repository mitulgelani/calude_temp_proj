// Injected into every page in Pluck's browser.
// 1) Captures media URLs from the site's own data (Instagram embeds full JSON for every post/reel it shows,
//    and loads more through fetch/XHR as you scroll) — so downloads work logged-out, from the phone's own session.
// 2) Hides "Open app" buttons and sign-up walls so the user always stays in the browser.
// 3) Tells Pluck which post/video is on screen so the download button can appear.
(function () {
  if (window.__pluckInstalled) { try { window.__pluckScan && window.__pluckScan(); } catch (e) {} return; }
  window.__pluckInstalled = true;
  var store = (window.__pluckMedia = window.__pluckMedia || {});

  function best(arr) {
    var b = null, bs = -1;
    (arr || []).forEach(function (v) { var s = (v.width || 0) * (v.height || 0); if (s > bs) { bs = s; b = v; } });
    return b;
  }
  function slim(n) {
    if (!n || typeof n !== 'object') return null;
    var vv = best(n.video_versions);
    var cand = n.image_versions2 && n.image_versions2.candidates && n.image_versions2.candidates[0];
    var o = { video_url: n.video_url || (vv && vv.url) || null, display_url: n.display_url || (cand && cand.url) || null };
    var kids = n.carousel_media ||
      (n.edge_sidecar_to_children && n.edge_sidecar_to_children.edges && n.edge_sidecar_to_children.edges.map(function (e) { return e.node; }));
    if (kids && kids.length) o.carousel_media = kids.map(slim).filter(Boolean);
    return (o.video_url || o.display_url || (o.carousel_media && o.carousel_media.length)) ? o : null;
  }
  function caption(n) {
    try { return (n.caption && n.caption.text) || n.edge_media_to_caption.edges[0].node.text || ''; } catch (e) { return ''; }
  }
  function keep(key, s, x) {
    if (!key) return;
    key = String(key);
    var prev = store[key];
    if (prev && (prev.video_url || !s.video_url) && (prev.carousel_media || !s.carousel_media)) return;
    s._title = (caption(x) || '').split('\n')[0].slice(0, 90);
    var u = x.user || x.owner;
    s._owner = u && u.username ? '@' + u.username : null;
    store[key] = s;
  }
  function walk(x, depth) {
    if (!x || typeof x !== 'object' || depth > 60) return;
    if (Array.isArray(x)) { for (var i = 0; i < x.length; i++) walk(x[i], depth + 1); return; }
    if (x.video_versions || x.image_versions2 || x.display_url || x.video_url || x.carousel_media || x.edge_sidecar_to_children) {
      var s = slim(x);
      if (s) { keep(x.code || x.shortcode, s, x); keep(x.pk, s, x); if (typeof x.id === 'string') keep(x.id.split('_')[0], s, x); }
    }
    for (var k in x) {
      if (!Object.prototype.hasOwnProperty.call(x, k)) continue;
      var v = x[k];
      if (v && typeof v === 'object') walk(v, depth + 1);
      else if (typeof v === 'string' && v.length > 200 && v.charAt(0) === '{' && (v.indexOf('video_versions') >= 0 || v.indexOf('image_versions2') >= 0)) {
        try { walk(JSON.parse(v), depth + 1); } catch (e) {}
      }
    }
  }
  function eat(text) {
    if (!text || text.length < 20) return;
    if (text.indexOf('video_versions') < 0 && text.indexOf('display_url') < 0 && text.indexOf('image_versions2') < 0) return;
    text = text.replace(/^for \(;;\);/, '');
    try { walk(JSON.parse(text), 0); return; } catch (e) {}
    text.split('\n').forEach(function (line) { try { walk(JSON.parse(line), 0); } catch (e) {} });
  }
  function scanScripts() {
    document.querySelectorAll('script[type="application/json"],script[type="application/ld+json"]').forEach(function (s) {
      if (!s.__pl) { s.__pl = 1; eat(s.textContent); }
    });
  }

  // Watch the site's own network responses.
  var of = window.fetch;
  if (of) {
    window.fetch = function () {
      return of.apply(this, arguments).then(function (r) {
        try { r.clone().text().then(eat).catch(function () {}); } catch (e) {}
        return r;
      });
    };
  }
  var os = XMLHttpRequest.prototype.send;
  XMLHttpRequest.prototype.send = function () {
    this.addEventListener('load', function () {
      try { if (this.responseType === '' || this.responseType === 'text') eat(this.responseText); } catch (e) {}
    });
    return os.apply(this, arguments);
  };

  // Stay in the browser: hide "open app" prompts and sign-up walls.
  var NAG = /^(open app|open instagram|use the app|get the app|open in app|open tiktok|open the app|switch to the app|continue in app|download the app|open facebook|open youtube|open pinterest|get app|use app)$/i;
  var GO_WEB = /^(continue on web|continue on the web|continue in browser|stay on web|use the web|use web|not now|continue as guest|watch on web)$/i;
  var NAG_TEXT = /^(watch this (reel|post|video) in the app|see this (post|reel) in the app|get the full experience on the app|open in the app.*)$/i;
  function clickText(phrase) {
    try {
      var r = document.evaluate("//*[normalize-space(text())='" + phrase + "']", document, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);
      for (var i = 0; i < r.snapshotLength; i++) {
        var el = r.snapshotItem(i);
        if (el.__plClicked || el.offsetParent === null) continue;
        el.__plClicked = 1;
        var target = el.closest('a,button,[role="button"],[tabindex]') || el;
        ['pointerdown', 'mousedown', 'pointerup', 'mouseup', 'click'].forEach(function (type) {
          target.dispatchEvent(new MouseEvent(type, { bubbles: true, cancelable: true, view: window }));
        });
        window.__plContinued = (window.__plContinued || 0) + 1;
      }
    } catch (e) {}
  }
  function clean() {
    ['Continue on web', 'Continue on the web', 'Not now', 'Continue in browser', 'Stay on web'].forEach(clickText);
    document.querySelectorAll('a,button,div[role="button"],span[role="button"]').forEach(function (b) {
      var t = (b.innerText || '').trim();
      if (t.length >= 40) return;
      if (GO_WEB.test(t) && !b.__plClicked) { b.__plClicked = 1; try { b.click(); } catch (e) {} return; }
      if (NAG.test(t)) b.style.setProperty('display', 'none', 'important');
    });
    document.querySelectorAll('span,div,h2,h3').forEach(function (el) {
      if (el.children.length > 2) return;
      var t = (el.innerText || '').trim();
      if (t.length < 60 && NAG_TEXT.test(t)) el.style.setProperty('display', 'none', 'important');
    });
    if (location.pathname.indexOf('/accounts/') < 0 && location.pathname.indexOf('/login') < 0) {
      document.querySelectorAll('div[role="dialog"]').forEach(function (d) {
        var t = d.innerText || '';
        if (t.length < 700 && /sign up|log in to continue|create an account|see more from|never miss a post|open in the app/i.test(t)) {
          var root = d;
          for (var i = 0; i < 5 && root.parentElement && root.parentElement !== document.body; i++) root = root.parentElement;
          root.style.setProperty('display', 'none', 'important');
          document.documentElement.style.setProperty('overflow', 'auto', 'important');
          document.body.style.setProperty('overflow', 'auto', 'important');
        }
      });
    }
  }

  // What's on screen right now.
  function dist(el) {
    var r = el.getBoundingClientRect();
    if (r.bottom < 0 || r.top > innerHeight || r.width < 40) return 1e9;
    return Math.abs((r.top + r.bottom) / 2 - innerHeight / 2);
  }
  var SEL = 'a[href*="/reel/"],a[href*="/p/"],a[href*="/video/"],a[href*="/status/"],a[href*="/pin/"],a[href*="/shorts/"],a[href*="watch?v="],a[href*="/videos/"]';
  // Instagram's public embed page renders the real media in the DOM (works logged-out for public posts).
  function scanEmbed() {
    var em = location.pathname.match(/\/(?:p|reels?|tv)\/([A-Za-z0-9_-]{5,})\/embed/);
    if (!em) return;
    var vids = [], imgs = [];
    document.querySelectorAll('video').forEach(function (v) { var s = v.currentSrc || v.src; if (s && s.indexOf('http') === 0) vids.push(s); });
    document.querySelectorAll('img').forEach(function (i) { if (i.naturalWidth >= 320) imgs.push(i.currentSrc || i.src); });
    if (!vids.length && !imgs.length) return;
    var prev = store[em[1]];
    if (prev && (prev.video_url || !vids.length)) return;
    store[em[1]] = { video_url: vids[0] || null, display_url: imgs[0] || null, _title: (document.title || '').slice(0, 90), _owner: null };
  }
  function scan() {
    scanScripts();
    scanEmbed();
    clean();
    var bestV = null, bd = 1e9;
    document.querySelectorAll('video').forEach(function (v) { var d = dist(v); if (d < bd) { bd = d; bestV = v; } });
    var post = null;
    if (bestV) {
      var n = bestV;
      for (var i = 0; i < 30 && n && !post; i++) { if (n.querySelector) { var a = n.querySelector(SEL); if (a) post = a.href; } n = n.parentElement; }
    }
    if (!post) {
      var pd = 1e9;
      document.querySelectorAll(SEL).forEach(function (a) { var d = dist(a); if (d < pd) { pd = d; post = a.href; } });
      if (pd > innerHeight * 0.6) post = null;
    }
    var media = null;
    if (bestV) { var s = bestV.currentSrc || bestV.src; if (s && s.indexOf('http') === 0) media = s; }
    var ig = /instagram\.com$/.test(location.hostname);
    // Instagram only loads the real video once it plays: start the one on screen (muted), like a user tap.
    if (ig && bestV && bestV.paused && !bestV.__plPlayed) {
      bestV.__plPlayed = 1;
      try { bestV.muted = true; var pr = bestV.play(); if (pr && pr.catch) pr.catch(function () {}); } catch (e) {}
    }
    // Pair the playing video with the post in the address bar, so a reel never downloads as its thumbnail.
    var pc = location.pathname.match(/\/(?:p|reels?|tv)\/([A-Za-z0-9_-]{5,})/);
    if (ig && pc && media) {
      var cur = store[pc[1]];
      if (!cur || !cur.video_url) store[pc[1]] = { video_url: media, display_url: cur ? cur.display_url : null, _title: cur ? cur._title : '', _owner: cur ? cur._owner : null };
    }
    try { Pluck.postMessage(JSON.stringify({ url: location.href, post: post, media: media, codes: Object.keys(store) })); } catch (e) {}
  }
  window.__pluckScan = scan;
  window.__pluckPlay = function () {
    document.querySelectorAll('video').forEach(function (v) {
      var r = v.getBoundingClientRect();
      if (r.bottom > 0 && r.top < innerHeight) { try { v.muted = true; var p = v.play(); if (p && p.catch) p.catch(function () {}); } catch (e) {} }
    });
    scan();
  };
  window.__pluckGet = function (key) { return JSON.stringify(store[key] || null); };
  window.__pluckCurrent = function (hint) {
    var m = location.pathname.match(/\/(?:reels?|p|tv)\/([A-Za-z0-9_-]{5,})/);
    var k = (hint && store[hint]) ? hint : (m && store[m[1]] ? m[1] : null);
    return JSON.stringify(k ? store[k] : null);
  };
  setInterval(scan, 700);
  document.addEventListener('scroll', function () { clearTimeout(window.__pt); window.__pt = setTimeout(scan, 150); }, true);
  if (document.readyState !== 'loading') scan(); else document.addEventListener('DOMContentLoaded', scan);
})();
