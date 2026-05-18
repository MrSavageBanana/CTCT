// ==============================================================
//  YouTube Cleaner — Vivaldi custom.js mod
//  created with Claude. Account: Milobowler
// ==============================================================

// created with Claude. Account: Milobowler
(function () {
  "use strict";

  const DOMAIN = "www.youtube.com";

  function ts() {
    var d = new Date();
    return (
      d.toLocaleTimeString("en-GB") +
      "." +
      String(d.getMilliseconds()).padStart(3, "0")
    );
  }
  function LOG(mod, msg) {
    console.log("YT-Cleaner.js - " + mod + ": " + msg + " at " + ts());
  }

  // ── Module definitions ────────────────────────────────────────
  //
  //  cssPreload: true  — inject CSS on onCommitted (before first paint).
  //                      On SPA navigation, CSS is also REMOVED when the
  //                      new URL no longer matches, so it never leaks.
  //
  //  cssPreload: false — JS only. For modules with selectors so generic
  //                      (#container, #background) that even leaking for
  //                      one frame would break unrelated pages.
  // ──────────────────────────────────────────────────────────────
  const MODULES = [
    {
      name: "Borders",
      cssPreload: true,
      urlPattern: "^https?://www\\.youtube\\.com/",
      selectors: [
        "ytd-mini-guide-renderer.style-scope.ytd-app",
        "#logo-icon",
        "#buttons > ytd-button-renderer:nth-child(1) > yt-button-shape:nth-child(1)",
        "#button",
        "#icon",
        "#avatar-btn",
        "#voice-search-button > ytd-button-renderer:nth-child(1) > yt-button-shape:nth-child(1)",
        "#guide-button",
        "#country-code",
        "#sections > ytd-guide-section-renderer.style-scope:nth-child(3)",
        "#guide-inner-content",
        "#guide-content",
        "#guide-wrapper",
        "img.style-scope.ytd-yoodle-renderer",
      ],
    },
    {
      name: "Endcards",
      cssPreload: true,
      urlPattern: "^https?://www\\.youtube\\.com/",
      selectors: [
        ".ytp-ce-element",
        ".ytp-ce-covering-overlay",
        ".ytp-ce-element-shadow",
        ".ytp-endscreen-content",
        ".ytp-ce-playlist",
        ".ytp-ce-video",
        ".ytp-ce-channel",
        ".ytp-ce-link",
        "#movie_player > div:nth-child(24) > toggle-button-view-model:nth-child(1) > button-view-model.ytSpecButtonViewModelHost:nth-child(1)",
        "div.ytp-fullscreen-grid-stills-container",
      ],
    },
    {
      name: "Feed",
      // ytd-rich-grid-renderer is specific enough, but feed is rarely visited
      // directly so JS-only is fine here
      cssPreload: false,
      urlPattern: "^https?://www\\.youtube\\.com/feed/",
      selectors: [
        "ytd-rich-grid-renderer.style-scope.ytd-two-column-browse-results-renderer",
      ],
    },
    {
      name: "Homepage",
      // #contents hides the video grid — must be pre-hidden before paint
      // so it never flashes. The tight URL pattern (exact /$) means it will
      // be removed by syncCSSPreloads the moment any SPA nav fires.
      cssPreload: true,
      urlPattern: "^https?://www\\.youtube\\.com/$",
      selectors: ["#contents", "#chips-content"],
    },
    {
      name: "Playlists",
      // #container and #background are too generic — JS only
      cssPreload: false,
      urlPattern: "^https?://www\\.youtube\\.com/playlist\\?list=",
      selectors: [
        "ytd-browse.style-scope.ytd-page-manager",
        "yt-searchbox.ytSearchboxComponentHost.ytSearchboxComponentDesktop.ytd-masthead.ytSearchboxComponentHostDark",
        "#container",
        "#background",
        "ytd-two-column-browse-results-renderer.style-scope.ytd-browse.grid.grid-disabled",
        "ytd-playlist-header-renderer.style-scope.ytd-browse",
      ],
    },
    {
      name: "Metrics",
      cssPreload: true,
      urlPattern: "^https?://www\\.youtube\\.com/",
      selectors: [
        "div#metadata div#metadata-line span:first-of-type",
        "#content > yt-content-metadata-view-model > div:nth-child(2) > span",
        "#contents > yt-content-metadata-view-model > div:nth-child(2) > span:nth-child(1)",
        "div#metadata-line span:first-of-type",
        "span.view-count",
        "div.view-count",
        "ytd-video-view-count-renderer",
        "div#description-content span:first-of-type",
        "div#info-text div#count",
        "#info > span:nth-child(1)",
        "ytm-slim-video-information-renderer .secondary-text .yt-core-attributed-string",
        "#view-count > yt-animated-rolling-number",
        "ytm-factoid-renderer:nth-child(1)",
        "ytm-factoid-renderer:nth-child(2)",
        "yt-formatted-string#formatted-snippet-text span:first-of-type",
        "yt-formatted-string#info.style-scope.ytd-watch-metadata span:first-of-type",
        "ytd-toggle-button-renderer.ytd-menu-renderer yt-formatted-string#text",
        "ytd-sentiment-bar-renderer#sentiment",
        "div#segmented-like-button div.yt-spec-button-shape-next--button-text-content",
        "#segmented-like-button > ytd-toggle-button-renderer > yt-button-shape > button > div:nth-child(2)",
        "toggle-button-view-model div.yt-spec-button-shape-next__button-text-content",
        "#segmented-like-button button div span",
        "#subscribers",
        "#page-header > yt-page-header-renderer > yt-page-header-view-model > div > div.page-header-view-model-wiz__page-header-headline > div > yt-content-metadata-view-model > div:nth-child(3) > span:nth-child(1)",
        "yt-formatted-string#subscriber-count",
        "yt-formatted-string#owner-sub-count",
        "div#metadata > span#subscribers",
        "ytd-comments",
        "div#comment-teaser",
        "#vote-count-middle",
        "ytd-comment-action-buttons-renderer span#vote-count-middle",
        "div:nth-child(1) > div:nth-child(2) > yt-content-metadata-view-model:nth-child(2) > div:nth-child(3) > span.ytAttributedStringHost:nth-child(1)",
        "div:nth-child(1) > div:nth-child(2) > yt-content-metadata-view-model:nth-child(2) > div:nth-child(3) > span.ytContentMetadataViewModelDelimiter:nth-child(2)",
        "#metadata",
        "ytm-shorts-lockup-view-model:nth-child(1) > div:nth-child(2) > div:nth-child(1) > div:nth-child(2) > span.ytAttributedStringHost:nth-child(1)",
      ],
    },
  ];

  // Pre-compile regex and CSS string for each module
  MODULES.forEach(function (mod) {
    mod.re = new RegExp(mod.urlPattern);
    mod.css = mod.selectors
      .map(function (sel) {
        return sel + " { display: none !important; }";
      })
      .join("\n");
  });

  // ── CSS helpers ───────────────────────────────────────────────
  //
  // injectCSSForUrl  — used on onCommitted (fresh page load).
  //                    Only inserts; no removal needed on a fresh page.
  //
  // syncCSSPreloads  — used on onHistoryStateUpdated (SPA navigation).
  //                    Inserts CSS for modules that NOW match the new URL,
  //                    AND removes CSS for modules that no longer match.
  //                    This is what prevents Homepage CSS leaking onto
  //                    search results when the user types a query.
  // ──────────────────────────────────────────────────────────────
  function injectCSSForUrl(tabId, url) {
    if (!chrome.scripting) return;
    MODULES.forEach(function (mod) {
      if (!mod.cssPreload || !mod.re.test(url)) return;
      chrome.scripting
        .insertCSS({ target: { tabId: tabId }, css: mod.css, origin: "USER" })
        .then(function () {
          LOG(mod.name, "CSS pre-injected (full load) for " + url);
        })
        .catch(function (e) {
          LOG(mod.name, "CSS insert failed: " + e);
        });
    });
  }

  function syncCSSPreloads(tabId, url) {
    if (!chrome.scripting) return;
    MODULES.forEach(function (mod) {
      if (!mod.cssPreload) return;
      if (mod.re.test(url)) {
        chrome.scripting
          .insertCSS({ target: { tabId: tabId }, css: mod.css, origin: "USER" })
          .then(function () {
            LOG(mod.name, "CSS pre-injected (SPA) for " + url);
          })
          .catch(function (e) {
            LOG(mod.name, "CSS insert failed: " + e);
          });
      } else {
        // Remove CSS left over from a previous page that matched this module.
        // This fires immediately on SPA nav — before the new page renders —
        // so the stale CSS is gone before search results paint.
        chrome.scripting
          .removeCSS({ target: { tabId: tabId }, css: mod.css, origin: "USER" })
          .then(function () {
            LOG(mod.name, "CSS removed (no longer matches " + url + ")");
          })
          .catch(function () {
            /* wasn't injected — fine */
          });
      }
    });
  }

  // ── Page-world script ─────────────────────────────────────────
  // Injected via executeScript (world: MAIN) after the page loads.
  // Removes nodes and watches for YouTube re-injecting them.
  // Must be self-contained — no outer-scope references.
  // ──────────────────────────────────────────────────────────────
  function pageScript(modules) {
    var FLAG = "__ytCleanerActive";
    if (window[FLAG]) return;
    window[FLAG] = true;

    function ts() {
      var d = new Date();
      return (
        d.toLocaleTimeString("en-GB") +
        "." +
        String(d.getMilliseconds()).padStart(3, "0")
      );
    }

    function urlMatches(patternStr) {
      try {
        return new RegExp(patternStr).test(location.href);
      } catch (e) {
        return false;
      }
    }

    function removeAll(reason) {
      modules.forEach(function (mod) {
        if (!urlMatches(mod.urlPattern)) return;
        var count = 0;
        mod.selectors.forEach(function (sel) {
          try {
            document.querySelectorAll(sel).forEach(function (el) {
              el.remove();
              count++;
            });
          } catch (e) {}
        });
        if (count > 0) {
          console.log(
            "YT-Cleaner.js - " +
              mod.name +
              ": Removed " +
              count +
              " object(s) at " +
              ts() +
              " because " +
              reason,
          );
        }
      });
    }

    var debounceTimer;
    var pendingReason;
    function debouncedRemove(reason, delay) {
      if (!pendingReason) pendingReason = reason;
      clearTimeout(debounceTimer);
      debounceTimer = setTimeout(
        function () {
          var r = pendingReason;
          pendingReason = null;
          removeAll(r);
        },
        delay != null ? delay : 150,
      );
    }

    setTimeout(function () {
      removeAll("initial load (100ms)");
    }, 100);
    setTimeout(function () {
      removeAll("initial load (800ms)");
    }, 800);

    var lastUrl = location.href;
    new MutationObserver(function () {
      if (location.href !== lastUrl) {
        var from = lastUrl;
        lastUrl = location.href;
        debouncedRemove("SPA nav from " + from, 500);
      }
    }).observe(document.documentElement, { childList: true, subtree: true });

    new MutationObserver(function () {
      debouncedRemove("DOM mutation", 150);
    }).observe(document.documentElement, { childList: true, subtree: true });
  }

  function injectJS(tabId, reason) {
    if (!chrome.scripting) return;
    LOG("Core", "Injecting page script (" + reason + ")");
    chrome.scripting
      .executeScript({
        target: { tabId: tabId, allFrames: false },
        world: "MAIN",
        func: pageScript,
        args: [MODULES],
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
    // onCommitted — fires before first paint.
    // Fresh page: inject CSS for matching modules only.
    if (chrome.webNavigation && chrome.webNavigation.onCommitted) {
      chrome.webNavigation.onCommitted.addListener(function (details) {
        if (details.frameId !== 0) return;
        if (isYouTube(details.url)) {
          LOG("Core", "onCommitted — " + details.url);
          injectCSSForUrl(details.tabId, details.url);
        }
      });
    }

    // onUpdated (complete) — page is fully loaded, set up JS observer.
    if (chrome.tabs && chrome.tabs.onUpdated) {
      chrome.tabs.onUpdated.addListener(function (tabId, changeInfo, tab) {
        if (changeInfo.status === "complete" && isYouTube(tab.url)) {
          LOG("Core", "onUpdated complete — " + tab.url);
          injectJS(tabId, "page load complete");
        }
      });
    }

    // onHistoryStateUpdated — SPA pushState (clicking links on YouTube).
    //
    // syncCSSPreloads runs IMMEDIATELY (no setTimeout):
    //   - Inserts CSS for modules matching the new URL
    //   - Removes CSS for modules that no longer match (e.g. Homepage
    //     CSS is removed here before search results ever render)
    //
    // JS gets a short delay to let the new page's DOM populate.
    if (chrome.webNavigation && chrome.webNavigation.onHistoryStateUpdated) {
      chrome.webNavigation.onHistoryStateUpdated.addListener(
        function (details) {
          if (details.frameId !== 0) return;
          if (!isYouTube(details.url)) return;
          LOG("Core", "onHistoryStateUpdated — " + details.url);
          syncCSSPreloads(details.tabId, details.url); // immediate, no delay
          setTimeout(function () {
            injectJS(details.tabId, "SPA navigation");
          }, 400);
        },
      );
    }

    LOG("Core", "Active — monitoring " + DOMAIN);
  }

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
