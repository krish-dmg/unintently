/**
 * Unintently Chrome Extension - Content Script
 * Version: 2.0.0
 * Extracts ChatGPT conversations and generates Unintently handwritten assignment payloads.
 */

(function () {
  "use strict";

  const BUTTON_ID = "unintently-export-btn";
  const FLOATING_BUTTON_ID = "unintently-floating-btn";
  const MODAL_ID = "unintently-modal-overlay";

  let isConverting = false;

  // SVG Icons (Strictly NO emojis)
  const ICONS = {
    doc: `<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m2.25 0H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z" />
    </svg>`,
    convert: `<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" d="M19.5 12c0-1.232-.046-2.453-.138-3.662a4.006 4.006 0 00-3.7-3.7 48.678 48.678 0 00-7.324 0 4.006 4.006 0 00-3.7 3.7c-.017.22-.032.441-.046.662M19.5 12l3-3m-3 3l-3-3m-12 3c0 1.232.046 2.453.138 3.662a4.006 4.006 0 003.7 3.7 48.656 48.656 0 007.324 0 4.006 4.006 0 003.7-3.7c.017-.22.032-.441.046-.662M4.5 12l3 3m-3-3l-3 3" />
    </svg>`,
    copy: `<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" d="M15.666 3.888A2.25 2.25 0 0013.5 2.25h-3c-1.03 0-1.9.693-2.166 1.638m7.332 0c.055.194.084.4.084.612v0a.75.75 0 01-.75.75H9a.75.75 0 01-.75-.75v0c0-.212.03-.418.084-.612m7.332 0c.646.049 1.288.11 1.927.184 1.1.128 1.907 1.077 1.907 2.185V19.5a2.25 2.25 0 01-2.25 2.25H6.75A2.25 2.25 0 014.5 19.5V6.257c0-1.108.806-2.057 1.907-2.185a48.208 48.208 0 011.927-.184" />
    </svg>`,
    check: `<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12.75l6 6 9-13.5" />
    </svg>`,
    close: `<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
    </svg>`
  };

  /**
   * Copy text helper with fallback
   */
  async function copyToClipboard(text) {
    try {
      if (navigator.clipboard && window.isSecureContext) {
        await navigator.clipboard.writeText(text);
        return true;
      }
    } catch (_) {}

    try {
      const textarea = document.createElement("textarea");
      textarea.value = text;
      textarea.style.position = "fixed";
      textarea.style.left = "-9999px";
      textarea.style.top = "-9999px";
      document.body.appendChild(textarea);
      textarea.focus();
      textarea.select();
      const successful = document.execCommand("copy");
      document.body.removeChild(textarea);
      return successful;
    } catch (e) {
      console.info("[Unintently] Clipboard copy note:", e);
      return false;
    }
  }

  /**
   * Extract conversation title cleanly
   */
  function extractConversationTitle() {
    let title = document.title || "ChatGPT Assignment";
    title = title.replace(/\s*-\s*ChatGPT$/i, "").trim();
    if (!title || title.toLowerCase() === "chatgpt" || title.toLowerCase() === "new chat") {
      const firstHeading = document.querySelector("h1");
      if (firstHeading && firstHeading.textContent.trim()) {
        title = firstHeading.textContent.trim();
      } else {
        title = "Assignment " + new Date().toLocaleDateString();
      }
    }
    return title;
  }

  /**
   * Helper to clean message text from live DOM elements
   */
  function cleanElementText(el) {
    if (!el) return "";
    let raw = el.innerText || el.textContent || "";
    if (!raw) return "";

    // Remove action button texts from ChatGPT UI
    let cleaned = raw
      .replace(/^(Copy|Edit|Read aloud|Good response|Bad response|Regenerate)\s*$/gim, "")
      .trim();

    return cleaned;
  }

  /**
   * Identifies all distinct conversation turns in ChatGPT across DOM revisions
   */
  function getTurnContainers() {
    const selectors = [
      'article',
      '[data-testid^="conversation-turn-"]',
      'div.group\\/conversation-turn',
      'div[class*="conversation-turn"]',
      '[data-message-author-role]'
    ];

    let allMatches = [];
    selectors.forEach(sel => {
      try {
        const found = Array.from(document.querySelectorAll(sel));
        allMatches.push(...found);
      } catch (_) {}
    });

    if (allMatches.length === 0) return [];

    // Filter to retain only unique, topmost turn containers
    const topTurns = [];
    allMatches.forEach(el => {
      const isContained = topTurns.some(t => t.contains(el));
      if (!isContained) {
        for (let i = topTurns.length - 1; i >= 0; i--) {
          if (el.contains(topTurns[i])) {
            topTurns.splice(i, 1);
          }
        }
        topTurns.push(el);
      }
    });

    // Sort strictly in document reading order
    topTurns.sort((a, b) => {
      const pos = a.compareDocumentPosition(b);
      if (pos & Node.DOCUMENT_POSITION_FOLLOWING) return -1;
      if (pos & Node.DOCUMENT_POSITION_PRECEDING) return 1;
      return 0;
    });

    return topTurns;
  }

  /**
   * Accurately determines if a turn is from the user or assistant
   */
  function detectTurnRole(el) {
    if (!el) return "unknown";

    // 1. Explicit author role attribute
    const roleAttr = el.getAttribute("data-message-author-role") ||
                     el.querySelector("[data-message-author-role]")?.getAttribute("data-message-author-role");
    if (roleAttr === "user") return "user";
    if (roleAttr === "assistant") return "assistant";

    // 2. Screen-reader / accessibility headings (standard in modern ChatGPT)
    const headings = Array.from(el.querySelectorAll('h5, h6, [class*="sr-only"], span, div'));
    for (const h of headings) {
      const text = (h.textContent || "").trim().toLowerCase();
      if (text.startsWith("you said") || text === "you" || text === "you:") return "user";
      if (text.startsWith("chatgpt said") || text === "chatgpt" || text === "chatgpt:") return "assistant";
    }

    // 3. Assistant formatting markers (markdown/prose containers are exclusively used for ChatGPT outputs)
    if (el.querySelector(".markdown, [class*='markdown'], [class*='prose']")) {
      return "assistant";
    }

    // 4. User message attributes and bubble classes
    if (
      el.querySelector('[data-testid*="user"]') ||
      el.getAttribute("data-testid")?.includes("user") ||
      el.classList.contains("user-message") ||
      el.querySelector('[class*="bg-token-message-surface"]')
    ) {
      return "user";
    }

    // 5. Assistant action controls (Copy, Regenerate, Read aloud)
    if (el.querySelector('button[aria-label*="Copy"], [data-testid*="copy"], button[aria-label*="Read aloud"]')) {
      return "assistant";
    }

    return "unknown";
  }

  /**
   * Extracts clean message text from a turn element
   */
  function extractTurnText(el, role) {
    if (!el) return "";
    const clone = el.cloneNode(true);

    // Remove screen-reader headers
    clone.querySelectorAll('h5, h6, [class*="sr-only"]').forEach(h => {
      const t = (h.textContent || "").toLowerCase();
      if (t.includes("you said") || t.includes("chatgpt said")) h.remove();
    });

    // Remove action buttons and toolbar widgets
    clone.querySelectorAll('button, svg, [role="button"], [class*="action-button"], footer').forEach(b => b.remove());

    if (role === "user") {
      const userBubble = clone.querySelector(".whitespace-pre-wrap, div[class*='whitespace-pre-wrap']");
      if (userBubble && userBubble.innerText?.trim()) {
        return userBubble.innerText.trim();
      }
    } else if (role === "assistant") {
      const md = clone.querySelector(".markdown, [class*='markdown'], [class*='prose']");
      if (md && md.innerText?.trim()) {
        return md.innerText.trim();
      }
    }

    return cleanElementText(clone);
  }

  /**
   * Extract conversation turns reliably using multi-layer detection and sequential pairing
   */
  function extractConversation() {
    const title = extractConversationTitle();
    const items = [];

    // Approach 1: Top-level turn container parsing
    const turns = getTurnContainers();
    if (turns.length > 0) {
      let currentQuestion = "";
      let currentAnswer = "";
      let lastRole = null;

      turns.forEach(turn => {
        let role = detectTurnRole(turn);
        if (role === "unknown") {
          role = (lastRole === "user") ? "assistant" : "user";
        }

        const text = extractTurnText(turn, role);
        if (!text) return;

        if (role === "user") {
          if (currentQuestion && currentAnswer) {
            items.push({
              questionNumber: items.length + 1,
              question: currentQuestion,
              answer: currentAnswer
            });
            currentQuestion = text;
            currentAnswer = "";
          } else if (currentQuestion && !currentAnswer) {
            currentQuestion += "\n\n" + text;
          } else {
            currentQuestion = text;
          }
          lastRole = "user";
        } else if (role === "assistant") {
          if (currentAnswer) {
            currentAnswer += "\n\n" + text;
          } else {
            currentAnswer = text;
          }
          lastRole = "assistant";
        }
      });

      if (currentQuestion || currentAnswer) {
        items.push({
          questionNumber: items.length + 1,
          question: currentQuestion || title,
          answer: currentAnswer || ""
        });
      }
    }

    // Approach 2: If turn containers failed, query user and assistant elements directly
    if (items.length === 0) {
      const userElements = Array.from(document.querySelectorAll('[data-message-author-role="user"]'));
      const assistantElements = Array.from(document.querySelectorAll('[data-message-author-role="assistant"], .markdown'));
      const maxLen = Math.max(userElements.length, assistantElements.length);

      for (let i = 0; i < maxLen; i++) {
        const uText = cleanElementText(userElements[i]);
        let aText = "";
        if (assistantElements[i]) {
          const md = assistantElements[i].querySelector(".markdown") || assistantElements[i];
          aText = cleanElementText(md);
        }

        if (!uText && !aText) continue;

        items.push({
          questionNumber: items.length + 1,
          question: uText || `Question ${items.length + 1}`,
          answer: aText || ""
        });
      }
    }

    // Approach 3: Fallback bubble pairing (ensures messages are NEVER all joined into a single answer)
    if (items.length === 0) {
      const bubbles = Array.from(document.querySelectorAll("main .markdown, main div.whitespace-pre-wrap, main article, main p"));
      const topBubbles = bubbles.filter((el, idx) => {
        return !bubbles.some((other, oIdx) => idx !== oIdx && other.contains(el));
      });
      topBubbles.sort((a, b) => {
        const pos = a.compareDocumentPosition(b);
        if (pos & Node.DOCUMENT_POSITION_FOLLOWING) return -1;
        if (pos & Node.DOCUMENT_POSITION_PRECEDING) return 1;
        return 0;
      });

      const pieces = topBubbles
        .map(b => cleanElementText(b))
        .filter(t => t.length > 0 && !t.match(/^(Copy|Edit|Read aloud|Regenerate|Good response|Bad response)$/i));

      for (let i = 0; i < pieces.length; i += 2) {
        const q = pieces[i];
        const a = pieces[i + 1] || "";
        items.push({
          questionNumber: items.length + 1,
          question: q,
          answer: a
        });
      }
    }

    return {
      title: title,
      items: items
    };
  }

  /**
   * Injects the Convert button into the ChatGPT composer
   */
  function injectTriggerButton() {
    if (document.getElementById(BUTTON_ID)) return;

    // Potential injection points inside ChatGPT UI
    const targets = [
      document.querySelector("form div.flex.items-center:last-child"),
      document.querySelector("form div.flex.items-center"),
      document.querySelector("#composer-background div.flex.items-center"),
      document.querySelector("form div.relative.flex"),
      document.querySelector("form div[class*='composer']"),
      document.querySelector("div[data-testid='composer-speech-button']")?.parentElement,
      document.querySelector("button[data-testid='send-button']")?.parentElement
    ];

    let targetContainer = targets.find((t) => t && t.nodeType === Node.ELEMENT_NODE);

    if (targetContainer) {
      const floating = document.getElementById(FLOATING_BUTTON_ID);
      if (floating) floating.remove();

      const btn = document.createElement("button");
      btn.id = BUTTON_ID;
      btn.type = "button";
      btn.className = "unintently-trigger-btn";
      btn.innerHTML = `${ICONS.convert}<span>Convert To Assignment</span>`;
      btn.title = "Convert ChatGPT conversation into handwritten assignment and notes";
      btn.addEventListener("click", onConvertClick);

      targetContainer.appendChild(btn);
    } else {
      if (!document.getElementById(FLOATING_BUTTON_ID)) {
        const floatBtn = document.createElement("button");
        floatBtn.id = FLOATING_BUTTON_ID;
        floatBtn.type = "button";
        floatBtn.className = "unintently-floating-btn";
        floatBtn.innerHTML = `${ICONS.convert}<span>Convert To Assignment</span>`;
        floatBtn.title = "Convert ChatGPT conversation into handwritten assignment and notes";
        floatBtn.addEventListener("click", onConvertClick);
        document.body.appendChild(floatBtn);
      }
    }
  }

  /**
   * Main convert action handler
   */
  async function onConvertClick(e) {
    e.preventDefault();
    if (isConverting) return;
    isConverting = true;

    const btn = document.getElementById(BUTTON_ID) || document.getElementById(FLOATING_BUTTON_ID);
    if (btn) {
      btn.classList.add("converting");
      btn.innerHTML = `${ICONS.convert}<span>Converting...</span>`;
    }

    try {
      const extracted = extractConversation();
      const title = extracted.title;
      const items = extracted.items;

      if (items.length === 0) {
        alert("Please start or load a ChatGPT conversation before converting.");
        return;
      }

      // Format payload for original backend (api.intently.in)
      const legacyPayload = {
        title: title,
        avatarUrl: null,
        model: "ChatGPT",
        items: items.flatMap((i) => [
          { from: "human", value: i.question },
          { from: "gpt", value: i.answer }
        ])
      };

      // Format document payload for Unintently v2
      const assignmentDoc = {
        id: "chatgpt_" + Date.now(),
        title: title,
        docType: "qa",
        heading: title,
        items: items.map((i) => ({ question: i.question, answer: i.answer })),
        generalContent: items.map((i) => `Q: ${i.question}\n\nA: ${i.answer}`).join("\n\n"),
        fontFamily: "intentlyR1",
        fontSize: 17.0,
        lineSpacing: 1.6,
        paperAsset: "assets/images/ruled1.jpg",
        hasMobileShadow: false,
        isCompleted: false,
        createdAt: new Date().toISOString(),
        source: "ChatGPT Extension v2"
      };

      let shortLink = "";
      let isCloudSynced = false;

      // Primary: Use Unintently Cloudflare Worker backend
      try {
        const storageData = await chrome.storage.local.get(["workerApiUrl"]);
        let workerUrl = storageData.workerApiUrl;
        if (!workerUrl || workerUrl.includes("localhost") || workerUrl.includes("intently.in")) {
          workerUrl = "https://unintently-backend.brksmartkraft.workers.dev";
        }

        const res = await fetch(workerUrl.replace(/\/$/, "") + "/create/chatGPTAssignments", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(assignmentDoc),
          signal: AbortSignal.timeout(8000)
        });

        if (res.ok) {
          const data = await res.json();
          if (data.shortLink || data.code) {
            shortLink = data.shortLink || `${workerUrl.replace(/\/$/, "")}/a/${data.code}`;
            isCloudSynced = true;
          }
        }
      } catch (err) {
        console.info("[Unintently] Cloudflare Worker sync fallback:", err?.message);
      }

      // Fallback: Offline local link
      if (!shortLink) {
        const localCode = "UNIN-" + Math.random().toString(36).substring(2, 8).toUpperCase();
        shortLink = `https://unintently-backend.brksmartkraft.workers.dev/a/${localCode}`;
      }

      // Persist in extension history
      try {
        const stored = (await chrome.storage.local.get("conversationDataList")) || {};
        const list = Array.isArray(stored.conversationDataList) ? stored.conversationDataList : [];
        list.unshift({
          id: assignmentDoc.id,
          title: title,
          shortlink: shortLink,
          itemCount: items.length,
          creationTime: Date.now(),
          payload: assignmentDoc
        });
        await chrome.storage.local.set({ conversationDataList: list.slice(0, 80) });
      } catch (storeErr) {
        console.info("[Unintently] Local storage save note:", storeErr);
      }

      // Show in-page Modal Dialog matching authentic reference UI
      showModalDialog({
        title: title,
        itemCount: items.length,
        shortLink: shortLink,
        isCloudSynced: isCloudSynced,
        assignmentDoc: assignmentDoc
      });
    } catch (err) {
      console.info("[Unintently] Conversion note:", err);
      alert("Error converting conversation: " + (err?.message || "Unknown error"));
    } finally {
      isConverting = false;
      if (btn) {
        btn.classList.remove("converting");
        btn.innerHTML = `${ICONS.convert}<span>Convert To Assignment</span>`;
      }
    }
  }

  /**
   * In-page modal dialog rendering - Matches authentic reference screenshot
   */
  function showModalDialog(data) {
    const existing = document.getElementById(MODAL_ID);
    if (existing) existing.remove();

    const overlay = document.createElement("div");
    overlay.id = MODAL_ID;
    overlay.className = "unintently-overlay";

    const jsonString = JSON.stringify(data.assignmentDoc, null, 2);
    const linkUrl = data.shortLink;

    overlay.innerHTML = `
      <div class="unintently-modal-dialog" role="dialog" aria-modal="true">
        <button class="unintently-modal-close-btn" id="unintently-close-modal" aria-label="Close dialog">
          ${ICONS.close}
        </button>

        <div class="unintently-modal-brand-title" style="display: flex; align-items: center; justify-content: center; gap: 8px;">
          <img src="${chrome.runtime.getURL('logo.png')}" width="24" height="24" style="border-radius: 6px; display: inline-block;" alt="Unintently" />
          <span>Unintently</span>
        </div>
        <div class="unintently-modal-heading">Scan QR</div>
        <div class="unintently-modal-subtitle">Scan this on mobile to open assignment</div>

        <div class="unintently-qr-box">
          <canvas id="unintently-qr-canvas" width="200" height="200"></canvas>
        </div>

        <div class="unintently-divider-row">
          <div class="unintently-divider-line"></div>
          <span class="unintently-divider-label">or share this assignment link</span>
          <div class="unintently-divider-line"></div>
        </div>

        <div class="unintently-link-box">
          <div class="unintently-link-text" id="unintently-link-val">${escapeHtml(linkUrl)}</div>
          <button type="button" class="unintently-link-copy-btn" id="unintently-copy-link-btn" title="Copy Link">
            ${ICONS.copy}
          </button>
        </div>

        <div class="unintently-secondary-action">
          <button type="button" class="unintently-btn-payload" id="unintently-copy-payload-btn">
            ${ICONS.doc}<span>Copy Assignment Payload (JSON)</span>
          </button>
        </div>
      </div>
    `;

    document.body.appendChild(overlay);

    // Render clean, high-contrast QR Code using UnintentlyQR
    const canvas = document.getElementById("unintently-qr-canvas");
    if (canvas && window.UnintentlyQR) {
      try {
        window.UnintentlyQR.toCanvas(canvas, linkUrl, { width: 200, margin: 2 }, function (err) {
          if (err) {
            console.info("[Unintently] QR canvas fallback note:", err);
          }
        });
      } catch (qrEx) {
        console.info("[Unintently] QR rendering note:", qrEx);
      }
    }

    // Modal Events
    const closeBtn = document.getElementById("unintently-close-modal");
    closeBtn.addEventListener("click", () => overlay.remove());

    overlay.addEventListener("click", (evt) => {
      if (evt.target === overlay) overlay.remove();
    });

    document.addEventListener("keydown", function escHandler(evt) {
      if (evt.key === "Escape") {
        overlay.remove();
        document.removeEventListener("keydown", escHandler);
      }
    });

    // Copy Link button
    const copyLinkBtn = document.getElementById("unintently-copy-link-btn");
    copyLinkBtn.addEventListener("click", async () => {
      const ok = await copyToClipboard(linkUrl);
      if (ok) {
        copyLinkBtn.innerHTML = ICONS.check;
        setTimeout(() => {
          copyLinkBtn.innerHTML = ICONS.copy;
        }, 1500);
      }
    });

    // Copy Payload button
    const copyPayloadBtn = document.getElementById("unintently-copy-payload-btn");
    copyPayloadBtn.addEventListener("click", async () => {
      const ok = await copyToClipboard(jsonString);
      if (ok) {
        copyPayloadBtn.classList.add("copied");
        copyPayloadBtn.innerHTML = `${ICONS.check}<span>Payload Copied to Clipboard!</span>`;
        setTimeout(() => {
          copyPayloadBtn.classList.remove("copied");
          copyPayloadBtn.innerHTML = `${ICONS.doc}<span>Copy Assignment Payload (JSON)</span>`;
        }, 1800);
      }
    });
  }

  function escapeHtml(str) {
    if (!str) return "";
    return String(str)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;");
  }

  // Periodic and Mutation-based observer
  function setupObserver() {
    injectTriggerButton();

    const observer = new MutationObserver(() => {
      injectTriggerButton();
    });

    observer.observe(document.body, { childList: true, subtree: true });

    setInterval(() => {
      injectTriggerButton();
    }, 1000);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", setupObserver);
  } else {
    setupObserver();
  }
})();
