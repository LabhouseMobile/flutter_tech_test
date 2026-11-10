# LLM costs

The LLM writes the summary and picks the segment where each chapter starts. It's the cheap part.
Even so, there's a catch I didn't see coming: the model I had planned shuts down in a month.

Prices checked on the providers' official pages on **November 10, 2026**.

## The data I steer by

1. **Is it still alive?** `gpt-5-nano` shuts down on **December 11, 2026**. Its official
   replacement is `gpt-5.6-luna`.
2. **Does it guarantee the JSON shape?** I need Structured Outputs with a strict schema, so the
   model can only return `summary` and `chapters: [{segmentId, title}]`.
3. **Can it live behind the single OpenAI key?**
4. **What does an hour of episode cost?** Here the differences are cents, not dollars.

## How I count an hour of episode

- One hour of talk ≈ 9,000 words ≈ 12K tokens of plain text.
- With the segment IDs and the system prompt: **~16.5K input tokens**.
- Output: **~3K tokens** (the JSON plus low-effort reasoning).
- In Spanish the same audio gives ~20–30% more tokens. I computed it at +25%.

These are my estimates, not measurements. With the first real episodes I'll recalculate them.

## Models

| Provider · model                            | Input $/1M | Cached input $/1M | Output $/1M | **$ per episode-hour** | +25% tokens (ES) | Alive                     | Same OpenAI key |
|---------------------------------------------|-----------:|------------------:|------------:|-----------------------:|-----------------:|---------------------------|-----------------|
| OpenAI · `gpt-5-nano`                       |       0.05 |             0.005 |        0.40 |                 0.0020 |           0.0025 | ❌ **until Dec 11, 2026** | ✅              |
| OpenAI · `gpt-5.6-luna`                     |       0.20 |              0.02 |        1.20 |             **0.0069** |           0.0086 | ✅ replacement for nano   | ✅              |
| OpenAI · `gpt-5.4-nano`                     |       0.20 |              0.02 |        1.25 |                 0.0071 |           0.0088 | ✅                        | ✅              |
| OpenAI · `gpt-5-mini`                       |       0.25 |             0.025 |        2.00 |                 0.0101 |           0.0127 | ❌ until Dec 11, 2026     | ✅              |
| Anthropic · Claude Haiku 5.5 (≤100K prompt) |       0.10 |              0.01 |        0.50 |             **0.0032** |           0.0039 | ✅                        | ❌ second key   |
| Anthropic · Claude Haiku 4.5                |       1.00 |              0.10 |        5.00 |                 0.0315 |           0.0394 | ✅                        | ❌              |
| Anthropic · Claude Sonnet 5.5               |       2.00 |              0.10 |       10.00 |                 0.0630 |           0.0788 | ✅                        | ❌              |
| Google · Gemini 2.5 Flash-Lite (text)       |       0.10 |                 — |        0.40 |                 0.0029 |           0.0036 | ✅                        | ❌              |

Notes:
- Haiku 5.5 charges ×5 when the prompt goes over 100K tokens. That's ~6 hours of audio in one call,
  so it doesn't affect a podcast.
- `gpt-5.6-luna` doubles the input and charges ×1.5 on the output above 272K tokens. That doesn't
  affect us either.
- Batch is 50% off at OpenAI and Anthropic, but it's asynchronous. A user waiting in front of the
  sheet isn't a batch.

## What this means for the MVP

The plan said `gpt-5-nano`. It's going to be **`gpt-5.6-luna`**: it's the official replacement, it
supports Structured Outputs and `reasoning_effort` (I'd use `low`), and it costs $0.0069 per hour of
episode. That's 3.5× nano, but it's still less than a cent.

The full STT + LLM picture for one hour:

| Stack                              |   STT |     LLM | **Total per hour** |
|------------------------------------|------:|--------:|-------------------:|
| MVP, RSS with transcript           |    $0 | $0.0069 |        **$0.0069** |
| MVP, `whisper-1` + `gpt-5.6-luna`  | $0.36 | $0.0069 |        **$0.3669** |
| Production, Groq turbo + Haiku 5.5 | $0.04 | $0.0032 |        **$0.0432** |

Going from Haiku to Sonnet multiplies the LLM by 20, but the total only goes from `$0.043` to `$0.103` an
hour.
**The LLM is a quality decision. STT and the cache are cost decisions.**

## Sources

- OpenAI pricing: https://developers.openai.com/api/docs/pricing
- OpenAI `gpt-5.6-luna`: https://developers.openai.com/api/docs/models/gpt-5.6-luna
- OpenAI deprecations (`gpt-5-nano` and `gpt-5-mini` shut down Dec 11, 2026): https://developers.openai.com/api/docs/deprecations
- Anthropic pricing: https://platform.claude.com/en/docs/about-claude/pricing
- Google Gemini pricing: https://aistudio.google.com/docs/pricing
