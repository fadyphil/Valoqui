# 🧭 Journey

This is not a marketing document. It is an honest account of how Valoqui was built, what I actually learned, and where the line is between my work and the AI's.

---

## How It Was Built

Almost all the code in this repository was written by AI agents — Claude, Gemini, Qwen. I am not going to frame that differently than it is.

What I did was set the direction, enforce the constraints, and own the outcomes. I made the architectural decisions. I set the rules the agents had to follow. I reviewed what they produced, pushed back when it was wrong, and changed course when things broke. The agents implemented within the decisions I made. They did not make those decisions.

That distinction matters because it is the honest one.

Almost none of this was familiar territory. This was my first time with Firebase, CI/CD, local ML integration, formal product documentation, agent orchestration, and behavior-focused testing — most of it learned simultaneously on a single project.

---

## What Was Genuinely Mine

**The isolate decisions.** I identified that heavy STT and TTS inference would block the UI thread, decided that separate background isolates were the right tradeoff despite the larger memory footprint, and weighed that against the alternative. The agents wrote the isolate code. The architectural call was mine.

**The testing philosophy.** I discovered behavior-focused testing, understood why it is better than testing implementation details, and enforced it across the project. When my CI coverage threshold was set at 20%, I changed it — not to lower the bar, but because I understood that behavior-focused tests covering BLoCs and domain use cases will always yield lower coverage numbers than tests that cover every line. Changing a threshold you set yourself because you understood why it was wrong is a real decision.

**The perceived latency trick.** The STT model on mid-range Android hardware is physically constrained — the math is documented in the repo. You cannot make the model faster. What you can do is start decoding partial chunks while the user is still speaking, so the final result arrives sooner after silence is detected. I thought of that. It is the difference between optimizing a number and thinking about what the user actually experiences.

**The docs structure.** I built it incrementally, document by document, until it became what it is — ADRs, onboarding guide, setup guide, sprint docs, architecture deep dive, changelog. I learned that documentation is part of the architecture, not something you write at the end.

**Development, testing, and documentation together.** I used to finish all the code, then test it, then document it. On this project I did all three in parallel. That shift changes how you think about what "done" means.

**The CI scope.** I decided what the workflows check, agreed to agent suggestions where they made sense, and changed things that did not fit — like the coverage threshold. The pipeline is mine.

**Layer enforcement.** I forced the clean architecture. I set the rules for what can depend on what. When agents drifted, I corrected them. The service locator registration pattern — repositories as factories, datasources as lazy singletons — I set the example and the agents followed it.

---

## What the Bugs Taught Me

Some things I understood because I read about them. Others became real because they broke.

A font file was served as HTML instead of a TTF, and the system font silently overrode my design. That taught me: never trust the filesystem. Check existence and validity, not just existence.

A repository registered as a lazy singleton instead of a factory meant that the first speaking session worked, and every subsequent one got a disposed, dead object. That taught me resource ownership concretely — whoever creates something is responsible for its destruction, not some other object downstream. Lifecycle mismatches between a factory BLoC and singleton repositories is the kind of bug that does not appear in tutorials. It appeared for me and I had to reason through it.

These are not bugs I could have avoided by reading more carefully. They are the kind of thing that becomes a principle only after it costs you something.

---

## What I Generalized

From the bugs and the decisions, I came out with rules that are now general rather than specific:

- Assume failure even where success is expected. Cap everything. Add a safety net even for things that are supposed to work perfectly.
- Never trust incoming JSON. Never trust the filesystem. Validate before you use.
- Whoever creates a resource owns its destruction. Not the object downstream. Not the framework.
- Design for testability from the start, not after the code is written.
- Documentation is an engineering artifact, not an afterthought.

I can state these as rules because I learned them as rules, not as one-off fixes.

---

## Where I Still Have Gaps

I can read the code in this repository and explain most of it. There are patterns — particularly around isolate internals and some of the more complex BLoC orchestration — where my understanding is "I know why this decision was made" rather than "I could have designed this from scratch without help."

If you asked me to catch the problems I described above in a code review, I could catch most of them — but not on the first pass. The knowledge is there, not yet automatic. I know the difference.

This was also built alongside university exams, which means sprint deadlines slipped and some things took longer than they should have. That is context, not an excuse.

---

## What This Project Actually Is

It is proof that I learn, adapt, and think about quality rather than just completion. It is also proof that I can use AI as a force multiplier without producing slop — which requires knowing what good looks like and being willing to reject what does not meet it.

The codebase is scalable. The architecture is real. The decisions are documented. If you want to talk through any of it, I can.

---

*Built April 2026 — Flutter · BLoC · Freezed · GetIt · fpdart · Firebase · Sherpa-ONNX · Groq · Gemini*
