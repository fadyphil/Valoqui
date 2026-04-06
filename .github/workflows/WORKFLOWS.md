# Valoqui GitHub Actions — Setup Guide

## What's Here

Three workflows covering the full CI/CD lifecycle:

| File | Trigger | Purpose |
|---|---|---|
| `ci.yml` | Every push / PR | Blocks merges on broken code |
| `release.yml` | Version tag push | Builds release APK + GitHub Release |
| `dependency-audit.yml` | Weekly (Monday) | Security + staleness check |

---

## One-Time Setup Steps

### 1. Pin your Flutter version
In both `ci.yml` and `release.yml`, replace the `subosito/flutter-action` step with your exact version:

```yaml
- uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.24.0'   # Check with: flutter --version
    channel: stable
    cache: true
```

Pinning prevents a Flutter SDK update from silently breaking your CI.

### 2. Add the google-services.json secret
Your Firebase config must NOT be committed. The build will fail without it.

1. Copy the full content of `android/app/google-services.json`
2. Go to: GitHub repo → Settings → Secrets and variables → Actions → New repository secret
3. Name: `GOOGLE_SERVICES_JSON`
4. Value: paste the file content (not base64, just raw JSON)
5. In `ci.yml` and `release.yml`, uncomment the "Write google-services.json" step

### 3. Add API key secrets (if dart-define is used)
If Groq/Gemini keys are injected at build time via `--dart-define`, add them as secrets
and pass them in the build step:

```yaml
- name: Build debug APK
  run: flutter build apk --debug
    --dart-define=GROQ_API_KEY=${{ secrets.GROQ_API_KEY }}
```

### 4. Enable branch protection rules (makes CI meaningful)
Go to: GitHub repo → Settings → Branches → Add branch ruleset for `main`:
- ✅ Require a pull request before merging
- ✅ Require status checks to pass: `Code Quality`, `Tests & Coverage`, `Build Debug APK`
- ✅ Require branches to be up to date before merging

Without this, the CI runs but nothing stops you from merging broken code.

---

## Coverage Threshold Roadmap

The threshold in `ci.yml` starts at 20% because you currently have no tests.
Treat this as a ratchet — only move it up, never down.

| Milestone | Threshold | What should be tested |
|---|---|---|
| Now (Sprint 2 bugs fixed) | 20% | Nothing required yet |
| Sprint 3 complete | 40% | SpeakingBloc event handlers, ReportBloc |
| Post-MVP | 60% | Datasource dispose/re-init, critical use cases |

The "Speak Again" integration test from the handoff counts toward this threshold once written.

---

## Commit Message Convention (Feeds Release Notes)

The `release.yml` uses `generate_release_notes: true`, which pulls from your commit messages
between tags. Conventional Commits make this readable automatically:

```
feat: add network RTT check on session start
fix: kill isolate on STT datasource dispose
refactor: extract LLM+TTS pipeline to ConversationOrchestrator
docs: add testing strategy for datasource lifecycle
```

GitHub will group these by type in the auto-generated release notes.

---

## Release Tagging Workflow

```bash
# 1. Update pubspec.yaml version (must match the tag)
#    version: 0.3.0+1

# 2. Commit the version bump
git add pubspec.yaml
git commit -m "chore: bump version to 0.3.0"

# 3. Push and tag
git push origin main
git tag v0.3.0
git push origin v0.3.0

# The release.yml workflow triggers automatically.
```

---

## Design Decisions

**Why three separate jobs in ci.yml?**
`quality → (test + build in parallel)`. If formatting fails, there's no point
running tests. But once formatting passes, tests and the APK build can run
concurrently, keeping total pipeline time down.

**Why run `build_runner` in CI even though output is committed?**
The staleness check catches the case where someone edits a `@freezed` class and
forgets to regenerate. Without this check, `flutter analyze` would fail with a
cryptic error about a missing `.freezed.dart` file, and the developer wastes time
figuring out why.

**Why `continue-on-error: true` on the outdated packages step?**
`dart pub outdated` exits with a non-zero code if anything is outdated. That would
fail a non-blocking informational step, which defeats the purpose. You want to see
the output, not have the workflow fail silently because a patch version exists.

**Why separate jobs for tests and build instead of one job?**
If tests fail and the build also fails, you want to know both, independently,
in the same run. Combined jobs stop at the first failure, hiding the second.
GitHub Actions shows job-level status in the PR check list — two named failures
are more diagnostic than one.
