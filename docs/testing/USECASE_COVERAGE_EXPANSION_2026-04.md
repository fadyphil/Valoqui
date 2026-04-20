# Use Case Coverage Expansion (April 2026)

## Why this update was needed

The existing suite had strong BLoC coverage, but several core domain use cases had little or no direct unit-test coverage. That left business rules and repository orchestration paths under-validated when tested only through higher-level BLoCs.

This update focuses on behavior-first tests that verify externally observable outcomes of each use case:

- Input normalization behavior
- Failure propagation behavior
- Retry and fallback behavior
- Non-blocking side-effect behavior for best-effort writes
- Correct delegation to repository contracts

## Coverage gaps addressed

New tests were added for previously uncovered or under-covered use cases:

- `WatchAuthState`
- `SignOut`
- `WatchUserProfile`
- `UpdateUserLevel`
- `CheckOnboardingStatus`
- `MarkOnboardingComplete`
- `SaveGroqKey`
- `SaveGeminiKey`
- `SaveSessionXp`
- `GenerateReport`

## Behavior validated

### Auth + User flow

- Auth state stream is passed through exactly as exposed by repository.
- Sign-out success and failure states are propagated unchanged.
- User profile stream delegation is verified for the requested UID.
- `UpdateUserLevel` business rule (`"?" -> "A1"`) is tested explicitly.

### Onboarding key management

- Invalid Groq key format is rejected before storage writes.
- Key-storage failures stop the flow and propagate the failure.
- Firestore key-configured flag updates are validated.
- Best-effort behavior is verified: key save can still succeed even when Firestore flag update fails.

### Report generation + XP persistence

- XP persistence delegates correctly and returns repository outcomes.
- Report parsing succeeds for valid JSON payloads.
- Markdown-fenced JSON parsing is supported.
- Parse-failure retry behavior is tested (up to three attempts).
- Final parse failure after three invalid attempts is tested.
- LLM hard failure is returned immediately (no retry on left/failure result).

## Reasoning behind this test strategy

1. **Behavior over implementation details**: tests assert user-facing outcomes and contract boundaries, not private internals.
2. **Risk-first prioritization**: targeted use cases carrying business rules and retries were prioritized first.
3. **Layer confidence**: with BLoC tests already strong, use-case tests close the middle-layer gap and reduce regression risk when repository behavior changes.

## PR and Issue templates

This repository already contains contribution templates and they remain usable for follow-up work:

- PR template: `.github/PULL_REQUEST_TEMPLATE.md`
- Issue templates:
  - `.github/ISSUE_TEMPLATE/bug_report.md`
  - `.github/ISSUE_TEMPLATE/feature_decision.md`
