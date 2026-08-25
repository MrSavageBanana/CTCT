// ==============================================================
//  Channel Browse Blocker — Vivaldi custom.js mod
//  Hides channel browsing content; allows searching within a channel.
//  Drop alongside youtubeNU.js in your Vivaldi mod folder.
//  Created with Claude. Account: Unscripted
// ==============================================================

(function () {
  "use strict";

  var DOMAIN = "www.youtube.com";
  var BODY_CLASS = "chb-blocked";

  // Matches any /@handle URL (home, tabs, search — everything under a channel).
  // The BODY_CLASS gate enforces the real logic in page-world:
  // hide browse content everywhere EXCEPT /@handle/search?query=<value>.
  var CHANNEL_RE = /^https?:\/\/www\.youtube\.com\/@/;

  // CSS uses a body-class gate so it is safe to keep injected across the
  // entire /@handle/* space. It only activates when the pageScript adds the
  // class — never on search-results pages.
  //
  // Why class-toggling instead of selector-only CSS?
  //   A plain "ytd-two-column-browse-results-renderer { display:none }"
  //   injected at /@handle would need to be removed for search pages and
  //   re-injected when coming back — racing against YouTube's own rendering.
  //   Gating on a body class lets us leave the CSS injected for the whole
  //   /@handle/* space and flip visibility instantly with a single classList
  //   call, without touching the CSS injection machinery at all.
  var CSS =
    "body." +
    BODY_CLASS +
    " ytd-two-column-browse-results-renderer { display: none !important; }";

  function ts() {
    var d = new Date();
    return (
      d.toLocaleTimeString("en-GB") +
      "." +
      String(d.getMilliseconds()).padStart(3, "0")
    );
  }
  function LOG(msg) {
    console.log("ChannelBlocker.js: " + msg + " at " + ts());
  }

  // ── CSS injection count tracking ─────────────────────────────
  //
  // Identical problem to youtubeNU.js: chrome.scripting.insertCSS stacks —
  // each call is a separate injection even with identical CSS.
  // removeCSS peels exactly one layer per call.
  //
  // We track how many times the CSS has been injected per tab so that
  // removeCSS is called the exact right number of times when the user
  // navigates away from the channel section entirely.
  //
  // Counts are incremented SYNCHRONOUSLY before the async API call so
  // that a second syncCSSPreload call (arriving milliseconds later from a
  // rapid double-fire of onHistoryStateUpdated) already sees the right total.
  //
  // onCommitted (fresh page load) resets counts — new document, clean slate.
  // ──────────────────────────────────────────────────────────────
  var cssCount = new Map(); // key: tabId → value: number

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

  // ── CSS helpers ───────────────────────────────────────────────
  //
  // injectCSSForUrl — called on onCommitted (fresh page load).
  //   New document: any prior injections are gone, so reset the count
  //   first, then inject only if this is a channel URL.
  //
  // syncCSSPreload  — called on onHistoryStateUpdated (SPA navigation).
  //   If still inside /@handle/*: add another CSS layer (stacking is
  //     harmless — the body-class gate means duplicate layers don't cause
  //     problems and we track the exact count for clean removal later).
  //   If leaving /@handle/* entirely: peel every stacked layer.
  // ──────────────────────────────────────────────────────────────
  function injectCSSForUrl(tabId, url) {
    if (!chrome.scripting) return;
    resetCount(tabId); // fresh document — start from zero
    if (!CHANNEL_RE.test(url)) return;
    incrementCount(tabId); // sync — before the async call
    chrome.scripting
      .insertCSS({ target: { tabId: tabId }, css: CSS, origin: "USER" })
      .then(function () {
        LOG("CSS pre-injected (full load) for " + url);
      })
      .catch(function (e) {
        decrementCount(tabId); // roll back on failure
        LOG("CSS insert failed: " + e);
      });
  }

  function syncCSSPreload(tabId, url) {
    if (!chrome.scripting) return;
    if (CHANNEL_RE.test(url)) {
      // Still inside the channel section. Stack another CSS layer.
      // The body-class gate makes this safe even on search pages — the
      // CSS is present in the document but inert until the class appears.
      incrementCount(tabId);
      chrome.scripting
        .insertCSS({ target: { tabId: tabId }, css: CSS, origin: "USER" })
        .then(function () {
          LOG("CSS pre-injected (SPA) for " + url);
        })
        .catch(function (e) {
          decrementCount(tabId);
          LOG("CSS insert failed: " + e);
        });
    } else {
      // Left the channel section entirely. Remove every stacked layer.
      // Each insertCSS call was a separate injection — we must removeCSS
      // the same number of times to fully clear it.
      var n = getCount(tabId);
      if (n === 0) return; // nothing was injected — nothing to do
      resetCount(tabId); // clear count before async removals begin
      var done = 0;
      for (var i = 0; i < n; i++) {
        chrome.scripting
          .removeCSS({ target: { tabId: tabId }, css: CSS, origin: "USER" })
          .then(function () {
            done++;
            if (done === n) {
              LOG(
                "CSS removed (" +
                  n +
                  " layer(s)) — leaving channel section: " +
                  url,
              );
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
  // Injected via executeScript (world: MAIN) after the page loads.
  // Manages body.chb-blocked based on the current URL, responding to
  // YouTube's own SPA navigation events.
  //
  // Why class-toggling instead of DOM removal (like youtubeNU.js)?
  //   YouTube reuses ytd-two-column-browse-results-renderer across all
  //   SPA navigations within a channel (home, videos, playlists, search).
  //   Removing it with .remove() would require YouTube to fully recreate
  //   it when navigating between tabs — which is unreliable and can cause
  //   blank panels. Toggling a body class is non-destructive: YouTube's
  //   components stay alive in the DOM and render correctly the moment
  //   the class is removed on a search page.
  //
  // On the body-class / CSS-preload timing gap at fresh page loads:
  //   CSS is injected on onCommitted (before first paint).
  //   The body class is applied by this script on onUpdated→complete.
  //   In the narrow window between the two the CSS selector doesn't match —
  //   but ytd-two-column-browse-results-renderer is an empty shell at that
  //   point (populated via XHR which completes after this script runs).
  //   In practice there is no visible flash.
  //
  // The FLAG prevents multiple instances stacking up across re-injections.
  // On SPA navigations a new injectJS call fires (400ms after nav), but the
  // FLAG causes it to exit immediately — the original instance's event
  // listeners are already handling yt-navigate-start/finish.
  // On a fresh page load the flag is reset (new window object).
  //
  // Must be self-contained — no outer-scope references.
  // ──────────────────────────────────────────────────────────────
  function pageScript(BODY_CLASS) {
    var FLAG = "__ytChannelBlockerActive";
    if (window[FLAG]) return; // already running — bail
    window[FLAG] = true;

    function ts() {
      var d = new Date();
      return (
        d.toLocaleTimeString("en-GB") +
        "." +
        String(d.getMilliseconds()).padStart(3, "0")
      );
    }
    function LOG(msg) {
      console.log("ChannelBlocker.js: " + msg + " at " + ts());
    }

    // ── URL predicates ──────────────────────────────────────────
    // Matches any /@handle path (home, videos, playlists, about, search…).
    function isChannelPage() {
      return /^\/@[^/]+/.test(location.pathname);
    }

    // Returns true ONLY when the path is exactly /@handle/search AND
    // ?query= is present and non-empty. An empty search box does not count.
    function isChannelSearchWithQuery() {
      if (!/^\/@[^/]+\/search$/.test(location.pathname)) return false;
      var q = new URLSearchParams(location.search).get("query");
      return Boolean(q && q.trim().length > 0);
    }

    function shouldBlock() {
      return isChannelPage() && !isChannelSearchWithQuery();
    }

    // ── Class helpers ───────────────────────────────────────────
    function applyBlock() {
      if (document.body) {
        document.body.classList.add(BODY_CLASS);
        LOG("BLOCKING — " + location.pathname + location.search);
      }
    }
    function applyAllow() {
      if (document.body) {
        document.body.classList.remove(BODY_CLASS);
        LOG("allowing — " + location.pathname + location.search);
      }
    }

    // ── SPA hooks ───────────────────────────────────────────────
    //
    // yt-navigate-start fires BEFORE YouTube swaps in new content.
    //   → Pre-block unconditionally. Destination is unknown at this point,
    //     but blocking early prevents a flash of browse content while
    //     the new URL and DOM are still updating.
    //     yt-navigate-finish will immediately unblock if the destination
    //     turns out to be a channel search-results page.
    //
    // yt-navigate-finish fires after URL and DOM are updated.
    //   → The real destination is now known. Confirm the block or lift it.
    window.addEventListener("yt-navigate-start", function () {
      applyBlock();
    });
    window.addEventListener("yt-navigate-finish", function () {
      if (shouldBlock()) {
        applyBlock();
      } else {
        applyAllow();
      }
    });

    // ── Initial page load ───────────────────────────────────────
    // executeScript can fire before document.body exists on fast machines.
    // If body is already present, apply immediately. Otherwise, watch for it
    // with a MutationObserver (same pattern as the original Tampermonkey
    // script's initOnBody()).
    function init() {
      if (document.body) {
        if (shouldBlock()) applyBlock();
        return;
      }
      new MutationObserver(function (_, obs) {
        if (document.body) {
          obs.disconnect();
          if (shouldBlock()) applyBlock();
        }
      }).observe(document.documentElement, { childList: true });
    }

    init();
    LOG("Page script active");
  }

  // ── JS injection ──────────────────────────────────────────────
  function injectJS(tabId, reason) {
    if (!chrome.scripting) return;
    LOG("Injecting page script (" + reason + ")");
    chrome.scripting
      .executeScript({
        target: { tabId: tabId, allFrames: false },
        world: "MAIN",
        func: pageScript,
        args: [BODY_CLASS],
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
    // onCommitted — fires before first paint on a full page load.
    // Inject CSS for channel pages; no-op for everything else.
    if (chrome.webNavigation && chrome.webNavigation.onCommitted) {
      chrome.webNavigation.onCommitted.addListener(function (details) {
        if (details.frameId !== 0) return;
        if (isYouTube(details.url)) {
          LOG("onCommitted — " + details.url);
          injectCSSForUrl(details.tabId, details.url);
        }
      });
    }

    // onUpdated (complete) — page is fully loaded.
    // Set up the page-world script that manages the body class.
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
    // syncCSSPreload runs IMMEDIATELY (no delay):
    //   - Injects CSS when navigating deeper into the channel section
    //   - Removes all stacked layers when navigating away from it
    //
    // The pageScript's yt-navigate-start/finish hooks handle the body-class
    // toggle concurrently in the page world.
    //
    // The JS re-injection fires after a short delay to let YouTube's DOM
    // settle. The FLAG in pageScript means it exits immediately — the
    // original instance's listeners are still the ones handling nav events.
    if (chrome.webNavigation && chrome.webNavigation.onHistoryStateUpdated) {
      chrome.webNavigation.onHistoryStateUpdated.addListener(
        function (details) {
          if (details.frameId !== 0) return;
          if (!isYouTube(details.url)) return;
          LOG("onHistoryStateUpdated — " + details.url);
          syncCSSPreload(details.tabId, details.url); // immediate — no delay
          setTimeout(function () {
            injectJS(details.tabId, "SPA navigation");
          }, 400);
        },
      );
    }

    LOG("Active — monitoring " + DOMAIN);
  }

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
