# Multi-Provider Failover System

## Overview
The AI program generator now includes an intelligent multi-provider failover system that automatically switches between different AI providers if one fails. This ensures high availability and reliability.

## Supported Providers

### 1. **OpenRouter** (Primary Provider)
- **Priority**: First choice
- **API**: OpenRouter.ai
- **Models**: `deepseek/deepseek-r1-distill-llama-70b:free`
- **Configuration**: 3 API keys supported for redundancy
  - `OPENROUTER_API_KEY`
  - `OPENROUTER_API_KEYB`
  - `OPENROUTER_API_KEYC`

### 2. **Groq** (Secondary Provider)
- **Priority**: Second choice (if OpenRouter fails)
- **API**: api.groq.com
- **Models**: `mixtral-8x7b-32768`
- **Configuration**: Single API key
  - `GROQ_API_KEY`

### 3. **Google Gemini** (Tertiary Provider)
- **Priority**: Third choice (if Groq fails)
- **API**: generativelanguage.googleapis.com
- **Models**: `gemini-1.5-flash`
- **Configuration**: Single API key
  - `GEMINI_API_KEY`

## Setup Instructions

### 1. Update `wrangler.jsonc`

Add your API keys to the `vars` section:

```jsonc
{
  "vars": {
    "OPENROUTER_API_KEY": "your-openrouter-key-1",
    "OPENROUTER_API_KEYB": "your-openrouter-key-2",
    "OPENROUTER_API_KEYC": "your-openrouter-key-3",
    "GROQ_API_KEY": "your-groq-api-key",
    "GEMINI_API_KEY": "your-gemini-api-key"
  }
}
```

### 2. Environment Variables

For local development, set:
```bash
OPENROUTER_API_KEY=sk-or-v1-...
OPENROUTER_API_KEYB=sk-or-v1-...
OPENROUTER_API_KEYC=sk-or-v1-...
GROQ_API_KEY=gsk_...
GEMINI_API_KEY=AIza...
```

## How It Works

### Failover Flow

1. **OpenRouter (Primary)**
   - Tries all 3 OpenRouter keys in sequence
   - If any key succeeds, returns result
   - If all fail, moves to Groq

2. **Groq (Secondary)**
   - Only attempted if all OpenRouter keys fail
   - Uses `mixtral-8x7b-32768` model
   - If succeeds, returns result
   - If fails, moves to Gemini

3. **Google Gemini (Tertiary)**
   - Only attempted if both OpenRouter and Groq fail
   - Uses `gemini-1.5-flash` model
   - Final fallback provider
   - If fails, throws error

### Request Types

The system handles both:
- **Batch requests** (week/month): Multiple days of programs
- **Single-day requests**: One program for a specific date

Temperature and token limits are automatically adjusted:
- **Batch mode** (isArray=true):
  - Temperature: 0.9 (more creative)
  - Max tokens: 4096
- **Single mode** (isArray=false):
  - Temperature: 0.7 (more consistent)
  - Max tokens: 2048

## Logging

The system provides detailed logs for debugging:

```
🔄 Trying OpenRouter...
✅ OpenRouter success
Provider Used: OpenRouter

OR

❌ OpenRouter failed: [error message]
🔄 Trying Groq...
✅ Groq success
Provider Used: Groq
```

## Response Format

All responses include a `provider` field indicating which AI provider generated the response:

```json
{
  "program": {
    "nom": "Programme IA – 2026-01-01",
    "date": "2026-01-01",
    "exercices": [...]
  },
  "provider": "OpenRouter"
}
```

## Error Handling

### Retriable Errors
The system automatically retries on:
- 401 (Unauthorized) - Next key or provider
- 403 (Forbidden) - Next key or provider
- 429 (Rate Limited) - Next key or provider
- 500, 502, 503, 504 (Server Errors) - Next provider
- Network errors - Next key or provider

### Non-Retriable Errors
Immediately throws error:
- 400 (Bad Request)
- 404 (Not Found)
- Other client errors

## API Keys

### Getting OpenRouter Keys
1. Go to [OpenRouter.ai](https://openrouter.ai)
2. Create account
3. Generate API keys
4. Copy to `wrangler.jsonc`

### Getting Groq Keys
1. Go to [Groq Console](https://console.groq.com)
2. Create account
3. Generate API key
4. Copy to `wrangler.jsonc`

### Getting Google Gemini Keys
1. Go to [Google AI Studio](https://aistudio.google.com)
2. Create API key
3. Copy to `wrangler.jsonc`

## Testing

### Test Multi-Provider Failover

```bash
# Test with debug mode enabled
curl -X POST https://your-worker-url.com \
  -H "Content-Type: application/json" \
  -d '{
    "uid": "user123",
    "objectif": "Augmenter force",
    "range": "week",
    "debug": true
  }'
```

Check response logs to see which provider was used.

## Performance

Expected response times:
- **OpenRouter**: 2-5 seconds
- **Groq**: 3-8 seconds
- **Google Gemini**: 4-10 seconds

Failover adds minimal overhead (~1-2 seconds) per provider attempt.

## Cost Considerations

### OpenRouter
- Free tier with rate limits
- Paid tier for unlimited usage

### Groq
- Free tier available
- Pay-as-you-go for high volume

### Google Gemini
- Free tier (limited requests)
- Paid tier for production

Recommend implementing request queuing/caching to reduce API calls.

## Troubleshooting

### All Providers Failing?
1. Check API keys in `wrangler.jsonc`
2. Verify internet connectivity
3. Check rate limits on each provider
4. Review error logs for specific issues

### Slow Responses?
1. Consider caching responses
2. Use cheaper models if applicable
3. Reduce max_tokens if not needed
4. Implement request batching

### Inconsistent Output?
1. All providers may format differently
2. Validate output in application layer
3. Consider normalizing responses

## Future Enhancements

- [ ] Add Claude (Anthropic) as provider
- [ ] Add local LLM support (Ollama)
- [ ] Implement response caching
- [ ] Add cost tracking per provider
- [ ] Implement request queuing
- [ ] Add provider-specific prompt optimization
