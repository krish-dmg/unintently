/**
 * Unintently Cloudflare Worker
 * Version: 2.0.0
 * Provides AI assignment generation and ChatGPT extension sync endpoints.
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
        JSON.stringify({ status: 'ok', name: 'Unintently AI & Sync Worker', version: '2.0.0' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // AI Assignment Generation Endpoint
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

        // Run Cloudflare Workers AI model (Meta Llama 3 8B Instruct)
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
          generatedText = `[Offline Mode] Generated answer for: "${prompt}"`;
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

        // Persist to KV if bound, otherwise in-memory map
        if (env.ASSIGNMENTS) {
          await env.ASSIGNMENTS.put(shortCode, JSON.stringify(record), { expirationTtl: 86400 * 7 });
        } else {
          inMemoryAssignments.set(shortCode, record);
          // Keep in-memory cache pruned
          if (inMemoryAssignments.size > 200) {
            const oldestKey = inMemoryAssignments.keys().next().value;
            inMemoryAssignments.delete(oldestKey);
          }
        }

        return new Response(
          JSON.stringify({
            success: true,
            shortLink: shortCode,
            id: shortCode,
            code: shortCode,
            message: 'Assignment synced successfully',
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

    // Retrieve Synced Assignment by Code or ID
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
