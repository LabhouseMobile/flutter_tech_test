# Marco's brain: how I got to AI Companion

## Letting things go

AI Companion is an MVP meant to stand out, so first we have to ship a minimum viable version. That
means that when making an architecture decision, we have to let things go, and we have to know what
we're letting go.

That's why there are several things that would be the "ideal way" of building this feature for end
users.

For that, the MVP will follow a principle called KISS, to have a solid base, like a base of Lego
pieces, so later we can add or remove other pieces.

For this version, I wanted the reviewer to take as few steps as possible, and to add as few libraries
and changes as possible.

## Limits for the reviewer

For this development there are some limits for the reviewer:

- The reviewer shouldn't have to create accounts or generate other API keys, and only 1 LLM client is
  used.
- Don't change or add libraries to the app that need private files (aka `GoogleService-Info.plist`,
  `google-services.json`).
- Don't change the Xcode version, to make it easy for the reviewer.

That's why I chose to use every service from a single provider (OpenAI). Today they have a
transcription model, and we can use their LLM to summarize.

## What I compared

My benchmark was based on prices, scalability, practicality, user experience and implementation.

Something I found is that summarizing is what costs the least. What costs, logically and
economically, is TRANSCRIBING.

Another finding: focusing on the podcast instead of the user is the best approach possible. If
10,000 users look for the same podcast, we don't summarize it or fetch the audio 10,000 times. We
need a cache or storage of every podcast that's been requested, so the user who hits play triggers
the call and saves the podcast, and the rest of the users who want to listen to it use the cache
someone else triggered.

The backend/backend for frontend/function/lambda would do the work of giving us the information,
without much effort on the device.

The price of the summary depends on whether we use a stronger or weaker model with any provider
(OpenAI, Gemini, Claude) and its effort level.

## The ideal pipeline (thousands of users)

So the pipeline I'd consider for this feature, in an environment with thousands of users, would be
this one.

**User 1: opens an episode that hasn't been saved**

1. I open the episode.
2. Is there a cache? No.
3. Is there a transcript?
   - Yes: we parse the transcript.
   - No: we get the transcript with times (if possible).
4. We get the text segments with their times.
5. The LLM summarizes.
6. We try to match it with the times.
7. The transcript/prompt is saved.
8. It's returned to the user.

**User 2: opens an episode that's already saved**

1. I open the episode.
2. Is there a cache? Yes.
3. It downloads the summary and shows it.

If 10,000 users open the same episode, only the first user pays for the summary and/or the
transcription. So the first user would wait a bit longer than the rest.

The Speech to Text (STT) and LLM costs are in [`costs/`](costs/).

## Picking the STT

In the market of late 2026, there are several options for STT:

- **Whisper-1** (the favorite), BUT: it shuts down on Feb 26, 2027. It has words + segments.
  Note: OpenAI will move its service to `gpt-transcribe`, but word timestamps won't be there anymore.
- **Apple's on-device speech (iOS 26+)** gives us time ranges, but not every user would have this
  feature. It would save us part of the costs, in exchange for the user's battery and storage.
- **Groq, `whisper-large-v3-turbo`**: the Winner. It uses Whisper's open weights, its API is
  compatible with OpenAI, and it has timestamps. Its price per hour is $0.04, the cheapest (well, not
  as cheap as on-device, tbh).

What I'd propose for the "ideal way" would be: use Groq Whisper Turbo, and pick Claude Haiku or
`gpt-5.6-luna` in the stack for the STT+LLM processes. (`gpt-5-nano` was the option, but it shuts
down on Dec 11, 2026, and its official replacement is `gpt-5.6-luna`.)

However, Groq and OpenAI come with a file size limit, which is 25 MB free / 100 MB dev, or by URL.

## BUT IT'S NOT ALL ROSES: long episodes

It means that if we want the text of a 2h30m episode that can weigh 110 MB, we'd have to cut it into
sections and then put the pieces back together. So I'd propose cutting it every so often. Doing it
by windows avoids the user waiting for the audio and summary of 25 MB of audio to come back.

Otherwise, split it into windows of ~12 minutes, ship a first version, while the whole episode gets
done in a queue.

But if someone hits play on the episode and doesn't finish it, we can make the loading progressive.
If nobody finishes the episode, does it make sense to fetch all of it and summarize it? We can fill
episodes as they get used, so we don't overspend. That would save cents, in case money were
something strictly calculated. It's something to check once the product is out, so we can study how
it's used.

## What can go wrong

There are things that can go wrong:

**What happens when a podcast has a lot of silence?**
Well, STTs tend to hallucinate in silence or music, so it would be good to find the segments and
remove whatever is left as empty space.

**What if Groq decides to change, or we switch providers, or we use an open weights model on our own
infrastructure?**
Keep the changes living outside the app, so the app is agnostic to big changes.

**What happens if someone wants to use our endpoint for free?**
Create limits per device, use known episodes, or check sessions and clients.

**What about translating languages?**
Measure with episodes in different languages to calculate the total prices, because, for example, in
Spanish there are about 20/30% more tokens per hour.

**And dynamic ads?**
Save the real audio duration and compare it, re-align with the segment. The LLM can already tell an
ad apart from a conversation topic.

**And what if someone opens an episode by accident?**
If AI Companion started on its own when opening the player, every fat-finger tap would pay for a
transcription and a summary nobody asked for.

That's why AI Companion only loads when the user taps the button below called "AI Companion", the one
with the magic icon. Opening an episode doesn't trigger anything: no download, no transcription, no
summary. We only pay for what someone wanted to see.

**BUT IT'S NOT ALL ROSES:** the first time you tap it on an episode with no cache, you have to wait
for it to get ready. I accept it. I'd rather that than spend on episodes nobody read.

## So, what goes into the MVP?

But Marco, I get that it's a whole process with several modules, technologies and calls. Are we going
to put all of it into this small test and MVP?

No, my friend. Even though I'd like to build it, dig in and get my hands a little dirty, I'll apply
the KISS principle. I know it can be done so it scales, but an MVP has to prove certain things and
ship in the shortest time possible. For that, I'm planning certain features inside the project,
knowing what I'd have to do:

1. Everything will be handled on the device.
2. We'll use OpenAI's services for the transcript and the summary: `whisper-1` to transcribe and
   `gpt-5.6-luna` for the summary and the chapters.
3. The summary and the cache will stay per user.
4. First I'll define the real foundations it will be built on.
5. The player will get the minimum viable changes so AI Companion can live in it.
6. The MVP will consume per episode, so if 1,000 people want to use it, there will be 1,000 payments
   to the API. But that's accepted in this MVP for time and practicality.
