/**
 * Unintently Chrome Extension - Popup Logic
 * Version: 2.0.0
 */

(function () {
  "use strict";

  // Elements
  const listEl = document.getElementById("assignments-list");
  const emptyStateEl = document.getElementById("empty-state");
  const countBadgeEl = document.getElementById("assignment-count-badge");
  const btnClearAll = document.getElementById("btn-clear-all");
  const btnToggleSettings = document.getElementById("btn-toggle-settings");
  const settingsPanel = document.getElementById("settings-panel");
  const workerUrlInput = document.getElementById("worker-url-input");
  const btnSaveSettings = document.getElementById("btn-save-settings");
  const settingsStatus = document.getElementById("settings-status");

  // QR Modal Elements
  const qrModal = document.getElementById("popup-qr-modal");
  const qrCanvas = document.getElementById("popup-qr-canvas");
  const qrModalTitle = document.getElementById("popup-modal-title");
  const qrCodeText = document.getElementById("popup-qr-code-text");
  const btnCloseQrModal = document.getElementById("btn-close-qr-modal");
  const btnModalCopyCode = document.getElementById("btn-modal-copy-code");
  const btnModalCopyJson = document.getElementById("btn-modal-copy-json");

  let activeModalData = null;

  // SVG Icons
  const ICONS = {
    doc: `<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m2.25 0H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z" />
    </svg>`,
    qr: `<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 4.875c0-.621.504-1.125 1.125-1.125h4.5c.621 0 1.125.504 1.125 1.125v4.5c0 .621-.504 1.125-1.125 1.125h-4.5A1.125 1.125 0 013.75 9.375v-4.5zM3.75 14.625c0-.621.504-1.125 1.125-1.125h4.5c.621 0 1.125.504 1.125 1.125v4.5c0 .621-.504 1.125-1.125 1.125h-4.5a1.125 1.125 0 01-1.125-1.125v-4.5zM13.5 4.875c0-.621.504-1.125 1.125-1.125h4.5c.621 0 1.125.504 1.125 1.125v4.5c0 .621-.504 1.125-1.125 1.125h-4.5A1.125 1.125 0 0113.5 9.375v-4.5z" />
      <path stroke-linecap="round" stroke-linejoin="round" d="M14.25 14.25h1.5v1.5h-1.5zM17.25 14.25h3v3h-3zM14.25 17.25h3v3h-3zM18.75 18.75h1.5v1.5h-1.5z" />
    </svg>`,
    copy: `<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" d="M15.666 3.888A2.25 2.25 0 0013.5 2.25h-3c-1.03 0-1.9.693-2.166 1.638m7.332 0c.055.194.084.4.084.612v0a.75.75 0 01-.75.75H9a.75.75 0 01-.75-.75v0c0-.212.03-.418.084-.612m7.332 0c.646.049 1.288.11 1.927.184 1.1.128 1.907 1.077 1.907 2.185V19.5a2.25 2.25 0 01-2.25 2.25H6.75A2.25 2.25 0 014.5 19.5V6.257c0-1.108.806-2.057 1.907-2.185a48.208 48.208 0 011.927-.184" />
    </svg>`,
    trash: `<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0" />
    </svg>`
  };

  /**
   * Helper to copy text to clipboard
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
      document.body.appendChild(textarea);
      textarea.focus();
      textarea.select();
      const res = document.execCommand("copy");
      document.body.removeChild(textarea);
      return res;
    } catch (e) {
      return false;
    }
  }

  /**
   * Format relative timestamp
   */
  function formatRelativeTime(ts) {
    if (!ts) return "Recently";
    const diff = Date.now() - Number(ts);
    const secs = Math.floor(diff / 1000);
    const mins = Math.floor(secs / 60);
    const hours = Math.floor(mins / 60);
    const days = Math.floor(hours / 24);

    if (mins < 1) return "Just now";
    if (mins < 60) return `${mins}m ago`;
    if (hours < 24) return `${hours}h ago`;
    if (days < 7) return `${days}d ago`;
    return new Date(ts).toLocaleDateString();
  }

  /**
   * Load and render assignments
   */
  async function loadAssignments() {
    try {
      const data = await chrome.storage.local.get(["conversationDataList", "workerApiUrl"]);
      const list = Array.isArray(data.conversationDataList) ? data.conversationDataList : [];

      if (workerUrlInput) {
        let currentUrl = data.workerApiUrl;
        if (!currentUrl || currentUrl.includes("localhost") || currentUrl.includes("intently.in")) {
          currentUrl = "https://unintently-backend.brksmartkraft.workers.dev";
          await chrome.storage.local.set({ workerApiUrl: currentUrl });
        }
        workerUrlInput.value = currentUrl;
      }

      countBadgeEl.textContent = list.length;

      if (list.length === 0) {
        listEl.innerHTML = "";
        emptyStateEl.classList.remove("hidden");
        return;
      }

      emptyStateEl.classList.add("hidden");
      renderList(list);
    } catch (err) {
      console.info("[Unintently] Note loading assignments:", err);
    }
  }

  /**
   * Render list of assignments
   */
  function renderList(list) {
    listEl.innerHTML = "";

    list.forEach((item, index) => {
      const card = document.createElement("div");
      card.className = "assignment-card";

      const count = item.itemCount || (item.payload?.items?.length) || 1;
      const title = item.title || "Untitled Assignment";
      const timeStr = formatRelativeTime(item.creationTime || item.payload?.createdAt);

      card.innerHTML = `
        <div class="card-top">
          <div class="card-icon">${ICONS.doc}</div>
          <div class="card-content">
            <div class="card-title" title="${escapeHtml(title)}">${escapeHtml(title)}</div>
            <div class="card-meta">
              <span>${timeStr}</span>
              <span class="card-badge">${count} Q&amp;As</span>
            </div>
          </div>
        </div>
        <div class="card-actions">
          <button class="btn-card-action btn-view-qr" data-index="${index}">
            ${ICONS.qr}<span>QR</span>
          </button>
          <button class="btn-card-action btn-copy-code" data-index="${index}">
            ${ICONS.copy}<span>Code</span>
          </button>
          <button class="btn-card-action btn-copy-json" data-index="${index}">
            <span>JSON</span>
          </button>
          <button class="btn-card-action btn-card-delete" data-index="${index}" title="Delete">
            ${ICONS.trash}
          </button>
        </div>
      `;

      listEl.appendChild(card);
    });

    // Attach event listeners
    attachCardListeners(list);
  }

  function attachCardListeners(list) {
    // View QR
    document.querySelectorAll(".btn-view-qr").forEach((btn) => {
      btn.addEventListener("click", () => {
        const idx = Number(btn.getAttribute("data-index"));
        const item = list[idx];
        if (item) openQrModal(item);
      });
    });

    // Copy Code
    document.querySelectorAll(".btn-copy-code").forEach((btn) => {
      btn.addEventListener("click", async () => {
        const idx = Number(btn.getAttribute("data-index"));
        const item = list[idx];
        const code = item?.shortlink || item?.id || "";
        const ok = await copyToClipboard(code);
        if (ok) {
          const original = btn.innerHTML;
          btn.innerHTML = `<span>Copied!</span>`;
          setTimeout(() => (btn.innerHTML = original), 1400);
        }
      });
    });

    // Copy JSON
    document.querySelectorAll(".btn-copy-json").forEach((btn) => {
      btn.addEventListener("click", async () => {
        const idx = Number(btn.getAttribute("data-index"));
        const item = list[idx];
        const payload = item?.payload ? JSON.stringify(item.payload, null, 2) : JSON.stringify(item, null, 2);
        const ok = await copyToClipboard(payload);
        if (ok) {
          const original = btn.innerHTML;
          btn.innerHTML = `<span>Copied!</span>`;
          setTimeout(() => (btn.innerHTML = original), 1400);
        }
      });
    });

    // Delete
    document.querySelectorAll(".btn-card-delete").forEach((btn) => {
      btn.addEventListener("click", async () => {
        const idx = Number(btn.getAttribute("data-index"));
        list.splice(idx, 1);
        await chrome.storage.local.set({ conversationDataList: list });
        loadAssignments();
      });
    });
  }

  /**
   * QR Modal handling
   */
  function openQrModal(item) {
    activeModalData = item;
    qrModalTitle.textContent = item.title || "Assignment QR";

    const code = item.shortlink || item.id || "";
    qrCodeText.textContent = code;

    const qrData = item.payload ? JSON.stringify(item.payload) : code;

    if (window.UnintentlyQR && qrCanvas) {
      try {
        window.UnintentlyQR.toCanvas(qrCanvas, code, { width: 200, margin: 2 }, (err) => {
          if (err) {
            console.info("[Unintently] Fallback to shortlink QR note:", err);
          }
        });
      } catch (ex) {
        console.info("[Unintently] QR note:", ex);
      }
    }

    qrModal.classList.remove("hidden");
  }

  function closeQrModal() {
    qrModal.classList.add("hidden");
    activeModalData = null;
  }

  btnCloseQrModal.addEventListener("click", closeQrModal);
  qrModal.addEventListener("click", (e) => {
    if (e.target === qrModal) closeQrModal();
  });

  btnModalCopyCode.addEventListener("click", async () => {
    if (!activeModalData) return;
    const code = activeModalData.shortlink || activeModalData.id || "";
    const ok = await copyToClipboard(code);
    if (ok) {
      const orig = btnModalCopyCode.textContent;
      btnModalCopyCode.textContent = "Copied!";
      setTimeout(() => (btnModalCopyCode.textContent = orig), 1400);
    }
  });

  btnModalCopyJson.addEventListener("click", async () => {
    if (!activeModalData) return;
    const jsonStr = activeModalData.payload
      ? JSON.stringify(activeModalData.payload, null, 2)
      : JSON.stringify(activeModalData, null, 2);
    const ok = await copyToClipboard(jsonStr);
    if (ok) {
      const orig = btnModalCopyJson.textContent;
      btnModalCopyJson.textContent = "Copied!";
      setTimeout(() => (btnModalCopyJson.textContent = orig), 1400);
    }
  });

  // Settings toggle
  btnToggleSettings.addEventListener("click", () => {
    settingsPanel.classList.toggle("hidden");
  });

  btnSaveSettings.addEventListener("click", async () => {
    const val = (workerUrlInput.value || "").trim();
    await chrome.storage.local.set({ workerApiUrl: val });
    settingsStatus.textContent = "Saved settings successfully.";
    setTimeout(() => {
      settingsStatus.textContent = "";
    }, 2000);
  });

  // Clear all history
  btnClearAll.addEventListener("click", async () => {
    if (confirm("Are you sure you want to clear all saved assignment history?")) {
      await chrome.storage.local.set({ conversationDataList: [] });
      loadAssignments();
    }
  });

  function escapeHtml(str) {
    if (!str) return "";
    return String(str)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;");
  }

  // Initialize
  document.addEventListener("DOMContentLoaded", loadAssignments);
})();
