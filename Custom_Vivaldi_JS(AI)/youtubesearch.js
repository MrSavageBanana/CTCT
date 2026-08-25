// ==============================================================
//  YouTube Search Pager — Vivaldi custom.js mod
//  Paginates YouTube search results and hides injected junk.
//  created with Claude. Account: Amy
// ==============================================================

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
    console.log("YT-SearchPager.js: " + msg + " at " + ts());
  }

  function isYouTube(url) {
    return typeof url === "string" && url.includes(DOMAIN);
  }

  // ── Page-world script ─────────────────────────────────────────
  //
  //  Injected via executeScript (world: MAIN) on every navigation
  //  to a YouTube tab.  Must be self-contained — no references to
  //  anything in the outer background-script scope.
  //
  //  Lifecycle vs. youtubeNU.js's FLAG guard:
  //    youtubeNU's pageScript uses window[FLAG] = true to run once
  //    per document.  The pager CANNOT do that — it must teardown
  //    the old instance and re-initialise on every SPA navigation.
  //    Instead we store the teardown function on window so that the
  //    next injection can call it before setting up a fresh pager.
  // ──────────────────────────────────────────────────────────────
  function pageScript() {
    // ── Teardown any previous instance ───────────────────────────
    if (typeof window.__ytSearchPagerTeardown === "function") {
      window.__ytSearchPagerTeardown();
      window.__ytSearchPagerTeardown = null;
    }

    // ── Constants ─────────────────────────────────────────────────
    var SETTLE_MS = 700; // wait after last mutation before capturing
    var SETUP_DELAY = 400; // retry interval if container not found yet

    // Only these element types are real, pageable search results.
    var REAL_TAGS = new Set([
      "ytd-video-renderer",
      "ytd-channel-renderer",
      "ytd-playlist-renderer",
      "ytd-radio-renderer",
    ]);

    // These are always hidden — YouTube injects them between real results.
    var INJECTED_TAGS = new Set([
      "ytd-shelf-renderer",
      "ytd-vertical-list-renderer",
      "ytd-horizontal-card-list-renderer",
      "ytd-ad-slot-renderer",
      "ytd-banner-promo-renderer",
      "ytd-statement-banner-renderer",
    ]);

    // Shorts shelf rows — NOT always hidden; they belong to the page that
    // owns the real results around them.
    var SHELF_MODEL_TAG = "grid-shelf-view-model";

    // ── State ─────────────────────────────────────────────────────
    var pages = [];
    var currentPage = -1;
    var container = null;
    var bar = null;
    var mutObs = null;
    var settleTimer = null;
    var setupTimer = null;
    var capturing = false;
    var known = new Set();

    // ── URL helpers ───────────────────────────────────────────────

    function onSearchPage() {
      var p = location.pathname;
      return (
        p === "/results" ||
        /^\/@[^/]+\/search$/.test(p) ||
        /^\/c\/[^/]+\/search$/.test(p) ||
        /^\/user\/[^/]+\/search$/.test(p)
      );
    }

    // ── DOM helpers ───────────────────────────────────────────────

    function findContainer() {
      return (
        document.querySelector(
          "ytd-search ytd-item-section-renderer #contents",
        ) ||
        document.querySelector(
          "ytd-browse ytd-item-section-renderer #contents",
        ) ||
        null
      );
    }

    function isRealResult(el) {
      return REAL_TAGS.has(el.tagName.toLowerCase());
    }
    function isInjected(el) {
      return INJECTED_TAGS.has(el.tagName.toLowerCase());
    }
    function isShelfModel(el) {
      return el.tagName.toLowerCase() === SHELF_MODEL_TAG;
    }

    function getCont() {
      if (!container) return null;
      return container.querySelector(":scope > ytd-continuation-item-renderer");
    }
    function hideCont() {
      var c = getCont();
      if (c) c.style.display = "none";
    }
    function showCont() {
      var c = getCont();
      if (!c) return false;
      c.style.display = "";
      requestAnimationFrame(function () {
        c.scrollIntoView({ behavior: "smooth", block: "end" });
      });
      return true;
    }

    // Always hide injected elements — called on every mutation.
    function hideInjected() {
      if (!container) return;
      Array.from(container.children).forEach(function (el) {
        if (isInjected(el)) el.style.display = "none";
      });
    }

    // ── SVG icon builder (avoids innerHTML / TrustedHTML CSP) ─────

    function makeSvg(paths) {
      var NS = "http://www.w3.org/2000/svg";
      var svg = document.createElementNS(NS, "svg");
      svg.setAttribute("height", "24");
      svg.setAttribute("viewBox", "0 0 24 24");
      svg.setAttribute("width", "24");
      svg.setAttribute("focusable", "false");
      for (var i = 0; i < paths.length; i++) {
        var path = document.createElementNS(NS, "path");
        path.setAttribute("d", paths[i]);
        path.setAttribute("fill", "currentColor");
        svg.appendChild(path);
      }
      return svg;
    }

    var PATH_L = "M15.41 7.41 14 6l-6 6 6 6 1.41-1.41L10.83 12z";
    var PATH_R = "M10 6 8.59 7.41 13.17 12l-4.58 4.59L10 18l6-6z";

    // ── Batch capture ─────────────────────────────────────────────

    function captureBatch() {
      if (!container) return;

      var allChildren = Array.from(container.children);

      // Fresh real results not yet assigned to any page.
      var fresh = allChildren.filter(function (el) {
        return isRealResult(el) && !known.has(el);
      });

      hideInjected();

      if (fresh.length === 0) {
        capturing = false;
        hideCont();
        renderBar();
        return;
      }

      var wasAdvancing = capturing && pages.length > 0;
      capturing = false;

      var firstIdx = allChildren.indexOf(fresh[0]);
      var lastIdx = allChildren.indexOf(fresh[fresh.length - 1]);

      var batch = [];

      // Scan backwards from firstIdx: claim any shelf rows that sit in
      // the gap between the previous page's last element and this batch.
      for (var i = firstIdx - 1; i >= 0; i--) {
        var el = allChildren[i];
        if (known.has(el) || !isShelfModel(el)) break;
        batch.unshift(el);
        known.add(el);
      }

      // Scan forward through [firstIdx, lastIdx], plus any trailing shelf
      // rows immediately after the last fresh real result.
      for (var i = firstIdx; i < allChildren.length; i++) {
        var el = allChildren[i];

        if (known.has(el)) {
          if (i > lastIdx) break;
          continue;
        }

        if (i <= lastIdx) {
          if (isRealResult(el) || isShelfModel(el)) {
            batch.push(el);
            known.add(el);
          }
        } else {
          if (isShelfModel(el)) {
            batch.push(el);
            known.add(el);
          } else {
            break;
          }
        }
      }

      pages.push(batch);

      if (currentPage === -1) {
        currentPage = 0;
      } else if (wasAdvancing) {
        currentPage = pages.length - 1;
      }

      showPage(currentPage);
      hideCont();
      if (wasAdvancing) scrollToTop();
      renderBar();
    }

    // ── Page display ──────────────────────────────────────────────

    function showPage(idx) {
      pages.forEach(function (batch, i) {
        var show = i === idx;
        batch.forEach(function (el) {
          el.style.display = show ? "" : "none";
        });
      });
    }

    // ── Navigation ────────────────────────────────────────────────

    function goNext() {
      if (capturing) return;
      if (currentPage < pages.length - 1) {
        currentPage++;
        showPage(currentPage);
        scrollToTop();
        renderBar();
      } else {
        if (showCont()) {
          capturing = true;
          renderBar();
          clearTimeout(settleTimer);
          settleTimer = setTimeout(captureBatch, SETTLE_MS * 4);
        }
      }
    }

    function goPrev() {
      if (currentPage <= 0 || capturing) return;
      currentPage--;
      showPage(currentPage);
      scrollToTop();
      renderBar();
    }

    function scrollToTop() {
      var anchor =
        (container && container.closest("ytd-item-section-renderer")) ||
        container ||
        document.body;
      anchor.scrollIntoView({ behavior: "smooth", block: "start" });
    }

    // ── MutationObserver ──────────────────────────────────────────

    function onMutation(mutations) {
      hideInjected();

      if (!capturing) {
        hideCont();
        return;
      }

      var gotNew = false;
      for (var i = 0; i < mutations.length; i++) {
        var added = mutations[i].addedNodes;
        for (var j = 0; j < added.length; j++) {
          var node = added[j];
          if (
            node.nodeType === 1 &&
            !known.has(node) &&
            (isRealResult(node) || isShelfModel(node))
          ) {
            gotNew = true;
          }
        }
      }

      if (gotNew) {
        clearTimeout(settleTimer);
        settleTimer = setTimeout(captureBatch, SETTLE_MS);
      }
    }

    // ── Pagination bar ────────────────────────────────────────────

    function makeBtn(id, pathD) {
      var btn = document.createElement("button");
      btn.id = id;
      btn.appendChild(makeSvg([pathD]));
      btn.setAttribute(
        "aria-label",
        id === "yt-pg-prev" ? "Previous page" : "Next page",
      );
      btn.style.cssText = [
        "display:flex",
        "align-items:center",
        "justify-content:center",
        "width:40px",
        "height:40px",
        "border-radius:50%",
        "border:none",
        "background:transparent",
        "color:var(--yt-spec-text-primary,#0f0f0f)",
        "cursor:pointer",
        "transition:background 120ms ease,opacity 150ms ease",
        "outline:none",
        "padding:0",
        "flex-shrink:0",
      ].join(";");

      var hover = "var(--yt-spec-10-percent-layer,rgba(0,0,0,.08))";
      var press = "var(--yt-spec-10-percent-layer,rgba(0,0,0,.14))";

      btn.addEventListener("mouseenter", function () {
        if (!btn.disabled) btn.style.background = hover;
      });
      btn.addEventListener("mouseleave", function () {
        btn.style.background = "transparent";
      });
      btn.addEventListener("mousedown", function () {
        if (!btn.disabled) btn.style.background = press;
      });
      btn.addEventListener("mouseup", function () {
        btn.style.background = hover;
      });

      return btn;
    }

    function buildBar() {
      var wrap = document.createElement("div");
      wrap.id = "yt-pager";
      wrap.style.cssText = [
        "display:flex",
        "align-items:center",
        "justify-content:center",
        "gap:4px",
        "padding:16px 24px 32px",
        'font-family:"Roboto","Arial",sans-serif',
      ].join(";");

      var prev = makeBtn("yt-pg-prev", PATH_L);

      var lbl = document.createElement("span");
      lbl.id = "yt-pg-lbl";
      lbl.style.cssText = [
        "font-size:14px",
        "font-weight:500",
        "line-height:20px",
        "color:var(--yt-spec-text-primary,#0f0f0f)",
        "min-width:88px",
        "text-align:center",
        "user-select:none",
        "letter-spacing:0.01em",
      ].join(";");

      var next = makeBtn("yt-pg-next", PATH_R);

      prev.addEventListener("click", goPrev);
      next.addEventListener("click", goNext);

      wrap.appendChild(prev);
      wrap.appendChild(lbl);
      wrap.appendChild(next);

      return wrap;
    }

    function attachBar() {
      if (bar || !container) return;
      bar = buildBar();
      var section = container.closest("ytd-item-section-renderer");
      var ref = section || container;
      if (ref.parentNode) ref.parentNode.insertBefore(bar, ref.nextSibling);
    }

    function setBtn(btn, enabled) {
      btn.disabled = !enabled;
      btn.style.opacity = enabled ? "1" : "0.38";
      btn.style.pointerEvents = enabled ? "auto" : "none";
      btn.style.cursor = enabled ? "pointer" : "default";
    }

    function renderBar() {
      if (!bar) return;

      var prev = bar.querySelector("#yt-pg-prev");
      var next = bar.querySelector("#yt-pg-next");
      var lbl = bar.querySelector("#yt-pg-lbl");

      if (capturing) {
        setBtn(prev, false);
        setBtn(next, false);
        lbl.textContent = "Loading\u2026";
        return;
      }

      setBtn(prev, currentPage > 0);
      setBtn(next, currentPage < pages.length - 1 || !!getCont());
      lbl.textContent = "Page " + (currentPage + 1);
    }

    // ── Setup / Teardown ──────────────────────────────────────────

    function setup() {
      if (!onSearchPage()) {
        teardown();
        return;
      }

      container = findContainer();
      if (!container) {
        // Container not ready yet — retry.
        setupTimer = setTimeout(setup, SETUP_DELAY);
        return;
      }

      pages = [];
      currentPage = -1;
      capturing = true;
      known.clear();

      attachBar();

      if (mutObs) mutObs.disconnect();
      mutObs = new MutationObserver(onMutation);
      mutObs.observe(container, { childList: true });

      var existing = Array.from(container.children).filter(isRealResult);
      if (existing.length > 0) {
        settleTimer = setTimeout(captureBatch, SETTLE_MS);
      }
    }

    function teardown() {
      clearTimeout(setupTimer);
      clearTimeout(settleTimer);

      if (mutObs) {
        mutObs.disconnect();
        mutObs = null;
      }
      if (container) {
        Array.from(container.children).forEach(function (el) {
          el.style.display = "";
        });
      }
      if (bar) {
        bar.remove();
        bar = null;
      }

      container = null;
      pages = [];
      currentPage = -1;
      capturing = false;
      known.clear();
    }

    // ── Register teardown and start ───────────────────────────────
    //
    //  Store teardown so the NEXT injection (SPA nav) can call it
    //  before re-initialising.  This replaces the yt-navigate-finish
    //  listener used by the original Tampermonkey script — the Vivaldi
    //  background already handles navigation events and fires a fresh
    //  injection on each SPA nav.
    // ─────────────────────────────────────────────────────────────
    window.__ytSearchPagerTeardown = teardown;
    setup();
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
        args: [],
      })
      .catch(function (e) {
        LOG("JS inject failed: " + e);
      });
  }

  // ── Navigation listeners ──────────────────────────────────────
  //
  //  Mirrors the pattern in youtubeNU.js:
  //
  //    onUpdated (complete)     — full page load; DOM is ready.
  //    onHistoryStateUpdated    — SPA pushState (clicking links).
  //                               400ms delay matches youtubeNU.js;
  //                               setup() retries internally if the
  //                               container isn't stamped yet.
  //
  //  No CSS pre-injection needed here — the pager uses only inline
  //  styles, so there is nothing to insert before first paint.
  // ──────────────────────────────────────────────────────────────
  function attachListeners() {
    // Full page load — page is done, DOM is available.
    if (chrome.tabs && chrome.tabs.onUpdated) {
      chrome.tabs.onUpdated.addListener(function (tabId, changeInfo, tab) {
        if (changeInfo.status === "complete" && isYouTube(tab.url)) {
          LOG("onUpdated complete — " + tab.url);
          injectJS(tabId, "page load complete");
        }
      });
    }

    // SPA navigation — YouTube pushed a new URL without a real page load.
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

  // ── Bootstrap (wait for Chrome APIs like youtubeNU.js does) ───

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
