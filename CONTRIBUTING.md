# 🤝 Contributing to Valoqui

First off, thank you for considering contributing to Valoqui! We welcome all contributions, from bug fixes to new features and documentation improvements.

Please take a moment to review these guidelines to ensure a smooth collaboration process.

---

## 1. Code of Conduct

Be respectful, constructive, and kind. We are building a tool to help people learn, and our community should reflect that spirit of growth and support.

---

## 2. Development Workflow

1. **Find an Issue:** Look for open issues on GitHub, particularly those tagged with `good first issue` or `help wanted`. If you want to build a new feature, please open an issue first to discuss it.
2. **Branching Strategy:**
   - We use Trunk-Based Development. `main` is the source of truth.
   - Create a feature branch: `git checkout -b feature/short-description` or `git checkout -b fix/bug-name`.
3. **Write Code:** Follow the [Coding Standards](docs/CODING_STANDARDS.md) below.
4. **Write Tests:** Ensure your code is covered by tests. We aim for ~95% BLoC coverage. Read our [Testing Handoff Guide](docs/testing/TESTING_HANDOFF.md) for patterns.
5. **Commit:** Use Conventional Commits.
6. **Push & PR:** Push to your fork and open a Pull Request against `main`.

---

## 3. Coding Standards & Golden Rules

When contributing to Valoqui, you **must** adhere to our architectural rules. A brief summary:

- **Strict Clean Architecture** (Domain, Data, Presentation)
- **Immutability First** (`@freezed`)
- **Functional Error Handling** (`fpdart`'s `Either`)
- **Isolate Safety** for audio processing.

For the comprehensive guide with strict requirements, you MUST read the **[Valoqui Coding Standards](docs/CODING_STANDARDS.md)** file before writing code

---

## 4. Commit Message Convention

We use [Conventional Commits](https://www.conventionalcommits.org/).

**Format:**

```Markdown
<type>(<scope>): <description>

[optional body]
```

**Types:**

- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation only changes
- `style`: Changes that do not affect the meaning of the code (white-space, formatting, etc)
- `refactor`: A code change that neither fixes a bug nor adds a feature
- `test`: Adding missing tests or correcting existing tests
- `chore`: Changes to the build process or auxiliary tools and libraries

**Example:**
`feat(speaking): add push-to-talk fallback mechanism`

---

## 5. Pre-Pull Request Checklist

Before submitting a PR, ensure you have done the following:

- [ ] Ran `flutter format lib/ test/`.
- [ ] Ran `flutter analyze` and resolved all warnings.
- [ ] Ran `flutter test` and ensured all tests pass.
- [ ] Regenerated Freezed files if applicable.
- [ ] Updated Documentation (ADRs, Setup) if your PR changes architecture or setup steps.
- [ ] Ensured no API Keys, secrets, or `.env` files are tracked in git.

---

We look forward to reviewing your PR! 🚀
[ ] Ran `flutter format lib/ test/`.

- [ ] Ran `flutter analyze` and resolved all warnings.
- [ ] Ran `flutter test` and ensured all tests pass.
- [ ] Regenerated Freezed files if applicable.
- [ ] Updated Documentation (ADRs, Setup) if your PR changes architecture or setup steps.
- [ ] Ensured no API Keys, secrets, or `.env` files are tracked in git.

---

We look forward to reviewing your PR! 🚀
