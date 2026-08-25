// ==============================================================
//  YouTube Blur Thumbnails — Vivaldi custom.js mod
//  Blurs all thumbnails so you search with intent, not your eyes.
//  Ported from the Tampermonkey script by local.
//  created with Claude. Account: Milobowler
// ==============================================================

(function () {
  "use strict";

  const DOMAIN = "www.youtube.com";
  var URL_RE = /^https?:\/\/www\.youtube\.com\//;

  function ts() {
    var d = new Date();
    return (
      d.toLocaleTimeString("en-GB") +
      "." +
      String(d.getMilliseconds()).padStart(3, "0")
    );
  }
  function LOG(msg) {
    console.log("YT-BlurThumbs.js: " + msg + " at " + ts());
  }

  // ── Blur CSS ───────────────────────────────────────────────────
  //
  //  Selectors mirror the original Tampermonkey script:
  //    ytd-thumbnail img          — standard video card thumbnails
  //    yt-image img               — newer yt-image component layout
  //    ytd-playlist-thumbnail img — playlist cover art
  //    #thumbnail img             — fallback ID-based selector
  //    ytd-reel-*-renderer img    — Shorts shelf items in search
  //    ytd-playlist-renderer img  — playlist cards in search results
  //    ytd-course-card-renderer img — course cards
  //    img[src*="i.ytimg.com"]    — catch-all CDN domain future-proof
  //    img.cbCustomThumbnailCanvas — DeArrow custom thumbnails
  //                                  (blob: URLs, matched by class)
  //
  //  scale(1.05) prevents the blur kernel from exposing transparent
  //  edges around the thumbnail boundary.
  // ──────────────────────────────────────────────────────────────
  var BLUR_SELECTORS = [
    "ytd-thumbnail img",
    "yt-image img",
    "ytd-playlist-thumbnail img",
    "#thumbnail img",
    "ytd-reel-item-renderer img",
    "ytd-reel-shelf-renderer img",
    "ytd-playlist-renderer img",
    "ytd-course-card-renderer img",
    'img[src*="i.ytimg.com"]',
    "img.cbCustomThumbnailCanvas",
  ];

  var BLUR_CSS =
    BLUR_SELECTORS.join(",\n") +
    " {\n" +
    "  filter: blur(12px) !important;\n" +
    "  transform: scale(1.05) !important;\n" +
    "  will-change: filter;\n" +
    "}";

  // ── CSS injection count tracking ──────────────────────────────
  //
  //  Identical problem to youtubeNU.js: chrome.scripting.insertCSS
  //  STACKS — each call is a separate injection even with identical
  //  CSS. removeCSS only peels off one layer at a time.
  //
  //  Problem: YouTube fires two rapid onHistoryStateUpdated events
  //  on some navigations (e.g. Homepage → Search). The intermediate
  //  event re-injects CSS on top of the onCommitted injection,
  //  creating 2 layers. A single removeCSS call only clears 1,
  //  leaving the blur stuck on.
  //
  //  Fix: track exactly how many times CSS is injected per tab.
  //  On removal, call removeCSS that many times to clear every layer.
  //
  //  Counts are incremented SYNCHRONOUSLY before the async API call
  //  so that a second syncCSS call (a few ms later) sees the correct
  //  total. onCommitted resets the count — new document, clean slate.
  // ──────────────────────────────────────────────────────────────
  var cssCount = new Map(); // tabId → number of active injections

  function getCount(tabId) {
    return cssCount.get(tabId) || 0;
  }
  function incrementCount(tabId) {
    cssCount.set(tabId, getCount(tabId) + 1);
  }
  function decrementCount(tabId) {
    cssCount.set(tabId, Math.max(0, getCount(tabId) - 1));
  }
  function resetCount(tabId) {
    cssCount.set(tabId, 0);
  }

  // ── CSS injection helpers ─────────────────────────────────────
  //
  //  injectCSS   — used on onCommitted (fresh page load).
  //               Resets count first (new document = clean slate),
  //               then injects if the URL is YouTube.
  //
  //  syncCSS     — used on onHistoryStateUpdated (SPA navigation).
  //               Inserts when URL still matches YouTube.
  //               Removes ALL stacked layers when it no longer does.
  // ──────────────────────────────────────────────────────────────
  function injectCSS(tabId, url) {
    if (!chrome.scripting) return;
    if (!URL_RE.test(url)) return;
    resetCount(tabId); // fresh document — prior injections are gone
    incrementCount(tabId); // synchronous, before the async call
    chrome.scripting
      .insertCSS({ target: { tabId: tabId }, css: BLUR_CSS, origin: "USER" })
      .then(function () {
        LOG("CSS injected (full load) — " + url);
      })
      .catch(function (e) {
        decrementCount(tabId); // roll back on failure
        LOG("CSS insert failed: " + e);
      });
  }

  function syncCSS(tabId, url) {
    if (!chrome.scripting) return;
    if (URL_RE.test(url)) {
      // URL is still YouTube — keep blurring.
      incrementCount(tabId); // synchronous, before the async call
      chrome.scripting
        .insertCSS({ target: { tabId: tabId }, css: BLUR_CSS, origin: "USER" })
        .then(function () {
          LOG("CSS pre-injected (SPA) — " + url);
        })
        .catch(function (e) {
          decrementCount(tabId); // roll back on failure
          LOG("CSS insert failed: " + e);
        });
    } else {
      // Navigated away from YouTube — strip every stacked layer.
      var n = getCount(tabId);
      if (n === 0) return; // nothing was injected — nothing to do
      resetCount(tabId); // clear before async removals
      var completed = 0;
      for (var i = 0; i < n; i++) {
        chrome.scripting
          .removeCSS({ target: { tabId: tabId }, css: BLUR_CSS, origin: "USER" })
          .then(function () {
            completed++;
            if (completed === n) {
              LOG("CSS removed (" + n + " layer(s)) — left YouTube: " + url);
            }
          })
          .catch(function () {
            /* layer wasn't present — fine */
          });
      }
    }
  }

  // ── Page-world script ─────────────────────────────────────────
  //
  //  Injected into the page via executeScript (world: MAIN).
  //  Handles thumbnails delivered as inline background-image style
  //  properties — those can't be caught by the CSS selector rules
  //  above (no element selector targets a style attribute value).
  //
  //  YouTube sometimes sets thumbnails as background-image on anchor
  //  or div elements inside ytd-rich-grid-media and similar. This
  //  observer detects and blurs them as they are injected.
  //
  //  Must be entirely self-contained — no references to the outer
  //  IIFE scope, as it runs in the page world, not the extension.
  // ──────────────────────────────────────────────────────────────
  function pageScript() {
    var FLAG = "__ytBlurThumbsActive";
    if (window[FLAG]) return; // guard: skip if already running
    window[FLAG] = true;

    var BLUR_FILTER = "blur(12px)";
    var BLUR_SCALE = "scale(1.05)";

    function blurNode(node) {
      if (!(node instanceof HTMLElement)) return;

      // Blur this node if it carries a background-image inline style.
      if ((node.getAttribute("style") || "").includes("background-image")) {
        node.style.filter = BLUR_FILTER;
        node.style.transform = BLUR_SCALE;
      }

      // Walk all descendants — MutationObserver delivers only the root
      // of a large HTML insertion, not every child within it.
      node.querySelectorAll('[style*="background-image"]').forEach(function (el) {
        el.style.filter = BLUR_FILTER;
        el.style.transform = BLUR_SCALE;
      });
    }

    // Cover any background-image elements already in the DOM at inject time.
    blurNode(document.body);

    // Watch for dynamically injected content: infinite scroll, SPA nav,
    // YouTube's aggressive element recycling.
    new MutationObserver(function (mutations) {
      for (var i = 0; i < mutations.length; i++) {
        for (var j = 0; j < mutations[i].addedNodes.length; j++) {
          blurNode(mutations[i].addedNodes[j]);
        }
      }
    }).observe(document.body, { childList: true, subtree: true });
  }

  function injectJS(tabId, reason) {
    if (!chrome.scripting) return;
    LOG("Injecting page script (" + reason + ")");
    chrome.scripting
      .executeScript({
        target: { tabId: tabId, allFrames: false },
        world: "MAIN",
        func: pageScript,
      })
      .catch(function (e) {
        LOG("JS inject failed: " + e);
      });
  }

  function isYouTube(url) {
    return typeof url === "string" && url.includes(DOMAIN);
  }

  // ── Navigation listeners ──────────────────────────────────────
  function attachListeners() {
    // onCommitted — fires before first paint.
    // Inject blur CSS immediately so thumbnails never appear unblurred.
    if (chrome.webNavigation && chrome.webNavigation.onCommitted) {
      chrome.webNavigation.onCommitted.addListener(function (details) {
        if (details.frameId !== 0) return;
        if (isYouTube(details.url)) {
          LOG("onCommitted — " + details.url);
          injectCSS(details.tabId, details.url);
        }
      });
    }

    // onUpdated (complete) — page is fully loaded.
    // Start the background-image MutationObserver in page world.
    if (chrome.tabs && chrome.tabs.onUpdated) {
      chrome.tabs.onUpdated.addListener(function (tabId, changeInfo, tab) {
        if (changeInfo.status === "complete" && isYouTube(tab.url)) {
          LOG("onUpdated complete — " + tab.url);
          injectJS(tabId, "page load complete");
        }
      });
    }

    // onHistoryStateUpdated — YouTube SPA pushState navigation.
    //
    // syncCSS runs IMMEDIATELY (no setTimeout):
    //   - Inserts blur CSS for the new URL if it is still YouTube
    //   - Removes ALL stacked layers if the tab left YouTube
    //
    // JS gets a short delay so the new page's DOM can begin to populate
    // before the background-image observer is (re-)attached.
    if (chrome.webNavigation && chrome.webNavigation.onHistoryStateUpdated) {
      chrome.webNavigation.onHistoryStateUpdated.addListener(
        function (details) {
          if (details.frameId !== 0) return;
          if (!isYouTube(details.url)) return;
          LOG("onHistoryStateUpdated — " + details.url);
          syncCSS(details.tabId, details.url); // immediate — no delay
          setTimeout(function () {
            injectJS(details.tabId, "SPA navigation");
          }, 400);
        }
      );
    }

    LOG("Active — monitoring " + DOMAIN);
  }

  // Wait for Chrome extension APIs to become available (same retry
  // pattern as youtubeNU.js — Vivaldi initialises them asynchronously).
  var attempts = 0;
  function waitForApis() {
    if (chrome && chrome.tabs && chrome.tabs.onUpdated) {
      attachListeners();
    } else if (attempts++ < 40) {
      setTimeout(waitForApis, 250);
    } else {
      LOG("ERROR: Chrome APIs never became available");
    }
  }
  waitForApis();
})();
