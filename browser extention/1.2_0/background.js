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
    if (!existing.workerApiUrl) {
      // Default to empty or configurable worker endpoint
      updates.workerApiUrl = "http://localhost:8787";
    }
    if (Object.keys(updates).length > 0) {
      await chrome.storage.local.set(updates);
    }
    console.log("[Unintently] Extension installed/updated successfully:", details.reason);
  } catch (err) {
    console.error("[Unintently] Error during installation setup:", err);
  }
});
