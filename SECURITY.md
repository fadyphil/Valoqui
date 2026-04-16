# Security Policy

## Scope

Valoqui uses a BYOK (Bring Your Own Key) model. Users supply their own Groq
and Gemini API keys. These keys are stored exclusively in the Android Keystore
via `flutter_secure_storage` and are never transmitted to any Valoqui-controlled
server.

Security issues in the following areas are in scope:

- API key storage or extraction vulnerabilities
- Authentication bypass (Firebase Auth)
- Firestore security rule bypass (unauthorised access to another user's data)
- Unintended key leakage (logs, network traffic, Firestore documents)

## Reporting a vulnerability

Open a GitHub Issue marked **[SECURITY]** or email directly if you prefer not
to disclose publicly. Please include:

- Description of the vulnerability
- Steps to reproduce
- Potential impact

## Out of scope

- Vulnerabilities in third-party services (Groq, Gemini, Firebase) — report
  these to the respective providers.
- Issues on devices where the attacker has physical access and root — Android
  Keystore provides no guarantees in this threat model.
