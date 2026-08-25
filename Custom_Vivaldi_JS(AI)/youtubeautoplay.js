// ==============================================================
//  YouTube – Force Autoplay Off — Vivaldi custom.js mod
//  created with Claude. Account: Burhan Ra'if Kouri
// ==============================================================

// created with Claude. Account: Burhan Ra'if Kouri
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
  function LOG(msg) {
    console.log("YT-AutoplayOff.js: " + msg + " at " + ts());
  }

  // ── Page-world script ─────────────────────────────────────────
  //
  // Injected via executeScript (world: MAIN) after the page loads.
  // Watches .ytp-autonav-toggle-button and clicks it off whenever
  // YouTube turns autoplay back on.
  //
  // The FLAG guard means this setup block only ever runs ONCE per
  // document — on a full page reload the document is fresh so FLAG
  // is unset and setup runs; on SPA navigation the document persists
  // so FLAG stays set and executeScript re-injections are no-ops.
  // Actual SPA enforcement is handled by the yt-page-data-updated
  // listener and the URL-watching MutationObserver set up below.
  //
  // Must be self-contained — no outer-scope references.
  // ──────────────────────────────────────────────────────────────
  function pageScript() {
    var FLAG = "__ytAutoplayOffActive";
    if (window[FLAG]) return;
    window[FLAG] = true;

    var btnObserver = null;

    function enforce() {
      var btn = document.querySelector(".ytp-autonav-toggle-button");
      if (!btn) return; // not a watch page, nothing to do

      // Turn it off immediately if YouTube already has it on
      if (btn.getAttribute("aria-checked") === "true") {
        btn.click();
        console.log(
          "YT-AutoplayOff.js: Autoplay clicked off at " +
            new Date().toLocaleTimeString("en-GB"),
        );
      }

      // Re-attach attribute observer to the (possibly new) button.
      // Disconnecting first is safe even if btnObserver is null.
      if (btnObserver) btnObserver.disconnect();
      btnObserver = new MutationObserver(function () {
        if (btn.getAttribute("aria-checked") === "true") {
          btn.click();
          console.log(
            "YT-AutoplayOff.js: YouTube re-enabled autoplay — clicked off at " +
              new Date().toLocaleTimeString("en-GB"),
          );
        }
      });
      btnObserver.observe(btn, {
        attributes: true,
        attributeFilter: ["aria-checked"],
      });
    }

    // yt-page-data-updated fires in the page world after every SPA navigation
    // once YouTube has finished populating the new page's data — the video
    // player (and its autoplay button) are ready at this point.
    window.addEventListener("yt-page-data-updated", enforce);

    // Belt-and-suspenders: also run on the initial load in case the event
    // already fired before we registered, or fires late.
    setTimeout(function () {
      enforce();
    }, 500);
    setTimeout(function () {
      enforce();
    }, 1500);

    // URL-watching MutationObserver — backup for SPA nav in case
    // yt-page-data-updated is delayed or fires before the button exists.
    var lastUrl = location.href;
    new MutationObserver(function () {
      if (location.href !== lastUrl) {
        lastUrl = location.href;
        // Short delay lets the new page's player DOM settle
        setTimeout(enforce, 800);
      }
    }).observe(document.documentElement, { childList: true, subtree: true });

    console.log("YT-AutoplayOff.js: Active");
  }

  // ── Extension-world helpers ───────────────────────────────────

  function injectJS(tabId, reason) {
    if (!chrome.scripting) return;
    LOG("Injecting page script (" + reason + ")");
    chrome.scripting
      .executeScript({
        target: { tabId: tabId, allFrames: false },
        world: "MAIN",
        func: pageScript,
        args: [],
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
    // onUpdated (complete) — fires when a fresh page finishes loading.
    // The document is new here, so the FLAG is unset and pageScript
    // will run its full setup.
    if (chrome.tabs && chrome.tabs.onUpdated) {
      chrome.tabs.onUpdated.addListener(function (tabId, changeInfo, tab) {
        if (changeInfo.status === "complete" && isYouTube(tab.url)) {
          LOG("onUpdated complete — " + tab.url);
          injectJS(tabId, "page load complete");
        }
      });
    }

    // onHistoryStateUpdated — SPA pushState (clicking links on YouTube).
    // Because the document persists across SPA navigation, the FLAG guard
    // in pageScript makes these re-injections no-ops. The real work is done
    // by the yt-page-data-updated listener and URL-watcher set up on first
    // injection. We still call injectJS here for the edge case where the
    // initial onUpdated injection was missed.
    if (chrome.webNavigation && chrome.webNavigation.onHistoryStateUpdated) {
      chrome.webNavigation.onHistoryStateUpdated.addListener(
        function (details) {
          if (details.frameId !== 0) return;
          if (!isYouTube(details.url)) return;
          LOG("onHistoryStateUpdated — " + details.url);
          setTimeout(function () {
            injectJS(details.tabId, "SPA navigation");
          }, 400);
        },
      );
    }

    LOG("Active — monitoring " + DOMAIN);
  }

  // ── Startup ───────────────────────────────────────────────────
  // Poll until Vivaldi's Chrome APIs are ready (same pattern as youtubeNU.js).
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
