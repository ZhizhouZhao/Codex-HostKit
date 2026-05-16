# Codex++ Companion

Codex++ Companion is a macOS helper for Codex++ users. It helps configure OpenAI-compatible provider billing while keeping ChatGPT account login for Codex Mobile remote control. It also backs up/restores local plugin snapshots and checks host readiness.

Important disclaimer: this project does not bypass account eligibility, OAuth authorization, paid access, server-side restrictions, or official plugin access controls. It only manages local configuration, local plugin snapshots, and local host readiness.

## What It Solves

- Keeps ChatGPT login available for Codex Mobile host control.
- Configures local Codex/Codex++ model requests to use an OpenAI-compatible provider.
- Avoids manual `nano`, Terminal, `launchctl`, and plist edits.
- Saves and restores plugins already installed on this Mac.
- Shows simple host readiness diagnostics for mobile/local thread use.

## How The Mobile Billing Bridge Works

Codex Mobile still needs ChatGPT login so the phone can see and connect to your Mac host. Provider billing only follows your local OpenAI-compatible provider when the phone chooses the Mac host / local thread. Cloud threads use server-side ChatGPT behavior and should not be used for this workflow.

## Provider Setup

Paste one of these into Provider Bridge:

- API key only, such as `sk-...`
- URL only, such as `https://example.com/v1`
- JSON, such as `{"key":"sk-...","url":"https://example.com"}`
- cURL with `Authorization: Bearer ...`

The app parses the key, URL, model, normalizes `/v1`, stores the key in Keychain, writes `~/.codex/config.toml`, and can sync `OPENAI_API_KEY` plus `KKRICH_API_KEY` to `launchctl` and the Codex++ watcher plist. Existing config and plist files are backed up before writing.

## Local Plugin Snapshot

The app scans `~/.codex/plugins/cache`, backs it up to `~/.codex/plugins/local-snapshot`, and can generate `~/.agents/plugins/marketplace.json` pointing at the local snapshot. It does not download official restricted plugins or bypass marketplace access. Google/Gmail/Drive OAuth plugins may require reauthorization. Computer Use may still require macOS Screen Recording and Accessibility permissions.

## Safety Notes

- API keys are stored in macOS Keychain and redacted from command output.
- Config writes create timestamped backups first.
- The MVP does not automatically kill Codex or Codex++ processes.
- Maintenance scripts are generated for review instead of being executed automatically.

## Build

Open `CodexPlusPlusCompanion.xcodeproj` in Xcode 26 or newer and run the `CodexPlusPlusCompanion` target. The deployment target is macOS 14+.

Command-line build:

```sh
xcodebuild -project CodexPlusPlusCompanion.xcodeproj -scheme CodexPlusPlusCompanion -configuration Debug build
```

## Troubleshooting

Missing environment variable: save the provider key to Keychain, then use “Sync Env to launchctl” and “Sync Env to Codex++ Watcher”.

401 Invalid token: confirm the key belongs to the selected provider and the base URL ends with `/v1`.

Idle timeout waiting for SSE: increase provider/server timeout, confirm the provider supports the Responses API, and try non-stream first.

Plugins not visible: restore the local snapshot, generate the local marketplace, then reopen Codex++ normally. OAuth-based plugins may need login again.

Mobile stuck thinking: fully close and reopen ChatGPT on the phone, choose Mac host / local thread, create a new thread, send `Reply only ok`, and check the provider dashboard for a request record.

Orphan app-server: use Maintenance > Diagnose Only, then review the generated orphan cleanup script before running anything manually.
