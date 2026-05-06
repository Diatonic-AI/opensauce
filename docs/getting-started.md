# Getting Started

After [installing](user-install.md), here's the first 5 minutes.

## 1. Verify install

```sh
sauce --version
sauce-pipeline --help
sauce-tok --text "hello world" --count
```

You should see version output, the `sauce-pipeline` argument list, and `2` (token count for "hello world" under cl100k BPE).

## 2. Initialize per-user state

```sh
sauce init --scope user --profile dev
```

This creates:
- `~/.config/sauce/sauce.toml` — your config
- `~/.local/share/sauce/` — persistent state
- `~/.cache/sauce/` — regenerable cache

## 3. Start LM Studio

Sauce dispatches inference to a local [LM Studio](https://lmstudio.ai). Install it, load a tool-capable model (recommended starter: `nvidia/nemotron-3-nano-4b`), and confirm it's listening:

```sh
curl -s http://localhost:1234/v1/models | head
```

Override the endpoint via:
```sh
export LMSTUDIO_BASE_URL=http://your-host:1234
```

## 4. Run your first pipeline

`sauce-pipeline` walks a directory, chunks, dispatches each chunk to LM Studio with a task class, and assembles results.

```sh
sauce-pipeline --target ~/code/some-project --task code.patterns.classify
```

Output lands at `deliverables/pipeline-<ts>-<task>.md` by default.

## 5. Try a task-pinned binary

The 19 task-pinned binaries (3 generalists + 16 cartography) are bound to a specific task class:

```sh
sauce-cart-fs-inventory --target ~/Downloads
sauce-cart-sql-schema --target ~/code/myapp/migrations
sauce-classify --target ~/code/myapp/src
```

See [`binaries.md`](binaries.md) for the full reference.

## 6. (Optional) Enrol with an enterprise control node

If your install is part of an enterprise deployment, your operator will give you an enrollment token:

```sh
sauce enroll --token $ENROLLMENT_TOKEN
```

After enrollment, your install registers with the enterprise control node and (transitively) with Sauce Global for license + version reconciliation.

## Next

- 🆘 Stuck? → [`troubleshooting.md`](troubleshooting.md)
- 🏢 Standing up an enterprise control node? → [`enterprise-install.md`](enterprise-install.md)
- 📦 Curious about each binary? → [`binaries.md`](binaries.md)
