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
   * Primary Strategy: Official ChatGPT internal Web API
   * Directly extracts the active conversation tree using the current browser session.
   * Completely immune to DOM virtualization, dynamic layout changes, or missing nodes.
   */
  async function extractViaChatGPTApi() {
    try {
      const match = window.location.pathname.match(/\/(?:c|share|g\/[a-z0-9_-]+\/c)\/([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})/i);
      if (!match) return null;
      const chatId = match[1];

      // 1. Fetch current session to obtain active bearer token
      const sessionRes = await fetch("/api/auth/session", {
        credentials: "same-origin",
        signal: AbortSignal.timeout(3000)
      });
      if (!sessionRes.ok) return null;
      const sessionData = await sessionRes.json();
      const accessToken = sessionData?.accessToken;
      if (!accessToken) return null;

      // 2. Fetch full conversation mapping
      const convRes = await fetch("/backend-api/conversation/" + chatId, {
        headers: {
          "Authorization": "Bearer " + accessToken,
          "X-Authorization": "Bearer " + accessToken
        },
        credentials: "same-origin",
        signal: AbortSignal.timeout(4500)
      });
      if (!convRes.ok) return null;
      const convData = await convRes.json();
      if (!convData || !convData.mapping) return null;

      const title = convData.title || extractConversationTitle();
      const startNodeId = convData.current_node || Object.values(convData.mapping).find(n => !n.children || n.children.length === 0)?.id;
      if (!startNodeId) return null;

      // 3. Trace nodes backwards along the active branch to root
      const linearNodes = [];
      let curId = startNodeId;
      while (curId) {
        const node = convData.mapping[curId];
        if (!node) break;
        const role = node.message?.author?.role;
        if (role === "user" || role === "assistant") {
          const parts = node.message?.content?.parts;
          if (Array.isArray(parts)) {
            const text = parts.filter(p => typeof p === "string").join("\n").trim();
            if (text) {
              linearNodes.unshift({ role, text });
            }
          }
        }
        curId = node.parent;
      }

      if (linearNodes.length === 0) return null;

      // 4. Pair questions and answers
      const items = [];
      let pendingQuestion = null;

      for (const node of linearNodes) {
        if (node.role === "user") {
          if (pendingQuestion !== null) {
            items.push({
              questionNumber: items.length + 1,
              question: pendingQuestion,
              answer: ""
            });
          }
          pendingQuestion = node.text;
        } else if (node.role === "assistant") {
          if (pendingQuestion !== null) {
            items.push({
              questionNumber: items.length + 1,
              question: pendingQuestion,
              answer: node.text
            });
            pendingQuestion = null;
          } else {
            if (items.length > 0) {
              items[items.length - 1].answer += "\n\n" + node.text;
            } else {
              items.push({
                questionNumber: 1,
                question: title,
                answer: node.text
              });
            }
          }
        }
      }

      if (pendingQuestion !== null) {
        items.push({
          questionNumber: items.length + 1,
          question: pendingQuestion,
          answer: ""
        });
      }

      if (items.length > 0) {
        return {
          title: title,
          items: items,
          legacyItems: items.flatMap(i => [
            { from: "human", value: i.question },
            { from: "gpt", value: i.answer }
          ]),
          sourceMethod: "ChatGPT Session API"
        };
      }
    } catch (e) {
      console.info("[Unintently] Session API extraction fallback note:", e?.message);
    }
    return null;
  }

  /**
   * Helper to clean user prompt text
   */
  function cleanUserText(el) {
    if (!el) return "";
    try {
      const bubble = el.querySelector(".whitespace-pre-wrap, [class*='whitespace-pre-wrap']") || el;
      let raw = bubble.innerText || bubble.textContent || "";
      if (!raw) return "";
      return raw.replace(/^(Edit|Copy)\s*$/gim, "").trim();
    } catch (_) {
      return (el.innerText || el.textContent || "").trim();
    }
  }

  /**
   * Helper to clean assistant response text from any turn or container
   */
  function cleanTurnText(el) {
    if (!el) return "";
    try {
      // If el is or contains a markdown/prose block, read directly from it
      const md = (el.classList?.contains("markdown") || el.classList?.contains("prose"))
        ? el
        : el.querySelector?.(".markdown, [class*='markdown'], [class*='prose']");
      const target = md || el;

      let raw = (target.innerText || target.textContent || "").trim();
      if (!raw) return "";

      // Remove ChatGPT UI button text artifacts
      let cleaned = raw
        .replace(/^(Copy|Edit|Read aloud|Good response|Bad response|Regenerate|Share)\s*$/gim, "")
        .replace(/\n{3,}/g, "\n\n")
        .trim();

      return cleaned;
    } catch (_) {
      return (el.innerText || el.textContent || "").trim();
    }
  }

  /**
   * Locates user prompt elements on ChatGPT
   */
  function getUserElements() {
    // 1. Explicit author role
    let els = Array.from(document.querySelectorAll('[data-message-author-role="user"]'));
    if (els.length > 0) return els;

    // 2. Turns with user markers
    const turns = Array.from(document.querySelectorAll('[data-testid^="conversation-turn-"], article, div[class*="conversation-turn"]'));
    const uTurns = turns.filter(t => t.querySelector('[data-message-author-role="user"]') || (t.querySelector('.whitespace-pre-wrap') && !t.querySelector('.markdown')));
    if (uTurns.length > 0) return uTurns;

    // 3. User bubbles outside forms
    const preWraps = Array.from(document.querySelectorAll('main div.whitespace-pre-wrap, div[class*="whitespace-pre-wrap"]'));
    const filtered = preWraps.filter(el => {
      if (el.closest('form, #composer-background, [contenteditable="true"], nav, aside')) return false;
      if (el.closest('.markdown, [class*="markdown"], [class*="prose"]')) return false;
      return (el.textContent || "").trim().length > 0;
    });
    return filtered.filter((el, idx) => !filtered.some((other, oIdx) => idx !== oIdx && other.contains(el)));
  }

  /**
   * Locates assistant response elements on ChatGPT using multi-strategy detection
   */
  function getAssistantElements() {
    // 1. Explicit author role
    let els = Array.from(document.querySelectorAll('[data-message-author-role="assistant"], [data-message-author-role="model"]'));
    if (els.length > 0) return els;

    // 2. Markdown / prose blocks in chat area (Standard container for all ChatGPT assistant outputs)
    const mdEls = Array.from(document.querySelectorAll('main .markdown, main [class*="markdown"], [class*="markdown prose"], div.prose, [data-testid*="agent-turn"] .markdown'));
    const filteredMd = mdEls.filter((el, idx) => {
      if (el.closest('[data-message-author-role="user"], form, #composer-background, nav, aside, header')) return false;
      if (mdEls.some((other, oIdx) => idx !== oIdx && other.contains(el))) return false;
      return (el.innerText || el.textContent || "").trim().length > 0;
    });
    if (filteredMd.length > 0) return filteredMd;

    // 3. Agent turns or conversation turns that are NOT user turns
    const allTurns = Array.from(document.querySelectorAll('.agent-turn, [data-testid^="conversation-turn-"], article, div[class*="conversation-turn"]'));
    if (allTurns.length > 0) {
      const aTurns = allTurns.filter(t => {
        if (t.closest('form, #composer-background, nav, aside, header')) return false;
        if (t.querySelector('[data-message-author-role="user"]')) return false;
        const txt = cleanTurnText(t);
        return txt.length > 0;
      });
      if (aTurns.length > 0) return aTurns;
    }

    // 4. Action button anchors: locate parent turn container of copy buttons
    const copyBtns = Array.from(document.querySelectorAll('button[aria-label*="Copy" i], [data-testid*="copy" i]'));
    if (copyBtns.length > 0) {
      const candidates = copyBtns.map(btn => {
        return btn.closest('[data-testid^="conversation-turn-"], article, .agent-turn') ||
               btn.parentElement?.parentElement?.parentElement?.parentElement;
      }).filter(Boolean);
      const unique = [];
      candidates.forEach(c => {
        if (!unique.includes(c) && !c.querySelector('[data-message-author-role="user"]')) {
          unique.push(c);
        }
      });
      if (unique.length > 0) return unique;
    }

    return [];
  }

  /**
   * Fallback: High-fidelity DOM-based conversation extractor
   */
  function extractViaDom() {
    const title = extractConversationTitle();

    let userElements = getUserElements();
    let assistantElements = getAssistantElements();

    // Sort strictly in DOM reading order
    userElements.sort((a, b) => {
      const pos = a.compareDocumentPosition(b);
      if (pos & Node.DOCUMENT_POSITION_FOLLOWING) return -1;
      if (pos & Node.DOCUMENT_POSITION_PRECEDING) return 1;
      return 0;
    });

    assistantElements.sort((a, b) => {
      const pos = a.compareDocumentPosition(b);
      if (pos & Node.DOCUMENT_POSITION_FOLLOWING) return -1;
      if (pos & Node.DOCUMENT_POSITION_PRECEDING) return 1;
      return 0;
    });

    const userTexts = userElements.map(cleanUserText).filter(t => t.length > 0);
    const assistantTexts = assistantElements.map(cleanTurnText).filter(t => t.length > 0);

    const items = [];
    const legacyItems = [];

    // Positional matching: match each user question with the assistant element following it in the DOM
    if (userElements.length > 0 && assistantElements.length > 0) {
      for (let i = 0; i < userElements.length; i++) {
        const uEl = userElements[i];
        const nextUEl = userElements[i + 1] || null;
        const q = cleanUserText(uEl);
        if (!q) continue;

        let matchedAssistantText = "";
        for (const aEl of assistantElements) {
          const posAfterU = uEl.compareDocumentPosition(aEl);
          const isAfter = !!(posAfterU & Node.DOCUMENT_POSITION_FOLLOWING);
          if (isAfter) {
            if (!nextUEl) {
              matchedAssistantText = cleanTurnText(aEl);
              break;
            } else {
              const posBeforeNext = aEl.compareDocumentPosition(nextUEl);
              const isBeforeNext = !!(posBeforeNext & Node.DOCUMENT_POSITION_FOLLOWING);
              if (isBeforeNext) {
                matchedAssistantText = cleanTurnText(aEl);
                break;
              }
            }
          }
        }

        // Fallback to index matching if positional didn't find one
        if (!matchedAssistantText && i < assistantTexts.length) {
          matchedAssistantText = assistantTexts[i] || "";
        }

        items.push({
          questionNumber: items.length + 1,
          question: q,
          answer: matchedAssistantText
        });

        legacyItems.push({ from: "human", value: q });
        if (matchedAssistantText) {
          legacyItems.push({ from: "gpt", value: matchedAssistantText });
        }
      }
    } else {
      // Index-based matching fallback
      const maxCount = Math.max(userTexts.length, assistantTexts.length);
      for (let i = 0; i < maxCount; i++) {
        const q = userTexts[i] || (maxCount === 1 ? title : `Question ${i + 1}`);
        const a = assistantTexts[i] || "";

        if (!q && !a) continue;

        if (q) legacyItems.push({ from: "human", value: q });
        if (a) legacyItems.push({ from: "gpt", value: a });

        items.push({
          questionNumber: items.length + 1,
          question: q,
          answer: a
        });
      }
    }

    // Fallback: If 0 items were extracted, pair alternating text bubbles
    if (items.length === 0) {
      const bubbles = Array.from(document.querySelectorAll("main div[class*='whitespace-pre-wrap'], main p, [data-testid*='message']"));
      const filtered = bubbles.filter((b, idx) => {
        if (b.closest("form, #composer-background, nav, aside, footer")) return false;
        if (bubbles.some((other, oIdx) => idx !== oIdx && other.contains(b))) return false;
        const txt = cleanTurnText(b);
        return txt.length > 0 && !txt.match(/^(Copy|Edit|Read aloud|Regenerate|Good response|Bad response)$/i);
      });

      filtered.sort((a, b) => {
        const pos = a.compareDocumentPosition(b);
        if (pos & Node.DOCUMENT_POSITION_FOLLOWING) return -1;
        if (pos & Node.DOCUMENT_POSITION_PRECEDING) return 1;
        return 0;
      });

      const pieces = filtered.map(cleanTurnText).filter(t => t.length > 0);
      for (let i = 0; i < pieces.length; i += 2) {
        const q = pieces[i];
        const a = pieces[i + 1] || "";
        legacyItems.push({ from: "human", value: q });
        if (a) legacyItems.push({ from: "gpt", value: a });
        items.push({
          questionNumber: items.length + 1,
          question: q,
          answer: a
        });
      }
    }

    return {
      title: title,
      items: items,
      legacyItems: legacyItems,
      sourceMethod: "Live DOM Extraction"
    };
  }

  /**
   * Main unified extractor: Prioritizes official API, then falls back to DOM
   */
  async function extractConversation() {
    const apiResult = await extractViaChatGPTApi();
    if (apiResult && apiResult.items.length > 0) {
      const hasAnswers = apiResult.items.some(i => i.answer && i.answer.trim().length > 0);
      if (hasAnswers) {
        console.info("[Unintently] Extracted " + apiResult.items.length + " items via ChatGPT Session API:", apiResult.items);
        return apiResult;
      }
    }

    const domResult = extractViaDom();
    console.info("[Unintently] Extracted " + domResult.items.length + " items via DOM (" + domResult.sourceMethod + "):", domResult.items);
    return domResult;
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
      const extracted = await extractConversation();
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
        legacyItems: extracted.legacyItems,
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
        sourceMethod: extracted.sourceMethod,
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
        <div class="unintently-modal-subtitle">${data.itemCount} Questions &amp; Answers Ready &bull; ${escapeHtml(data.sourceMethod || "Scan on mobile")}</div>

        <div style="max-height: 110px; overflow-y: auto; background: #0f172a; border: 1px solid #334155; border-radius: 8px; padding: 8px 10px; margin: 8px 0 12px 0; text-align: left; font-size: 11px; color: #cbd5e1; line-height: 1.4; word-break: break-word;">
          ${data.assignmentDoc.items.map((it, idx) => `
            <div style="margin-bottom: 4px; border-bottom: 1px solid #1e293b; padding-bottom: 3px;">
              <span style="color: #38bdf8; font-weight: 600;">Q${idx + 1}:</span> ${escapeHtml(it.question)}<br/>
              <span style="color: #4ade80; font-weight: 600;">A${idx + 1}:</span> ${escapeHtml(it.answer ? (it.answer.length > 80 ? it.answer.substring(0, 80) + '...' : it.answer) : '(Empty)')}
            </div>
          `).join('')}
        </div>

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
