# Pull Request

## Type
<!-- Mark exactly one -->
- [ ] `feat` — new feature or capability
- [ ] `fix` — bug fix
- [ ] `refactor` — code change with no behaviour change
- [ ] `perf` — performance improvement
- [ ] `test` — adding or correcting tests
- [ ] `chore` — build, deps, CI, tooling
- [ ] `docs` — documentation only

---

## What changed
<!-- One paragraph. What does this PR introduce or fix?
     Be specific enough that someone reading this in 6 months
     understands the change without opening the diff. -->

---

## Why
<!-- The architectural reason this change exists.
     Reference the relevant ADR, sprint guide section, or GitHub Issue.
     e.g. "Implements ADR-012. Android SpeechRecognizer hits a hard
     7-second OS ceiling — see ARCH-101 for full root cause." -->

---

## Tradeoffs and decisions made
<!-- What did you consciously choose NOT to do, and why?
     What alternative approaches were considered?
     This is the most valuable section — don't skip it. -->

---

## Risk areas
<!-- What could break? What are the edge cases you're most uncertain about?
     e.g. "TTS file copy on first launch — haven't tested on API 29" -->

---

## Screenshots / recordings
<!-- Voice pipeline changes: attach a screen recording of the conversation loop.
     UI changes: attach before/after screenshots.
     Not required for chore/docs PRs. -->

---

## Testing checklist

### General

- [ ] Builds without errors (`flutter build apk`)
- [ ] No new lint warnings (`flutter analyze`)
- [ ] `build_runner` run if any Freezed file was modified
- [ ] No API keys, `google-services.json`, or `firebase_options.dart` in diff
- [ ] No `TODO` comments in shipped code
- [ ] All error states handled — no unhandled `Left` or bare `catch (e) {}`

### If voice pipeline touched

- [ ] Tested on physical Android device (not emulator)
- [ ] Full conversation loop works end-to-end
- [ ] PTT mode works correctly
- [ ] Always-on VAD mode works correctly
- [ ] TTS speaks before full LLM response arrives (sentence-boundary trigger)
- [ ] Groq 429 falls back to Gemini silently
- [ ] Session ends cleanly — no dangling streams or subscriptions

### If BLoC touched

- [ ] No `emit()` called outside an event handler
- [ ] All stream subscriptions cancelled in `close()`
- [ ] Freezed `when()` exhaustive — no `orElse` hiding unhandled states

### If Firestore or auth touched

- [ ] Security rules still enforce per-user isolation
- [ ] No sensitive data written to Firestore (keys stay in Keystore only)

### If navigation touched

- [ ] Forward and back navigation tested
- [ ] GoRouter redirect logic does not loop

### Device matrix (mark which were tested)

- [ ] Android 10 (API 29)
- [ ] Android 12 (API 31)
- [ ] Android 14 (API 34)

---

## ADR created or updated
<!-- If this PR encodes a new architectural decision, create the ADR
     file in docs/decisions/ and link it here.
     If an existing ADR is superseded, update its Status field. -->
- [ ] No new architectural decision
- [ ] ADR created: `docs/decisions/ADR-XXX-title.md`
- [ ] ADR superseded: `docs/decisions/ADR-XXX-title.md` → Status updated

---

## Linked issues
<!-- Closes #XX | Relates to #XX -->
