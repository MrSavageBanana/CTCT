// ==============================================================
//  YouTube No Hover Preview — Vivaldi custom.js mod
//  Blocks hover/mouseover video previews on YouTube search pages.
//  Architecture mirrors youtubeNU.js (same SPA + CSS-stack handling).
// ==============================================================
// created with Claude. Account: Burhan Ra'if Kouri

(function () {
  "use strict";

  const DOMAIN = "www.youtube.com";

  // Matches /results?... and /search?... (the two search URL forms YouTube uses)
  const SEARCH_PATTERN = "^https?://www\\.youtube\\.com/(results|search)";
  const searchRe = new RegExp(SEARCH_PATTERN);

  function ts() {
    var d = new Date();
    return (
      d.toLocaleTimeString("en-GB") +
      "." +
      String(d.getMilliseconds()).padStart(3, "0")
    );
  }
  function LOG(section, msg) {
    console.log("YT-NoHover.js - " + section + ": " + msg + " at " + ts());
  }

  // ── CSS (Layer 3) ─────────────────────────────────────────────
  //
  // Pre-injected via onCommitted (before first paint) whenever a search page
  // loads — hard reload or SPA nav.  Removed immediately when the user navigates
  // away so it never leaks onto non-search pages (same cssPreload strategy as
  // youtubeNU.js).
  //
  // Covers every overlay element and animated-thumbnail <video> that YouTube
  // injects into search-result cards.
  // ──────────────────────────────────────────────────────────────
  var HOVER_CSS =
    [
      "ytd-video-renderer #mouseover-overlay",
      "ytd-video-renderer ytd-thumbnail-overlay-loading-preview-renderer",
      "ytd-compact-video-renderer #mouseover-overlay",
      "ytd-video-preview",
      "ytd-moving-thumbnail-renderer",
      "#mouseover-overlay.ytd-thumbnail",
      ".ytp-inline-preview-ui",
      ".ytp-inline-preview-overlay",
      "ytd-rich-item-renderer ytd-moving-thumbnail-renderer",
      "ytd-rich-item-renderer video",
      "ytd-video-renderer video",
      "ytd-thumbnail video",
    ]
      .map(function (sel) {
        return (
          sel +
          " { display: none !important; opacity: 0 !important;" +
          " pointer-events: none !important; visibility: hidden !important; }"
        );
      })
      .join("\n") +
    "\nytd-thumbnail:hover img, ytd-thumbnail:hover yt-image" +
    " { animation: none !important; transition: none !important; }";

  // ── CSS injection count tracking ──────────────────────────────
  //
  // chrome.scripting.insertCSS STACKS — each call is a separate injection,
  // removeCSS only peels one layer at a time.
  //
  // Problem: onHistoryStateUpdated can fire twice in quick succession on some
  // SPA navigations (e.g. homepage → search), stacking two CSS injections.
  // A single removeCSS call leaves one layer active → search CSS leaks.
  //
  // Fix: track exactly how many insertCSS calls have been made per tab.
  // On removal, call removeCSS that many times.  Count is incremented
  // synchronously before the async API call so a second syncCSS call
  // (a few ms later) already sees the correct total.
  // onCommitted (fresh page load) resets the count — new document, clean slate.
  // ──────────────────────────────────────────────────────────────
  var cssCount = new Map();

  function getCC(tabId) {
    return cssCount.get(tabId) || 0;
  }
  function incCC(tabId) {
    cssCount.set(tabId, getCC(tabId) + 1);
  }
  function decCC(tabId) {
    cssCount.set(tabId, Math.max(0, getCC(tabId) - 1));
  }
  function resetCC(tabId) {
    cssCount.set(tabId, 0);
  }

  function doInsertCSS(tabId) {
    if (!chrome.scripting) return;
    incCC(tabId); // synchronous — before the async call
    chrome.scripting
      .insertCSS({ target: { tabId: tabId }, css: HOVER_CSS, origin: "USER" })
      .then(function () {
        LOG("CSS", "Injected hover-suppression CSS");
      })
      .catch(function (e) {
        decCC(tabId); // roll back on failure
        LOG("CSS", "Insert failed: " + e);
      });
  }

  function doRemoveCSS(tabId) {
    if (!chrome.scripting) return;
    var n = getCC(tabId);
    if (n === 0) return;
    resetCC(tabId); // clear before the async removals
    for (var i = 0; i < n; i++) {
      chrome.scripting
        .removeCSS({ target: { tabId: tabId }, css: HOVER_CSS, origin: "USER" })
        .catch(function () {
          /* layer already gone — fine */
        });
    }
    LOG("CSS", "Removed " + n + " layer(s) of hover-suppression CSS");
  }

  // Called on SPA nav: insert if now on a search page, remove if leaving one
  function syncCSS(tabId, url) {
    if (searchRe.test(url)) {
      doInsertCSS(tabId);
    } else {
      doRemoveCSS(tabId);
    }
  }

  // ── Page-world script ─────────────────────────────────────────
  //
  // Injected via executeScript (world: MAIN) — runs in the tab's page context.
  // Handles three JS protection layers:
  //
  //   Layer 1 — HTMLVideoElement.prototype.play override
  //             Intercepts YouTube's play() call on preview videos inside
  //             search cards and returns a resolved Promise instead.
  //
  //   Layer 2 — DOM video killer
  //             Pauses and strips any <video> element injected into a search
  //             card, caught by MutationObserver as YouTube adds them.
  //
  //   Layer 4 — Hover event blocker
  //             Adds a capturing listener on each search-result card that
  //             calls stopImmediatePropagation() so YouTube's own mouseover
  //             handlers never fire.
  //
  // The window FLAG ensures this initialises only once per page session.
  // After the first injection the internal MutationObservers stay alive and
  // handle all subsequent SPA navigations without needing re-injection.
  // Layer 1's prototype patch persists for the life of the page; isSearch()
  // gates its effect so videos on non-search pages still play normally.
  //
  // Must be SELF-CONTAINED — no references to outer scope variables.
  // ──────────────────────────────────────────────────────────────
  function pageScript(searchPattern) {
    var FLAG = "__ytNoHoverPreviewMod";
    if (window[FLAG]) return;
    window[FLAG] = true;

    var re = new RegExp(searchPattern);
    function isSearch() {
      return re.test(location.href);
    }

    // Selectors for elements that host inline preview videos
    var CARDS = [
      "ytd-video-renderer",
      "ytd-rich-item-renderer",
      "ytd-compact-video-renderer",
      "ytd-thumbnail",
      "ytd-video-preview",
    ].join(", ");

    // ── Layer 1: prototype override ───────────────────────────────
    var nativePlay = window.HTMLVideoElement.prototype.play;
    window.HTMLVideoElement.prototype.play = function () {
      if (isSearch() && this.closest && this.closest(CARDS)) {
        // Silently cancel playback inside a search result card
        return Promise.resolve();
      }
      return nativePlay.apply(this, arguments);
    };

    // ── Layer 2: DOM video killer ─────────────────────────────────
    function killVideos() {
      if (!isSearch()) return;
      document.querySelectorAll(CARDS + " video").forEach(function (v) {
        v.pause();
        v.muted = true;
        v.src = "";
        v.srcObject = null;
        try {
          v.load();
        } catch (_) {}
      });
    }

    // ── Layer 4: hover event blocker ─────────────────────────────
    function blockHoverEvents(root) {
      if (!isSearch()) return;
      var q = root && root.querySelectorAll ? root : document;
      q.querySelectorAll(
        "ytd-thumbnail, ytd-video-renderer, ytd-rich-item-renderer",
      ).forEach(function (el) {
        if (el.dataset.nhBlocked) return; // already guarded
        el.dataset.nhBlocked = "1";
        [
          "mouseover",
          "mouseenter",
          "mousemove",
          "pointerover",
          "pointerenter",
        ].forEach(function (eventType) {
          el.addEventListener(
            eventType,
            function (e) {
              if (isSearch()) e.stopImmediatePropagation();
            },
            true, // capture phase — fires before YouTube's own handlers
          );
        });
      });
    }

    function runAll(root) {
      killVideos();
      blockHoverEvents(root || document);
    }

    // ── Initial passes ────────────────────────────────────────────
    // Two staggered passes catch cards that render at different times
    // (YouTube's virtual scroll / lazy hydration can spread them out).
    setTimeout(function () {
      runAll();
    }, 100);
    setTimeout(function () {
      runAll();
    }, 800);

    // ── SPA navigation detection ──────────────────────────────────
    // MutationObserver on documentElement is the lightest reliable way to
    // detect YouTube's pushState navigations without polling location.href.
    var debTimer;
    var lastUrl = location.href;
    new MutationObserver(function () {
      if (location.href !== lastUrl) {
        var prev = lastUrl;
        lastUrl = location.href;
        clearTimeout(debTimer);
        // 500ms debounce — lets YouTube finish rendering the new page
        debTimer = setTimeout(function () {
          console.log(
            "YT-NoHover.js - pageScript: SPA nav from " +
              prev +
              " to " +
              location.href,
          );
          runAll();
        }, 500);
      }
    }).observe(document.documentElement, { childList: true, subtree: true });

    // ── New nodes injected by YouTube ─────────────────────────────
    // YouTube injects search-card children lazily (virtual scroll, SPA render).
    // Process each new Element node as it appears so it gets guarded
    // immediately — no need to wait for the 500ms SPA debounce.
    new MutationObserver(function (mutations) {
      mutations.forEach(function (m) {
        m.addedNodes.forEach(function (node) {
          if (node.nodeType === 1) {
            // Element nodes only
            killVideos();
            blockHoverEvents(node);
          }
        });
      });
    }).observe(document.body || document.documentElement, {
      childList: true,
      subtree: true,
    });

    console.log("YT-NoHover.js - pageScript: Initialised on " + location.href);
  }

  function injectJS(tabId, reason) {
    if (!chrome.scripting) return;
    LOG("Core", "Injecting page script (" + reason + ")");
    chrome.scripting
      .executeScript({
        target: { tabId: tabId, allFrames: false },
        world: "MAIN",
        func: pageScript,
        args: [SEARCH_PATTERN],
      })
      .catch(function (e) {
        LOG("Core", "JS inject failed: " + e);
      });
  }

  function isYouTube(url) {
    return typeof url === "string" && url.includes(DOMAIN);
  }

  // ── Navigation listeners ──────────────────────────────────────
  function attachListeners() {
    // ── onCommitted ───────────────────────────────────────────────
    // Fires before first paint — ideal for CSS injection.
    // On a fresh page load the old document is gone, so we reset the CSS
    // injection count (clean slate) then inject if this is a search page.
    if (chrome.webNavigation && chrome.webNavigation.onCommitted) {
      chrome.webNavigation.onCommitted.addListener(function (details) {
        if (details.frameId !== 0) return;
        if (!isYouTube(details.url)) return;
        LOG("Core", "onCommitted — " + details.url);
        resetCC(details.tabId);
        if (searchRe.test(details.url)) {
          doInsertCSS(details.tabId);
        }
      });
    }

    // ── onUpdated (complete) ──────────────────────────────────────
    // Fires when the page is fully loaded and DOM is ready.
    // Inject the page-world script (Layers 1, 2, 4) for ALL YouTube pages —
    // the internal window FLAG makes it initialise only once, and the internal
    // SPA observer then handles subsequent search-page navigations.
    if (chrome.tabs && chrome.tabs.onUpdated) {
      chrome.tabs.onUpdated.addListener(function (tabId, changeInfo, tab) {
        if (changeInfo.status === "complete" && isYouTube(tab.url)) {
          LOG("Core", "onUpdated complete — " + tab.url);
          injectJS(tabId, "page load complete");
        }
      });
    }

    // ── onHistoryStateUpdated ─────────────────────────────────────
    // Fires on YouTube's pushState SPA navigations (clicking links in-page).
    //
    // syncCSS runs IMMEDIATELY (no setTimeout):
    //   - Inserts CSS when navigating TO a search page
    //   - Removes ALL stacked CSS layers when navigating AWAY from search
    //     (e.g. Homepage CSS is gone before search results ever render)
    //
    // injectJS gets a 400ms delay to let the new page's DOM populate before
    // the page script tries to find and guard search-card elements.
    // After the first injection the internal SPA observer handles everything,
    // so the FLAG check causes subsequent calls to return early harmlessly.
    if (chrome.webNavigation && chrome.webNavigation.onHistoryStateUpdated) {
      chrome.webNavigation.onHistoryStateUpdated.addListener(
        function (details) {
          if (details.frameId !== 0) return;
          if (!isYouTube(details.url)) return;
          LOG("Core", "onHistoryStateUpdated — " + details.url);
          syncCSS(details.tabId, details.url); // immediate — before render
          setTimeout(function () {
            injectJS(details.tabId, "SPA navigation");
          }, 400);
        },
      );
    }

    LOG("Core", "Active — monitoring YouTube search pages");
  }

  // ── Startup ───────────────────────────────────────────────────
  // Poll for Chrome APIs — same retry pattern as youtubeNU.js
  var attempts = 0;
  function waitForApis() {
    if (chrome && chrome.tabs && chrome.tabs.onUpdated) {
      attachListeners();
    } else if (attempts++ < 40) {
      setTimeout(waitForApis, 250);
    } else {
      LOG("Core", "ERROR: Chrome APIs never became available");
    }
  }
  waitForApis();
})();
