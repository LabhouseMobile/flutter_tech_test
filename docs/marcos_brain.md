# Marco's brain

Why this repository looks the way it does. These are my notes and my opinions, about the product,
about AI, and about where I still need to be the one deciding.

## Human in the loop

AI is a help and a tool, and the human part is still part of building software. In my case I kept a
document open where I wrote questions, points, improvements and bugs as I found them in the app.
In an app that reaches thousands of users a lot comes into play, from how comfortable the user feels
to the technical debt that doesn't make the app fail, but still bends the standards we set for
ourselves.

Apps start one way and end up another. We're always making decisions, winning some things and
giving up others. That's normal. But knowing what's missing and what has to change tells us the real
state of the app. That's why there are two documents:

- [`human_notes_repo_review.md`](tasks/human_notes_repo_review.md) is written by hand, with almost
  no AI in the writing. It stays the way I wrote it.
- [`technical_debt.md`](tasks/technical_debt.md) collects what showed up while I was writing the
  standards for the skills and `AGENTS.md`. None of it breaks the app, or it would only reach a very
  small number of users. We know it's there and we can fix it when there's time, and put the energy
  into features that really work (favourites) or new features that give the user, and the product,
  extra value (the AI Companion).

## The human brain vs the silicon brains

As code got more automated, we went from asking a chat:

> Hey, what's the naming convention for my method?
>
> Can you help me harden my method? *(copy and paste the method into the chat)*

to an AI that writes files on our machine, uses git, writes a huge amount of tokens, and even
builds features or whole apps in less than 40 minutes.

That brings a dilemma. At what point does our brain get overwhelmed and switch to autopilot, like
when we drive more than 3 hours on a highway and make decisions without thinking?

There are plenty of posts about how much is too much for a dev to read and remember. I had a rule in
my teams: no PR bigger than 18 files, because we got overwhelmed. We were the knowledge base of how
the code works. When someone showed us a bug, most of the time we knew where it happened, because we
had built it a while ago, and we remembered the exact line or method, because we had read it or
written it.

Several blogs argue whether 1000 lines of code is a lot or a little, that focus gets lost, that we
look for the least effort on tasks like these, juggling several tasks at once or huge PRs we
sometimes don't manage to understand.

In this project I went for PRs that solve specific problems in a pragmatic way, where AI is part of
the tooling, but I'm still the human in the loop:

- I stage the files by hand.
- I review the options before picking one.
- Changes stay very small.
- Every commit is treated like a PR, because now we review what the AI does as if a teammate had
  opened a PR for us.

That's why the history is a line of small commits, each one focused on one specific thing.

## Test in the loop

Tests are there to give a wider picture of what happens, not to say "I wrote tests". Each test has
to confirm one specific action.

The lines I change get the failing case first, then the possible options, so what we test is what
we modified. No getting lost in a sea of tests that look like they cover the change. The test checks
the code; we don't bend the tests to match whatever the code does.

That's why every plan in [`impl_plans/`](impl_plans/) has a **Tests first** section, and
`AGENTS.md` asks for a test that fails without the change.
