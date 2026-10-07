/**
 * Unintently Cloudflare Worker Backend
 * Version: 2.0.0
 * Zero-cost Cloudflare service for ChatGPT assignment synchronization and AI generation.
 */

const inMemoryAssignments = new Map();

function generateShortCode() {
  const chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
  let result = 'UNIN-';
  for (let i = 0; i < 6; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}

export default {
  async fetch(request, env) {
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    };

    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    const url = new URL(request.url);

    // Health check endpoint
    if (url.pathname === '/' || url.pathname === '/health') {
      return new Response(
        JSON.stringify({ status: 'ok', name: 'Unintently Cloudflare Backend', version: '2.0.0' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // AI Assignment Generation Endpoint (Llama 3)
    if (url.pathname === '/api/generate' && request.method === 'POST') {
      try {
        const body = await request.json();
        const prompt = body.prompt || '';
        const systemPrompt =
          body.system ||
          'You are an educational assistant that writes concise, clear, and well-structured answers for student assignments, homework, and practical lab files.';

        if (!prompt) {
          return new Response(
            JSON.stringify({ error: 'Prompt is required' }),
            { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          );
        }

        let generatedText = '';
        if (env.AI) {
          const aiResponse = await env.AI.run('@cf/meta/llama-3-8b-instruct', {
            messages: [
              { role: 'system', content: systemPrompt },
              { role: 'user', content: prompt },
            ],
            max_tokens: 1024,
          });
          generatedText = aiResponse.response || '';
        } else {
          generatedText = `Generated answer for: "${prompt}"`;
        }

        return new Response(
          JSON.stringify({ response: generatedText }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      } catch (err) {
        return new Response(
          JSON.stringify({ error: err.message }),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
    }

    // Create / Sync ChatGPT Assignment (Extension Sync)
    if (
      (url.pathname === '/create/chatGPTAssignments' || url.pathname === '/api/assignments') &&
      request.method === 'POST'
    ) {
      try {
        const assignmentData = await request.json();
        const shortCode = generateShortCode();
        const record = {
          id: shortCode,
          code: shortCode,
          data: assignmentData,
          createdAt: Date.now(),
        };

        // Persist to KV for 30 days
        if (env.ASSIGNMENTS) {
          await env.ASSIGNMENTS.put(shortCode, JSON.stringify(record), { expirationTtl: 86400 * 30 });
        } else {
          inMemoryAssignments.set(shortCode, record);
          if (inMemoryAssignments.size > 500) {
            const oldestKey = inMemoryAssignments.keys().next().value;
            inMemoryAssignments.delete(oldestKey);
          }
        }

        const shortLink = `https://${url.host}/a/${shortCode}`;
        const syncUrl = `https://${url.host}/assignments/${shortCode}`;

        return new Response(
          JSON.stringify({
            success: true,
            id: shortCode,
            code: shortCode,
            shortLink: shortLink,
            syncUrl: syncUrl,
            message: 'Assignment synced successfully to Unintently Cloudflare services',
          }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      } catch (err) {
        return new Response(
          JSON.stringify({ error: 'Failed to save assignment: ' + err.message }),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
    }

    // Web landing page for scanning link: /a/:code
    const webMatch = url.pathname.match(/^\/a\/([A-Za-z0-9_-]+)$/);
    if (webMatch && request.method === 'GET') {
      const code = webMatch[1];
      let record = null;
      if (env.ASSIGNMENTS) {
        const s = await env.ASSIGNMENTS.get(code);
        if (s) record = JSON.parse(s);
      } else {
        record = inMemoryAssignments.get(code) || null;
      }

      const title = record?.data?.title || 'ChatGPT Assignment';
      const count = record?.data?.items?.length || 1;

      const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${escapeHtml(title)} - Unintently</title>
  <style>
    body {
      margin: 0;
      padding: 24px 16px;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      background: #0f172a;
      color: #f8fafc;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      box-sizing: border-box;
    }
    .card {
      background: #1e293b;
      border: 1px solid #334155;
      border-radius: 16px;
      padding: 32px 24px;
      max-width: 440px;
      width: 100%;
      text-align: center;
      box-shadow: 0 10px 25px rgba(0, 0, 0, 0.4);
    }
    .badge {
      display: inline-block;
      background: rgba(0, 87, 210, 0.2);
      color: #60a5fa;
      padding: 4px 12px;
      border-radius: 9999px;
      font-size: 12px;
      font-weight: 600;
      letter-spacing: 0.5px;
      margin-bottom: 16px;
      text-transform: uppercase;
    }
    h1 {
      margin: 0 0 8px 0;
      font-size: 22px;
      font-weight: 700;
      color: #ffffff;
      word-break: break-word;
    }
    p {
      margin: 0 0 24px 0;
      font-size: 14px;
      color: #94a3b8;
      line-height: 1.5;
    }
    .code-box {
      background: #0f172a;
      border: 1px solid #334155;
      border-radius: 10px;
      padding: 12px;
      font-family: monospace;
      font-size: 16px;
      font-weight: 700;
      letter-spacing: 1px;
      color: #38bdf8;
      margin-bottom: 24px;
    }
    .btn {
      display: block;
      width: 100%;
      padding: 14px;
      border-radius: 10px;
      border: none;
      font-size: 15px;
      font-weight: 600;
      cursor: pointer;
      text-decoration: none;
      box-sizing: border-box;
      transition: background 0.2s ease;
      margin-bottom: 10px;
    }
    .btn-primary {
      background: #0057d2;
      color: #ffffff;
    }
    .btn-primary:hover {
      background: #0045a8;
    }
    .btn-secondary {
      background: #334155;
      color: #f8fafc;
    }
    .logo-wrap {
      margin-bottom: 20px;
      display: flex;
      justify-content: center;
    }
    .logo-wrap svg {
      width: 72px;
      height: 72px;
      border-radius: 18px;
      box-shadow: 0 4px 14px rgba(0, 87, 210, 0.35);
    }
  </style>
  <script>
    document.addEventListener("DOMContentLoaded", function() {
      // Automatic deep link launch
      var appUrl = "unintently://assignment?code=" + encodeURIComponent("${escapeHtml(code)}");
      window.location.href = appUrl;
    });
  </script>
</head>
<body>
  <div class="card">
    <div class="logo-wrap">
      <svg viewBox="0 0 512 512" width="72" height="72">
        <rect width="512" height="512" rx="116" fill="#0057D2"/>
        <path d="M 148 136 L 204 136 L 204 280 C 204 314, 226 334, 256 334 C 286 334, 308 314, 308 280 L 308 136 L 364 136 L 364 280 C 364 354, 318 394, 256 394 C 194 394, 148 354, 148 280 Z" fill="#FFFFFF"/>
        <circle cx="256" cy="358" r="7.5" fill="#0057D2"/>
        <rect x="253.5" y="362" width="5" height="34" fill="#0057D2"/>
      </svg>
    </div>
    <div class="badge">Unintently v2</div>
    <h1>${escapeHtml(title)}</h1>
    <p>Your handwritten assignment is ready to open on mobile.</p>
    <div class="code-box">${escapeHtml(code)}</div>
    <a href="unintently://assignment?code=${encodeURIComponent(code)}" class="btn btn-primary">Open in Unintently App</a>
    <a href="/assignments/${encodeURIComponent(code)}" class="btn btn-secondary">View Assignment JSON</a>
  </div>
</body>
</html>`;

      return new Response(html, {
        headers: { 'Content-Type': 'text/html; charset=utf-8' },
      });
    }

    // Retrieve Synced Assignment by Code or ID: /assignments/:code
    const getMatch = url.pathname.match(/^\/(?:assignments|api\/assignments)\/([A-Za-z0-9_-]+)$/);
    if (getMatch && request.method === 'GET') {
      const code = getMatch[1];
      let record = null;

      if (env.ASSIGNMENTS) {
        const storedStr = await env.ASSIGNMENTS.get(code);
        if (storedStr) {
          record = JSON.parse(storedStr);
        }
      } else {
        record = inMemoryAssignments.get(code) || null;
      }

      if (!record) {
        return new Response(
          JSON.stringify({ error: 'Assignment not found for code: ' + code }),
          { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      return new Response(
        JSON.stringify({
          success: true,
          code: code,
          assignment: record.data,
          createdAt: record.createdAt,
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    return new Response('Not Found', { status: 404, headers: corsHeaders });
  },
};

function escapeHtml(str) {
  if (!str) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}
