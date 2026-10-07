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
        JSON.stringify({ status: 'ok', name: 'Unintently AI Worker', version: '2.0.0' }),
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

        // Run Free Cloudflare Workers AI model (Meta Llama 3 8B Instruct)
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

    return new Response('Not Found', { status: 404, headers: corsHeaders });
  },
};
