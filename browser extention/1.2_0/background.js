/**
 * Unintently Chrome Extension - Background Service Worker
 * Version: 2.0.0
 */

chrome.runtime.onInstalled.addListener(async (details) => {
  try {
    const existing = await chrome.storage.local.get(["conversationDataList", "workerApiUrl"]);
    const updates = {};
    if (!existing.conversationDataList) {
      updates.conversationDataList = [];
    }
    if (!existing.workerApiUrl || existing.workerApiUrl.includes("localhost") || existing.workerApiUrl.includes("intently.in")) {
      updates.workerApiUrl = "https://unintently-backend.brksmartkraft.workers.dev";
    }
    if (Object.keys(updates).length > 0) {
      await chrome.storage.local.set(updates);
    }
    console.info("[Unintently] Extension installed/updated successfully:", details.reason);
  } catch (err) {
    console.info("[Unintently] Installation setup notice:", err);
  }
});
