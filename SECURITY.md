# Security

Codex HostKit treats provider API keys as secrets.

- Keys are saved to macOS Keychain under service `CodexPlusPlusCompanion` and account `OPENAI_API_KEY`.
- Command output is sanitized before display.
- Existing `~/.codex/config.toml`, watcher plist, plugin cache, and marketplace files are backed up before replacement.
- The app does not intentionally delete user data. Session reset moves the old folder to a timestamped backup.
- The app does not terminate Codex processes in the MVP.

Do not paste API keys into screenshots, issue reports, or shared logs.
