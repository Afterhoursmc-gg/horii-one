# Security Principles

- H0RII ONE stores device credentials in iOS Keychain.
- H0RII CORE stores only token hashes, never plaintext tokens.
- AI tool execution is allowlisted through Tool Registry, never arbitrary shell.
- Do not log tokens, API keys or credentials.
- PWA camera node must visibly show camera/mic active state and respect browser/iOS suspension.
