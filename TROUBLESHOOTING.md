# Troubleshooting

## Missing Environment Variable

Use Provider Bridge:

1. Parse provider info.
2. Save to Keychain.
3. Sync Env to launchctl.
4. Sync Env to Codex++ Watcher.

## 401 Invalid Token

Check that the key belongs to your provider and that `base_url` points to the provider's OpenAI-compatible `/v1` endpoint.

## Idle Timeout Waiting For SSE

Try non-stream testing first. If non-stream works but stream fails, the provider may not support streaming Responses API behavior in the same way as OpenAI.

## Plugins Not Visible

Use Local Plugin Snapshot to restore from `~/.codex/plugins/local-snapshot` and regenerate `~/.agents/plugins/marketplace.json`. OAuth plugins may still require authorization.

## Mobile Stuck Thinking

On the phone, fully close ChatGPT, reopen it, go to Codex, choose Mac host / local thread, and create a new thread. Do not choose Cloud.

## Orphan app-server

Use Maintenance > Diagnose Only. If orphan app-server processes are present, generate the cleanup script and review it before running manually.
