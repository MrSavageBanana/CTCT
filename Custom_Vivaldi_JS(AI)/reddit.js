// created with Claude. Account: Burhan Ra'if Kouri
// ============================================================
// Reddit Interaction Disabler — Vivaldi custom.js
// Blocks: upvote, downvote, reply, award (posts + comments)
// ============================================================
(function () {
    'use strict';

    const LOG = s => console.log('[Reddit Disabler BG]', s);
    const URL_PATTERN = /^https?:\/\/www\.reddit\.com\//;

    // ── CSS injected into shadow roots at creation time ──────────────
    // Targets votes/awards which live inside shadow DOMs.
    // Using broad `button` inside known vote components as a catch-all
    // (same strategy the original script used — it worked).
    const SHADOW_CSS = `
        shreddit-vote-buttons button,
        shreddit-award-button button,
        button[aria-label*="upvote"],
        button[aria-label*="Upvote"],
        button[aria-label*="downvote"],
        button[aria-label*="Downvote"],
        button[icon-name*="upvote"],
        button[icon-name*="downvote"],
        [slot="vote-buttons"] {
            pointer-events: none !important;
            opacity: 0.35 !important;
            cursor: not-allowed !important;
        }
    `;

    // ── Shadow host components to probe for votes/awards ─────────────
    const SHADOW_HOSTS = [
        'shreddit-post',
        'shreddit-comment',
        'shreddit-comment-action-row',
        'shreddit-vote-buttons',
        'shreddit-award-button',
        'shreddit-async-loader',
    ];

    // ── Selectors run inside each shadow root ─────────────────────────
    // Mirrors the original script's working selector list.
    // `shreddit-vote-buttons button` and the bare `button` catch-all
    // are what made upvote/downvote work in the original.
    const SHADOW_VOTE_SELECTORS = [
        'button[aria-label*="upvote"]',
        'button[aria-label*="Upvote"]',
        'button[aria-label*="downvote"]',
        'button[aria-label*="Downvote"]',
        'button[icon-name*="upvote"]',
        'button[icon-name*="downvote"]',
        'shreddit-vote-buttons button',
        'button',
    ];

    // ── Inject blocking CSS into a shadow root ────────────────────────
    function injectStyleIntoShadow(shadowRoot) {
        if (shadowRoot.__redditStyleInjected) return;
        shadowRoot.__redditStyleInjected = true;
        try {
            const style = document.createElement('style');
            style.textContent = SHADOW_CSS;
            shadowRoot.prepend(style);
        } catch (e) {}
    }

    // ── Imperatively disable a single element ─────────────────────────
    function disableEl(el) {
        if (el.__redditDisabled) return;
        el.__redditDisabled = true;
        el.style.setProperty('pointer-events', 'none', 'important');
        el.style.setProperty('opacity', '0.35', 'important');
        el.style.setProperty('cursor', 'not-allowed', 'important');
        if ('disabled' in el) el.disabled = true;
        el.addEventListener('click', function (ev) {
            ev.preventDefault();
            ev.stopImmediatePropagation();
        }, true);
    }

    // ── Disable a textarea (comment input box) ────────────────────────
    function disableTextarea(el) {
        if (el.__redditDisabled) return;
        el.__redditDisabled = true;
        el.style.setProperty('pointer-events', 'none', 'important');
        el.style.setProperty('opacity', '0.35', 'important');
        el.style.setProperty('cursor', 'not-allowed', 'important');
        el.setAttribute('readonly', 'true');
        el.setAttribute('disabled', 'true');
        el.addEventListener('focus', function (ev) { ev.preventDefault(); el.blur(); }, true);
        el.addEventListener('click', function (ev) { ev.preventDefault(); ev.stopImmediatePropagation(); }, true);
        el.addEventListener('keydown', function (ev) { ev.preventDefault(); ev.stopImmediatePropagation(); }, true);
    }

    // ── Probe a shadow root: inject CSS + imperative selector scan ────
    function probeAndDisable(host, selectors, context) {
        if (!host || !host.shadowRoot) return;
        injectStyleIntoShadow(host.shadowRoot);
        selectors.forEach(function (sel) {
            try {
                host.shadowRoot.querySelectorAll(sel).forEach(disableEl);
            } catch (e) {}
        });
        // Recurse into nested shadow hosts
        SHADOW_HOSTS.forEach(function (tag) {
            host.shadowRoot.querySelectorAll(tag).forEach(function (nested) {
                probeAndDisable(nested, selectors, context + '>' + tag);
            });
        });
    }

    // ── Plain-DOM pass: reply buttons and comment textareas ───────────
    // The reply button has no aria-label. Identified by:
    //   • containing an SVG with icon-name="comment"
    //   • or text content of exactly "Reply" or "Comment"
    // The comment textarea is identified by id or placeholder.
    function disablePlainDomInteractions() {
        document.querySelectorAll('button').forEach(function (btn) {
            var hasSvgComment = !!btn.querySelector('svg[icon-name="comment"]');
            var text = btn.textContent.trim().toLowerCase();
            if (hasSvgComment || text === 'reply' || text === 'comment') {
                disableEl(btn);
            }
        });

        document.querySelectorAll(
            'textarea#innerTextArea, ' +
            'textarea[placeholder*="conversation"], ' +
            'textarea[placeholder*="comment"], ' +
            'textarea[placeholder*="Add a comment"]'
        ).forEach(disableTextarea);
    }

    // ── Full sweep: shadow DOM pass + plain DOM pass ──────────────────
    function fullSweep() {
        SHADOW_HOSTS.forEach(function (tag) {
            document.querySelectorAll(tag).forEach(function (host) {
                probeAndDisable(host, SHADOW_VOTE_SELECTORS, tag);
            });
        });
        disablePlainDomInteractions();
    }

    // ── Page-side script (injected via chrome.scripting MAIN world) ───
    function pageScript() {
        if (window.__redditDisablerActive) return;
        window.__redditDisablerActive = true;
        console.log('[Reddit Disabler] Activated on', location.href);

        // ---- inline copies of all helpers (must be self-contained) ---

        var SHADOW_CSS = `
            shreddit-vote-buttons button,
            shreddit-award-button button,
            button[aria-label*="upvote"],
            button[aria-label*="Upvote"],
            button[aria-label*="downvote"],
            button[aria-label*="Downvote"],
            button[icon-name*="upvote"],
            button[icon-name*="downvote"],
            [slot="vote-buttons"] {
                pointer-events: none !important;
                opacity: 0.35 !important;
                cursor: not-allowed !important;
            }
        `;

        var SHADOW_HOSTS = [
            'shreddit-post',
            'shreddit-comment',
            'shreddit-comment-action-row',
            'shreddit-vote-buttons',
            'shreddit-award-button',
            'shreddit-async-loader',
        ];

        var SHADOW_VOTE_SELECTORS = [
            'button[aria-label*="upvote"]',
            'button[aria-label*="Upvote"]',
            'button[aria-label*="downvote"]',
            'button[aria-label*="Downvote"]',
            'button[icon-name*="upvote"]',
            'button[icon-name*="downvote"]',
            'shreddit-vote-buttons button',
            'button',
        ];

        function injectStyleIntoShadow(shadowRoot) {
            if (shadowRoot.__redditStyleInjected) return;
            shadowRoot.__redditStyleInjected = true;
            try {
                var style = document.createElement('style');
                style.textContent = SHADOW_CSS;
                shadowRoot.prepend(style);
            } catch (e) {}
        }

        function disableEl(el) {
            if (el.__redditDisabled) return;
            el.__redditDisabled = true;
            el.style.setProperty('pointer-events', 'none', 'important');
            el.style.setProperty('opacity', '0.35', 'important');
            el.style.setProperty('cursor', 'not-allowed', 'important');
            if ('disabled' in el) el.disabled = true;
            el.addEventListener('click', function (ev) {
                ev.preventDefault();
                ev.stopImmediatePropagation();
            }, true);
        }

        function disableTextarea(el) {
            if (el.__redditDisabled) return;
            el.__redditDisabled = true;
            el.style.setProperty('pointer-events', 'none', 'important');
            el.style.setProperty('opacity', '0.35', 'important');
            el.style.setProperty('cursor', 'not-allowed', 'important');
            el.setAttribute('readonly', 'true');
            el.setAttribute('disabled', 'true');
            el.addEventListener('focus', function (ev) { ev.preventDefault(); el.blur(); }, true);
            el.addEventListener('click', function (ev) { ev.preventDefault(); ev.stopImmediatePropagation(); }, true);
            el.addEventListener('keydown', function (ev) { ev.preventDefault(); ev.stopImmediatePropagation(); }, true);
        }

        function probeAndDisable(host, selectors, context) {
            if (!host || !host.shadowRoot) return;
            injectStyleIntoShadow(host.shadowRoot);
            selectors.forEach(function (sel) {
                try { host.shadowRoot.querySelectorAll(sel).forEach(disableEl); } catch (e) {}
            });
            SHADOW_HOSTS.forEach(function (tag) {
                host.shadowRoot.querySelectorAll(tag).forEach(function (nested) {
                    probeAndDisable(nested, selectors, context + '>' + tag);
                });
            });
        }

        function disablePlainDomInteractions() {
            document.querySelectorAll('button').forEach(function (btn) {
                var hasSvgComment = !!btn.querySelector('svg[icon-name="comment"]');
                var text = btn.textContent.trim().toLowerCase();
                if (hasSvgComment || text === 'reply' || text === 'comment') {
                    disableEl(btn);
                }
            });

            document.querySelectorAll(
                'textarea#innerTextArea, ' +
                'textarea[placeholder*="conversation"], ' +
                'textarea[placeholder*="comment"], ' +
                'textarea[placeholder*="Add a comment"]'
            ).forEach(disableTextarea);
        }

        function fullSweep() {
            SHADOW_HOSTS.forEach(function (tag) {
                document.querySelectorAll(tag).forEach(function (host) {
                    probeAndDisable(host, SHADOW_VOTE_SELECTORS, tag);
                });
            });
            disablePlainDomInteractions();
        }

        // ---- Patch attachShadow to catch shadow roots at creation -----
        if (!Element.prototype.__redditShadowPatched) {
            Element.prototype.__redditShadowPatched = true;
            var _orig = Element.prototype.attachShadow;
            Element.prototype.attachShadow = function (init) {
                var sr = _orig.call(this, init);
                injectStyleIntoShadow(sr);
                return sr;
            };
            console.log('[Reddit Disabler] attachShadow patched');
        }

        // ---- Staggered initial sweeps --------------------------------
        setTimeout(fullSweep, 300);
        setTimeout(fullSweep, 1000);
        setTimeout(fullSweep, 3000);

        // ---- SPA navigation watcher ----------------------------------
        var lastUrl = location.href;
        new MutationObserver(function () {
            if (location.href !== lastUrl) {
                lastUrl = location.href;
                console.log('[Reddit Disabler] URL changed →', location.href);
                clearTimeout(window.__redditNavDebounce);
                window.__redditNavDebounce = setTimeout(fullSweep, 600);
            }
        }).observe(document.documentElement, { childList: true, subtree: true });

        // ---- New-content watcher (scroll / lazy load) ----------------
        var mutationDebounce = null;
        new MutationObserver(function (mutations) {
            var relevant = false;
            mutations.forEach(function (m) {
                m.addedNodes.forEach(function (node) {
                    if (node.nodeType !== 1) return;
                    var tag = (node.tagName || '').toLowerCase();
                    if (SHADOW_HOSTS.indexOf(tag) !== -1) {
                        relevant = true;
                    } else if (node.querySelector) {
                        try {
                            if (node.querySelector(SHADOW_HOSTS.join(',') + ',button,textarea')) relevant = true;
                        } catch (e) {}
                    }
                });
            });
            if (relevant) {
                clearTimeout(mutationDebounce);
                mutationDebounce = setTimeout(fullSweep, 250);
            }
        }).observe(document.documentElement, { childList: true, subtree: true });
    }

    // ── Background: inject into a Reddit tab ─────────────────────────
    function injectIntoTab(tabId) {
        if (!chrome.scripting) { LOG('chrome.scripting unavailable'); return; }
        chrome.scripting.executeScript({
            target: { tabId: tabId, allFrames: false },
            world: 'MAIN',
            func: pageScript,
        }).then(function () {
            LOG('Injected into tab ' + tabId);
        }).catch(function (e) {
            LOG('Inject failed: ' + e);
        });
    }

    function isRedditUrl(url) {
        return url && URL_PATTERN.test(url);
    }

    // ── Background: attach navigation listeners ───────────────────────
    function attachListeners() {
        LOG('Attaching listeners');

        if (chrome.tabs && chrome.tabs.onUpdated) {
            chrome.tabs.onUpdated.addListener(function (tabId, changeInfo, tab) {
                if (changeInfo.status === 'complete' && isRedditUrl(tab.url)) {
                    LOG('onUpdated complete: ' + tab.url);
                    injectIntoTab(tabId);
                }
                if (changeInfo.url && isRedditUrl(changeInfo.url)) {
                    setTimeout(function () { injectIntoTab(tabId); }, 500);
                }
            });
        }

        if (chrome.webNavigation && chrome.webNavigation.onCommitted) {
            chrome.webNavigation.onCommitted.addListener(function (details) {
                if (details.frameId !== 0) return;
                if (isRedditUrl(details.url)) {
                    setTimeout(function () { injectIntoTab(details.tabId); }, 200);
                }
            });
        }

        if (chrome.webNavigation && chrome.webNavigation.onHistoryStateUpdated) {
            chrome.webNavigation.onHistoryStateUpdated.addListener(function (details) {
                if (details.frameId !== 0) return;
                if (isRedditUrl(details.url)) {
                    setTimeout(function () { injectIntoTab(details.tabId); }, 500);
                }
            });
        }

        LOG('All listeners attached');
    }

    var attempts = 0;
    function waitForApis() {
        if (chrome && chrome.tabs && chrome.tabs.onUpdated) {
            LOG('APIs ready after ' + attempts + ' attempt(s)');
            attachListeners();
        } else if (attempts++ < 40) {
            setTimeout(waitForApis, 250);
        } else {
            LOG('Gave up waiting for chrome.tabs API');
        }
    }

    waitForApis();
})();
