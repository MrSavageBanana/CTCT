// ============================================================
//  Vivaldi Mod — YouTube Shorts Restrictor (CSS JIT Version)
//  File: custom.js  (place in /opt/vivaldi/resources/vivaldi/)
//  Created by Gemini milobowler, :fixed with Claude. Account: Milobowler
// ============================================================

(function () {
  'use strict';

  function shortsRestrictor() {
    if (window.__yt_shorts_restrictor) return;
    window.__yt_shorts_restrictor = true;

    // ── CSS: visual dim for ALL blocked elements ──────────────────────
    //
    // CSS handles the comment panel interactions (like, dislike, reply,
    // comment box) purely via pointer-events + opacity — this stays
    // exactly as-is and is not touched by the click interceptor below.
    // ─────────────────────────────────────────────────────────────────
    const style = document.createElement('style');
    style.textContent = `
      like-button-view-model button,
      dislike-button-view-model button,
      #navigation-button-up button,
      #navigation-button-down button,
      ytd-comment-engagement-bar ytd-toggle-button-renderer#like-button button,
      ytd-comment-engagement-bar ytd-toggle-button-renderer#dislike-button button,
      ytd-comment-engagement-bar ytd-button-renderer#reply-button-end button,
      ytd-comment-simplebox-renderer {
        pointer-events: none !important;
        opacity: 0.35 !important;
        cursor: not-allowed !important;
      }
    `;
    document.documentElement.appendChild(style);

    // ── Click interceptor for VIDEO controls only ─────────────────────
    //
    // CSS pointer-events:none stops direct clicks but YouTube attaches
    // its handlers to ANCESTOR elements, so the click event still
    // propagates up and fires them.
    //
    // Fix: a single capturing listener at the document root that walks
    // the event's composed path (works through shadow DOM too) and kills
    // any click that passes through a video-control ancestor — before
    // YouTube's JS ever sees it.
    //
    // The comment panel is deliberately excluded: CSS alone is sufficient
    // there since those buttons are standard DOM with no parent handlers.
    // ─────────────────────────────────────────────────────────────────
    const VIDEO_CONTROL_SELECTORS = [
      'like-button-view-model',
      'dislike-button-view-model',
      '#navigation-button-up',
      '#navigation-button-down',
    ];

    function isVideoControl(el) {
      while (el && el !== document) {
        for (const sel of VIDEO_CONTROL_SELECTORS) {
          try {
            if (el.matches && el.matches(sel)) return true;
          } catch (e) {}
        }
        el = el.parentElement || (el.getRootNode && el.getRootNode().host) || null;
      }
      return false;
    }

    document.addEventListener('click', function (e) {
      // composedPath() gives the full path including through shadow roots
      const path = e.composedPath ? e.composedPath() : [e.target];
      for (const node of path) {
        if (node.nodeType !== 1) continue; // elements only
        if (isVideoControl(node)) {
          e.preventDefault();
          e.stopImmediatePropagation();
          return;
        }
      }
    }, true /* capture — runs before any YouTube handler */);

    // ── Block keyboard navigation between shorts ──────────────────────
    const NAV_KEYS = new Set(['ArrowUp', 'ArrowDown', 'PageUp', 'PageDown']);

    function blockNavKeys(e) {
      const tag = e.target ? e.target.tagName.toUpperCase() : '';
      if (tag === 'INPUT' || tag === 'TEXTAREA' || (e.target && e.target.isContentEditable)) return;
      if (NAV_KEYS.has(e.key)) {
        e.stopImmediatePropagation();
        e.preventDefault();
      }
    }

    // ── Block scroll navigation between shorts ────────────────────────
    function isInsideComments(el) {
      while (el) {
        if (el.tagName === 'YTD-ENGAGEMENT-PANEL-SECTION-LIST-RENDERER') return true;
        el = el.parentElement;
      }
      return false;
    }

    function blockScroll(e) {
      if (isInsideComments(e.target)) return;
      e.stopImmediatePropagation();
      e.preventDefault();
    }

    document.addEventListener('keydown', blockNavKeys, true);
    document.addEventListener('wheel', blockScroll, { capture: true, passive: false });
  }

  // ── Injection logic ───────────────────────────────────────────────
  function injectIntoTab(tabId) {
    chrome.scripting.executeScript({
      target: { tabId: tabId },
      func: shortsRestrictor,
      world: 'MAIN',
    }).catch(() => {});
  }

  chrome.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
    const url = tab.url || changeInfo.url || '';
    if (!url || !/youtube\.com\/shorts\//.test(url)) return;
    if (changeInfo.status === 'loading' || changeInfo.status === 'complete') {
      injectIntoTab(tabId);
    }
  });

  if (chrome.webNavigation) {
    chrome.webNavigation.onHistoryStateUpdated.addListener(
      (details) => {
        if (/youtube\.com\/shorts\//.test(details.url)) {
          injectIntoTab(details.tabId);
        }
      },
      { url: [{ hostContains: 'youtube.com' }] }
    );
  }

})();
