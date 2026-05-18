// ============================================================
// multi-domain-remover.js — Element Remover for Vivaldi custom.js
//  Claude: Shayan. Title: Adding multiple domains to a script
// ============================================================
(function () {
  "use strict";

  const LOG = (s) => console.log("[Remover:Multi]", s);

  // ============================================================
  // CONFIG — Add new domains here. Each entry needs:
  //   domain:    substring used to detect same-domain navigations
  //   pattern:   full regex string for the exact URL(s) you want to target
  //   selectors: array of CSS selectors to remove on matching pages
  // ============================================================
  const CONFIGS = [
    {
      domain: "www.reddit.com",
      pattern: "^https?://www\\.reddit\\.com/$",
      selectors: [
        "div.grid-container.theme-rpl.grid.flex-nav-expanded",
        "#notifications-inbox-button",
        "div.pe-lg.flex.gap-xs.items-center.justify-start",
      ],
    },
    // --- Add more domains below this line ---
    {
      domain: "www.reddit.com",
      pattern: "^https?://www\.reddit\.com/r/popular/$",
      selectors: [
        "div.grid-container.theme-rpl.grid.flex-nav-expanded",
        "#notifications-inbox-button",
        "div.pe-lg.flex.gap-xs.items-center.justify-start",
      ],
    },
    {
      domain: "www.reddit.com",
      pattern: "^https?://www\\.reddit\\.com/\\?feed=home",
      selectors: [
        "div.grid-container.theme-rpl.grid.flex-nav-expanded",
        "#notifications-inbox-button",
        "div.pe-lg.flex.gap-xs.items-center.justify-start",
      ],
    },
    {
      domain: "www.reddit.com",
      pattern: "^https?://www\.reddit\.com/news/$",
      selectors: [
        "div.grid-container.theme-rpl.grid.flex-nav-expanded",
        "#notifications-inbox-button",
        "div.pe-lg.flex.gap-xs.items-center.justify-start",
      ],
    },
  ];
  // ============================================================

  // Pre-compile each config's regex and CSS once
  const COMPILED = CONFIGS.map((cfg) => ({
    ...cfg,
    regex: new RegExp(cfg.pattern),
    cssRules: cfg.selectors
      .map((s) => s + " { display: none !important; }")
      .join("\n"),
  }));

  function getConfigForUrl(url) {
    if (!url) return null;
    return COMPILED.find((cfg) => cfg.regex.test(url)) || null;
  }

  function getSameDomainConfig(url) {
    if (!url) return null;
    return COMPILED.find((cfg) => url.includes(cfg.domain)) || null;
  }

  // --- Page script injected into the page context ---
  // Must be fully self-contained — no references to outer scope
  function pageScript(selectors, urlPatternStr) {
    const FLAG = "__overlayRemoverActive_" + urlPatternStr;
    if (window[FLAG]) return;
    window[FLAG] = true;
    console.log("[Remover:Multi] Active for", urlPatternStr);

    const URL_PATTERN = new RegExp(urlPatternStr);

    function isCurrentUrlMatch() {
      return URL_PATTERN.test(location.href);
    }

    function removeElements() {
      if (!isCurrentUrlMatch()) return 0;
      let count = 0;
      selectors.forEach(function (selector) {
        try {
          document.querySelectorAll(selector).forEach(function (el) {
            el.remove();
            count++;
          });
        } catch (e) {}
      });
      if (count)
        console.log("[Remover:Multi] Removed " + count + " element(s)");
      return count;
    }

    var debounceTimer = null;
    function debouncedRemove(delay) {
      clearTimeout(debounceTimer);
      debounceTimer = setTimeout(removeElements, delay || 150);
    }

    setTimeout(removeElements, 200);
    setTimeout(removeElements, 1500);

    var lastUrl = location.href;
    new MutationObserver(function () {
      if (location.href !== lastUrl) {
        lastUrl = location.href;
        debouncedRemove(600);
      }
    }).observe(document.documentElement, { childList: true, subtree: true });

    new MutationObserver(function () {
      debouncedRemove(150);
    }).observe(document.documentElement, { childList: true, subtree: true });
  }

  // --- Background-side helpers ---

  function injectCSS(tabId, cfg) {
    if (!chrome.scripting || !cfg.cssRules) return;
    chrome.scripting
      .insertCSS({
        target: { tabId },
        css: cfg.cssRules,
        origin: "USER",
      })
      .catch((e) => LOG("CSS inject failed: " + e));
  }

  function removeCSS(tabId, cfg) {
    if (!chrome.scripting || !cfg.cssRules) return;
    chrome.scripting
      .removeCSS({
        target: { tabId },
        css: cfg.cssRules,
        origin: "USER",
      })
      .catch((e) => LOG("CSS remove failed: " + e));
  }

  function injectJS(tabId, cfg) {
    if (!chrome.scripting) return;
    chrome.scripting
      .executeScript({
        target: { tabId, allFrames: false },
        world: "MAIN",
        func: pageScript,
        args: [cfg.selectors, cfg.pattern],
      })
      .then(() => LOG("JS injected into tab " + tabId + " for " + cfg.domain))
      .catch((e) => LOG("JS inject failed: " + e));
  }

  function attachListeners() {
    LOG("Attaching listeners for " + COMPILED.length + " domain config(s)");

    if (chrome.webNavigation && chrome.webNavigation.onCommitted) {
      chrome.webNavigation.onCommitted.addListener(function (details) {
        if (details.frameId !== 0) return;
        const matchCfg = getConfigForUrl(details.url);
        if (matchCfg) {
          injectCSS(details.tabId, matchCfg);
        } else {
          const domainCfg = getSameDomainConfig(details.url);
          if (domainCfg) removeCSS(details.tabId, domainCfg);
        }
      });
    }

    if (chrome.tabs && chrome.tabs.onUpdated) {
      chrome.tabs.onUpdated.addListener(function (tabId, changeInfo, tab) {
        if (changeInfo.status === "complete" && tab.url) {
          const cfg = getConfigForUrl(tab.url);
          if (cfg) injectJS(tabId, cfg);
        }
        if (changeInfo.url) {
          const matchCfg = getConfigForUrl(changeInfo.url);
          if (matchCfg) {
            setTimeout(() => {
              injectCSS(tabId, matchCfg);
              injectJS(tabId, matchCfg);
            }, 700);
          } else {
            const domainCfg = getSameDomainConfig(changeInfo.url);
            if (domainCfg) setTimeout(() => removeCSS(tabId, domainCfg), 700);
          }
        }
      });
    }

    if (chrome.webNavigation && chrome.webNavigation.onHistoryStateUpdated) {
      chrome.webNavigation.onHistoryStateUpdated.addListener(
        function (details) {
          if (details.frameId !== 0) return;
          const matchCfg = getConfigForUrl(details.url);
          if (matchCfg) {
            setTimeout(() => {
              injectCSS(details.tabId, matchCfg);
              injectJS(details.tabId, matchCfg);
            }, 700);
          } else {
            const domainCfg = getSameDomainConfig(details.url);
            if (domainCfg)
              setTimeout(() => removeCSS(details.tabId, domainCfg), 700);
          }
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
