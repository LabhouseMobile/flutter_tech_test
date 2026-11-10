# Speech-to-text costs

Transcribing is where the money goes. Summarizing an hour of podcast costs less than a cent;
transcribing that same hour can cost 36 cents. So if I have to be strict with one number, it's this
one.

Notes: Prices checked on the providers' official pages on **November 10, 2026**. Prices change every few
months, so double check sources and links before trusting them.

## The data I steer by

Before looking at the price, I ask these questions, in this order:

1. **Does it return real timestamps?** Without them there's no tap-to-seek. A cheap STT without timestamps
   doesn't count.
2. **Is it still alive when the reviewer runs the app?** A model that shuts down next month is a
   bug I'm shipping on purpose.
3. **Can it live behind the single OpenAI key?** The reviewer shouldn't have to create accounts.
4. **How big a file does it accept?** That decides which episodes the MVP can transcribe.
5. **What does an hour cost?** Only now.

## Providers

| Provider · model                      |   $/min |   $/hour | Real timestamps                    | File limit                         | Alive until      | Same OpenAI key |
|---------------------------------------|--------:|---------:|------------------------------------|------------------------------------|------------------|-----------------|
| OpenAI · `whisper-1`                  |   0.006 | **0.36** | ✅ segment + word (`verbose_json`) | 25 MB                              | **Feb 26, 2027** | ✅              |
| OpenAI · `gpt-transcribe`             |  0.0045 |     0.27 | ❌ not documented                  | 25 MB                              | replacement      | ✅              |
| OpenAI · `gpt-4o-transcribe`          |   0.006 |     0.36 | ❌                                 | 25 MB                              | Feb 26, 2027     | ✅              |
| OpenAI · `gpt-4o-mini-transcribe`     |   0.003 |     0.18 | ❌                                 | 25 MB                              | Feb 26, 2027     | ✅              |
| Groq · `whisper-large-v3-turbo`       | 0.00067 | **0.04** | ✅ segment + word (`verbose_json`) | 25 MB free / 100 MB dev, or by URL | open weights     | ❌ second key   |
| Groq · `whisper-large-v3`             | 0.00185 |    0.111 | ✅ segment + word                  | 25 MB / 100 MB, or by URL          | open weights     | ❌ second key   |
| Apple · `SpeechTranscriber` (iOS 26+) |       0 |        0 | ✅ time range per result           | none (on the device)               | OS               | n/a, iOS only   |

Notes:
- OpenAI says it plainly: `timestamp_granularities[]` is only supported for `whisper-1`. Its
  replacement returns the transcript and the language, with no times.
- Groq bills a minimum of 10 seconds per request.
- Apple costs $0 in API, but the user pays it in battery and storage. It only exists on iOS 26+, and
  the language assets may need a download first. Android would need its own path.

## What this means for the MVP

`whisper-1` is the only option that passes the first three questions. It's also the most expensive
one, and it shuts down on **February 26, 2027**.

BUT IT'S NOT ALL ROSES: I'm picking a model with an expiry date. I accept it because the test
gets reviewed before then, and because the app never talks to `whisper-1` by name outside one
service. Swapping it for Groq, or for our own backend, doesn't touch the UI.

### How many minutes fit in 25 MB?

| Bitrate                                  | MB per hour | Minutes in 25 MB |
|------------------------------------------|------------:|-----------------:|
| 128 kbps                                 |        57.6 |      **~26 min** |
| 64 kbps (common in spoken-word podcasts) |        28.8 |          ~52 min |

So an hour-long episode at 128 kbps doesn't fit. That's E4 in the README, and that's why the RSS
transcript goes first.

### What one episode costs in the MVP

| Case                                            |    STT | Note                             |
|-------------------------------------------------|-------:|----------------------------------|
| The RSS brings `<podcast:transcript>`           |  $0.00 | Nothing is transcribed           |
| Largest episode that fits (~26 min at 128 kbps) | ~$0.16 | `whisper-1` at $0.006/min        |
| One hour (if it fit)                            |  $0.36 | For comparison with Groq's $0.04 |

The cache is per device. If 1,000 people open the same one-hour episode, that's 1,000 transcripts:
**`~$360` instead of `$0.36`**. I know, and I accept it in the MVP for time and simplicity. In
production, this is the first thing I'd fix with a shared cache (see the README).

## Sources

- OpenAI pricing: https://developers.openai.com/api/docs/pricing
- OpenAI deprecations (announced Aug 26, 2026; shutdown Feb 26, 2027): https://developers.openai.com/api/docs/deprecations
- OpenAI speech-to-text guide (25 MB, timestamps only on `whisper-1`): https://developers.openai.com/api/docs/guides/speech-to-text
- Groq speech-to-text (prices, limits, `verbose_json`, 10 s minimum): https://console.groq.com/docs/speech-to-text
- Apple `SpeechTranscriber`: https://developer.apple.com/documentation/speech/speechtranscriber (the page didn't load when I checked; the notes on Apple come from the WWDC25 framework and still need confirming)
