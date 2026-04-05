// ============================================================
// multi-domain-remover.js — Element Remover for Vivaldi custom.js
// ============================================================
(function () {
  "use strict";

  const LOG = (s) => console.log("[Remover:Multi]", s);

  const CONFIGS = [
    {
      domain: "www.youtube.com",
      pattern: "^https://www\\.youtube\\.com/$",
      selectors: [
        "#chips-content",
        "#contents",
        "ytd-feed-filter-chip-bar-renderer.style-scope.ytd-rich-grid-renderer",
        "#button",
        "#icon",
        // Hides the shorts player if it lingers in the DOM while navigating
        // back to the homepage, preventing the flash of the black screen.
        "ytd-shorts.style-scope.ytd-page-manager",
      ],
    },
    {
      domain: "www.youtube.com",
      pattern: "^https://www\\.youtube\\.com/shorts/.*$",
      selectors: [
        "ytd-mini-guide-renderer.style-scope.ytd-app",
        "#sections > ytd-guide-section-renderer.style-scope:nth-child(3)",
        "#guide-inner-content",
        "#guide-content",
        "#guide-wrapper",
        "#contentContainer",
        "ytd-shorts.style-scope.ytd-page-manager",
      ],
    },
  ];

  // Group configs by domain so one pageScript handles all rules for that domain
  const configsByDomain = {};
  CONFIGS.forEach((cfg) => {
    if (!configsByDomain[cfg.domain]) configsByDomain[cfg.domain] = [];
    configsByDomain[cfg.domain].push(cfg);
  });

  // ── pageScript ───────────────────────────────────────────────
  // Injected ONCE per domain. Handles every config for that domain.
  // Must be fully self-contained — no references to outer scope.
  function pageScript(configs) {
    const FLAG = "__overlayRemoverUnified__";
    if (window[FLAG]) return;
    window[FLAG] = true;

    // Data attribute used to mark hidden elements.
    const ATTR = "data-orh-hidden";

    const compiled = configs.map(function (c) {
      return { selectors: c.selectors, regex: new RegExp(c.pattern) };
    });

    function getMatchingConfig() {
      for (var i = 0; i < compiled.length; i++) {
        if (compiled[i].regex.test(location.href)) return compiled[i];
      }
      return null;
    }

    // Pause every playing video/audio element on the page.
    // Called when entering the shorts URL (player is hidden but audio runs)
    // and when leaving it (audio would otherwise bleed into the next page).
    function stopMedia() {
      document.querySelectorAll("video, audio").forEach(function (media) {
        try {
          media.pause();
        } catch (e) {}
      });
    }

    function isShorts(url) {
      return /^https:\/\/www\.youtube\.com\/shorts\//.test(url);
    }

    // ── Capture-phase play interceptor ───────────────────────────
    // Registered once for the lifetime of the page. Fires synchronously
    // the instant any <video> or <audio> calls play() — before a single
    // audio frame is decoded — and immediately pauses it when on a shorts URL.
    // This is faster than any setTimeout approach because there is zero delay:
    // the pause happens in the same JS task as the play() call itself.
    document.addEventListener(
      "play",
      function (e) {
        if (isShorts(location.href)) {
          try {
            e.target.pause();
          } catch (err) {}
        }
      },
      true, // capture phase — intercepts before the element's own handlers
    );

    // Remove our hiding from every element we previously hid.
    function restoreAll() {
      document.querySelectorAll("[" + ATTR + "]").forEach(function (el) {
        el.style.removeProperty("display");
        el.removeAttribute(ATTR);
      });
    }

    // Hide elements for the given config. Idempotent — skips already-hidden ones.
    function applyConfig(cfg) {
      if (!cfg) return;
      cfg.selectors.forEach(function (selector) {
        try {
          document.querySelectorAll(selector).forEach(function (el) {
            if (!el.hasAttribute(ATTR)) {
              el.setAttribute(ATTR, "1");
              el.style.setProperty("display", "none", "important");
            }
          });
        } catch (e) {}
      });
    }

    // lastUrl is owned by update() so the MutationObserver's URL-change
    // branch never re-fires for a navigation that update() already handled.
    var lastUrl = location.href;

    // Full cycle: wipe previous state, apply current URL's rules.
    function update() {
      var prevUrl = lastUrl;
      var currentUrl = location.href;
      lastUrl = currentUrl; // claim this URL immediately

      // ── Stop audio when leaving the shorts player ──────────────
      // The hidden <ytd-shorts> element keeps its <video> running.
      // Pausing before restoreAll() means audio stops the instant
      // navigation begins, not after the next page finishes loading.
      if (isShorts(prevUrl) && !isShorts(currentUrl)) {
        stopMedia();
      }

      restoreAll();
      applyConfig(getMatchingConfig());

      // ── Stop audio when entering / staying on a shorts URL ─────
      // The capture-phase play interceptor above handles new play() calls
      // instantly, so these are just a safety net for streams that were
      // already running before the interceptor could fire.
      if (isShorts(currentUrl)) {
        stopMedia();
        setTimeout(stopMedia, 50);
        setTimeout(stopMedia, 200);
      }
    }

    // Debounced re-apply for the same-URL case (catches lazy-loaded elements).
    var debounceTimer = null;
    function debouncedApply(delay) {
      clearTimeout(debounceTimer);
      debounceTimer = setTimeout(function () {
        applyConfig(getMatchingConfig());
        // Also silence any audio that YouTube started after the initial pause.
        if (isShorts(location.href)) {
          stopMedia();
        }
      }, delay || 150);
    }

    // Initial runs — handles elements present at injection time + late arrivals.
    update();
    setTimeout(update, 500);
    setTimeout(update, 1500);

    // ── Synchronous URL-change detection ────────────────────────
    // Wrapping pushState/replaceState fires update() the instant YouTube
    // changes the URL, before any frame is rendered — eliminating the flash.
    function wrapHistory(method) {
      var original = history[method].bind(history);
      history[method] = function () {
        original.apply(history, arguments);
        update();
      };
    }
    wrapHistory("pushState");
    wrapHistory("replaceState");
    window.addEventListener("popstate", update);

    // ── MutationObserver ─────────────────────────────────────────
    // Two jobs:
    //  1. Fallback URL-change detection (catches anything pushState missed).
    //     Because update() sets lastUrl = location.href synchronously,
    //     this branch only fires for navigations that the pushState hook missed.
    //  2. Same-URL DOM changes: hide elements as YouTube lazy-loads them.
    new MutationObserver(function () {
      if (location.href !== lastUrl) {
        // Fallback path — update() will set lastUrl so this won't double-fire.
        update();
      } else {
        // Same URL, DOM changed. Apply immediately + debounced for late nodes.
        applyConfig(getMatchingConfig());
        debouncedApply(150);
      }
    }).observe(document.documentElement, { childList: true, subtree: true });
  }
  // ── End pageScript ───────────────────────────────────────────

  function injectJS(tabId, configs) {
    if (!chrome.scripting) return;
    chrome.scripting
      .executeScript({
        target: { tabId, allFrames: false },
        world: "MAIN",
        func: pageScript,
        args: [configs],
      })
      .then(() => LOG("Injected into tab " + tabId))
      .catch((e) => LOG("Inject failed: " + e));
  }

  function getDomainConfigs(url) {
    if (!url) return null;
    for (var domain in configsByDomain) {
      if (url.includes(domain)) return configsByDomain[domain];
    }
    return null;
  }

  function attachListeners() {
    LOG("Attaching listeners");

    // Full page load — primary injection point.
    if (chrome.tabs && chrome.tabs.onUpdated) {
      chrome.tabs.onUpdated.addListener(function (tabId, changeInfo, tab) {
        if (changeInfo.status === "complete" && tab.url) {
          var cfgs = getDomainConfigs(tab.url);
          if (cfgs) injectJS(tabId, cfgs);
        }
      });
    }

    // Fallback: inject on history state updates in case status=complete
    // doesn't fire for a given SPA navigation. FLAG makes re-injection a no-op.
    if (chrome.webNavigation && chrome.webNavigation.onHistoryStateUpdated) {
      chrome.webNavigation.onHistoryStateUpdated.addListener(
        function (details) {
          if (details.frameId !== 0) return;
          var cfgs = getDomainConfigs(details.url);
          if (cfgs) injectJS(details.tabId, cfgs);
        },
      );
    }
  }

  var attempts = 0;
  function waitForApis() {
    if (chrome && chrome.tabs && chrome.tabs.onUpdated) {
      LOG("APIs ready after " + attempts + " attempt(s)");
      attachListeners();
    } else if (attempts++ < 40) {
      setTimeout(waitForApis, 250);
    } else {
      LOG("Gave up waiting for chrome.tabs API");
    }
  }

  waitForApis();
})();
