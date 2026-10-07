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
      console.error("[Unintently] Clipboard copy failed:", e);
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
   * Extract user and assistant turns from ChatGPT DOM
   */
  function extractConversationTurns() {
    // Strategy A: data-message-author-role attributes (standard in ChatGPT web)
    const userElements = Array.from(document.querySelectorAll('[data-message-author-role="user"]'));
    const assistantElements = Array.from(document.querySelectorAll('[data-message-author-role="assistant"]'));

    let userTexts = userElements.map((el) => cleanUserText(el)).filter(Boolean);
    let assistantTexts = assistantElements.map((el) => cleanAssistantText(el)).filter(Boolean);

    // Strategy B: If empty, check article tags (modern ChatGPT articles)
    if (userTexts.length === 0 && assistantTexts.length === 0) {
      const articles = Array.from(document.querySelectorAll("article"));
      articles.forEach((art) => {
        const isUser =
          art.querySelector('[data-message-author-role="user"]') ||
          art.getAttribute("data-testid")?.includes("user") ||
          art.querySelector('div[class*="user"]');

        const isAssistant =
          art.querySelector('[data-message-author-role="assistant"]') ||
          art.getAttribute("data-testid")?.includes("assistant") ||
          art.querySelector('div[class*="assistant"]') ||
          art.querySelector(".markdown");

        if (isUser) {
          const t = cleanUserText(art);
          if (t) userTexts.push(t);
        } else if (isAssistant) {
          const t = cleanAssistantText(art);
          if (t) assistantTexts.push(t);
        }
      });
    }

    const maxCount = Math.max(userTexts.length, assistantTexts.length);
    const items = [];

    for (let i = 0; i < maxCount; i++) {
      const question = userTexts[i] || `Question ${i + 1}`;
      const answer = assistantTexts[i] || "No answer provided.";
      items.push({
        questionNumber: i + 1,
        question: question.trim(),
        answer: answer.trim()
      });
    }

    return items;
  }

  function cleanUserText(el) {
    if (!el) return "";
    // Remove edit controls
    const clone = el.cloneNode(true);
    const buttons = clone.querySelectorAll("button, [role='button']");
    buttons.forEach((b) => b.remove());
    return clone.innerText.trim();
  }

  function cleanAssistantText(el) {
    if (!el) return "";
    const clone = el.cloneNode(true);
    // Strip toolbars and action buttons
    const actionRows = clone.querySelectorAll(
      "button, [role='button'], div[class*='toolbar'], div[class*='feedback'], [data-testid*='copy']"
    );
    actionRows.forEach((r) => r.remove());

    const markdownNode = clone.querySelector(".markdown, [class*='markdown']");
    if (markdownNode) {
      return markdownNode.innerText.trim();
    }
    return clone.innerText.trim();
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
      // Remove floating button if inline target is available
      const floating = document.getElementById(FLOATING_BUTTON_ID);
      if (floating) floating.remove();

      const btn = document.createElement("button");
      btn.id = BUTTON_ID;
      btn.type = "button";
      btn.className = "unintently-trigger-btn";
      btn.innerHTML = `${ICONS.convert}<span>Convert To Assignment</span>`;
      btn.title = "Convert ChatGPT Q&As into Unintently handwritten assignment";
      btn.addEventListener("click", onConvertClick);

      targetContainer.appendChild(btn);
    } else {
      // If composer toolbar is not found, mount a floating fallback button
      if (!document.getElementById(FLOATING_BUTTON_ID)) {
        const floatBtn = document.createElement("button");
        floatBtn.id = FLOATING_BUTTON_ID;
        floatBtn.type = "button";
        floatBtn.className = "unintently-floating-btn";
        floatBtn.innerHTML = `${ICONS.convert}<span>Convert To Assignment</span>`;
        floatBtn.title = "Convert ChatGPT Q&As into Unintently handwritten assignment";
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
      btn.innerHTML = `${ICONS.convert}<span>Extracting Q&A...</span>`;
    }

    try {
      const title = extractConversationTitle();
      const items = extractConversationTurns();

      if (items.length === 0) {
        alert("No questions and answers found in this chat yet. Please prompt ChatGPT first.");
        return;
      }

      const assignmentDoc = {
        id: "chatgpt_" + Date.now(),
        title: title,
        docType: "qa",
        heading: title,
        items: items.map((i) => ({ question: i.question, answer: i.answer })),
        legacyItems: items.flatMap((i) => [
          { from: "human", value: i.question },
          { from: "gpt", value: i.answer }
        ]),
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

      // Determine sync code and online upload
      let syncCode = "UNINTENTLY-" + Math.random().toString(36).substring(2, 8).toUpperCase();
      let isCloudSynced = false;

      try {
        const storageData = await chrome.storage.local.get(["workerApiUrl"]);
        const workerUrl = storageData.workerApiUrl || "http://localhost:8787";

        if (workerUrl) {
          const syncUrl = workerUrl.replace(/\/$/, "") + "/create/chatGPTAssignments";
          const res = await fetch(syncUrl, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(assignmentDoc),
            signal: AbortSignal.timeout(2500)
          });
          if (res.ok) {
            const data = await res.json();
            if (data.shortLink || data.id) {
              syncCode = data.shortLink || data.id;
              isCloudSynced = true;
            }
          }
        }
      } catch (uploadErr) {
        // Fallback to offline direct sync gracefully
        console.info("[Unintently] Cloud sync offline fallback:", uploadErr?.message);
      }

      // Persist in extension history
      try {
        const stored = (await chrome.storage.local.get("conversationDataList")) || {};
        const list = Array.isArray(stored.conversationDataList) ? stored.conversationDataList : [];
        list.unshift({
          id: assignmentDoc.id,
          title: title,
          shortlink: syncCode,
          itemCount: items.length,
          creationTime: Date.now(),
          payload: assignmentDoc
        });
        // Limit to 60 items
        await chrome.storage.local.set({ conversationDataList: list.slice(0, 60) });
      } catch (storeErr) {
        console.warn("[Unintently] Local storage save error:", storeErr);
      }

      // Show in-page Modal Dialog
      showModalDialog({
        title: title,
        itemCount: items.length,
        syncCode: syncCode,
        isCloudSynced: isCloudSynced,
        assignmentDoc: assignmentDoc
      });
    } catch (err) {
      console.error("[Unintently] Error during conversion:", err);
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
   * In-page modal dialog rendering - Matches screenshot reference
   */
  function showModalDialog(data) {
    const existing = document.getElementById(MODAL_ID);
    if (existing) existing.remove();

    const overlay = document.createElement("div");
    overlay.id = MODAL_ID;
    overlay.className = "unintently-overlay";

    const jsonString = JSON.stringify(data.assignmentDoc, null, 2);
    const shareUrl = data.isCloudSynced
      ? `http://localhost:8787/assignments/${data.syncCode}`
      : `https://unintently.page.link/${data.syncCode}`;

    // For QR code: if cloud synced, encode the sync link; otherwise encode self-contained payload URL
    const qrData = data.isCloudSynced
      ? shareUrl
      : `unintently://payload?data=${encodeURIComponent(JSON.stringify(data.assignmentDoc))}`;

    overlay.innerHTML = `
      <div class="unintently-modal-dialog" role="dialog" aria-modal="true">
        <button class="unintently-modal-close-btn" id="unintently-close-modal" aria-label="Close dialog">
          ${ICONS.close}
        </button>

        <div class="unintently-modal-brand-title">Unintently</div>
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
          <div class="unintently-link-text" id="unintently-link-val">${escapeHtml(shareUrl)}</div>
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

    // Render QR Code using standalone UnintentlyQR
    const canvas = document.getElementById("unintently-qr-canvas");
    if (canvas && window.UnintentlyQR) {
      try {
        window.UnintentlyQR.toCanvas(canvas, qrData, { width: 200, margin: 2 }, function (err) {
          if (err) {
            console.warn("[Unintently] QR canvas fallback to shareUrl:", err);
            window.UnintentlyQR.toCanvas(canvas, shareUrl, { width: 200, margin: 2 });
          }
        });
      } catch (qrEx) {
        console.error("[Unintently] QR rendering error:", qrEx);
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
      const ok = await copyToClipboard(shareUrl);
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

    setInterval(injectTriggerButton, 1500);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", setupObserver);
  } else {
    setupObserver();
  }
})();
