# Hobbyist Quickstart

> **Audience: hobbyist / power-user persona.** You've installed Sauce
> via [`user-install.md`](user-install.md). Now you want to *extend* it.
> You're already touching L11 (delivery) and L12 (user surfaces); this
> guide adds **L7 (Cognition — local model)** and **L8 (Agency — skills,
> plugins, MCP servers)**. Persona map: framework repo
> `docs/architecture/install-ladder.md`.

You don't need a cloud account, an API key, or a credit card. Everything
in this guide runs locally on the box where you installed Sauce.

---

## What you're adding

Sauce is a 12-layer stack. The full contract lives in the framework repo
at `docs/architecture/layer-stack.md`. As a hobbyist you only need two
new layers:

| Layer | What it is | Why you care |
|---|---|---|
| **L7 · Cognition** | Where models actually run — locally via LM Studio, or remotely via cloud bridges. | Sauce dispatches inference here. Without an L7 endpoint the higher layers have nothing to reason with. |
| **L8 · Agency** | The contract surface for AI agents — MCP servers, skills, plugins. | This is where *your code* plugs in to make sauce do new things. |

L1–L6 (substrate, OS, paths, storage, indexing, semantics) and L9–L10
(mesh, governance) are managed for you. You don't have to think about
them until you graduate to enterprise operator.

---

## Step 1 — Run a local model (L7)

Install [LM Studio](https://lmstudio.ai) (free, cross-platform). Load
*any* tool-capable instruct model that fits in your VRAM. LM Studio's
catalog flags compatible models; pick one and download it.

Start LM Studio's local server (usually `http://localhost:1234`).
Confirm Sauce can see it:

```sh
sauce-pipeline --help
```

If `sauce-pipeline` lists an LM Studio backend, you're good. The exact
flag set varies per Sauce release — read what `--help` prints, not what
the internet tells you.

> **Why local first.** L7 is the only Sauce layer permitted to hold
> model state. Everything above L7 is a *contract surface* — your
> skills and plugins describe what they want, the L7 layer decides how
> to satisfy it. A local pool means no API keys, no per-token billing,
> and no data leaving your machine.

---

## Step 2 — Use an existing skill

```sh
sauce skill list
sauce skill run <skill-name>
```

Skills are the smallest reusable unit at L8. They have a `SKILL.md`
front-matter that declares trigger phrases, required tools, and the
work the skill performs. Sauce loads them dynamically at runtime; you
don't recompile to add one.

---

## Step 3 — Author your first skill

Skills can be authored as Rust crates (against `sauce-skill-sdk`) or as
plain shell scripts with a `SKILL.md` header. The shell path is the
fastest way in.

The SDK lives in the framework repo at `crates/sauce-skill-sdk/`.
The SDK ships a stub API surface today; method bodies are placeholders.
The contract shape (the `Skill` trait, `SkillManifest`, input/output
envelopes) is stable for early authoring; runtime execution lands in a
later release. Track the crate's `CHANGELOG.md` for status.

The shape of every skill is the same:

1. A `SKILL.md` declaring metadata (name, description, triggers, tools).
2. An entry point (Rust `fn run(...)` or a shell `run.sh`).
3. A registration in your local skill index so `sauce skill list` finds it.

---

## Step 4 — Author a plugin

Plugins are heavier than skills — they extend Sauce itself rather than
adding a single workflow. Use a plugin when you need to register new
commands, hook into the orchestrator lifecycle, or expose a long-lived
service.

The SDK lives in the framework repo at `crates/sauce-plugin-sdk/`.
Plugin authoring follows the same "describe in metadata, implement
behind a trait" pattern as skills. The SDK ships a stub API surface
today; method bodies are placeholders. The contract shape (the
`Plugin` trait, `PluginManifest`, ABI version constants) is stable for
early authoring; runtime execution lands in a later release. Track the
crate's `CHANGELOG.md` for status.

---

## Step 5 — Write an MCP server

[Model Context Protocol](https://modelcontextprotocol.io) is the
standard agent-tool protocol. Sauce is fully MCP-native at L8 — every
skill, plugin, and tool is reachable via MCP.

If you have something Sauce doesn't expose yet (a private API, a custom
data source, a domain-specific tool), wrap it as an MCP server. The SDK
lives in the framework repo at `crates/sauce-mcp-sdk/`. Sauce will
discover and bind to your server through its registry. The SDK ships a
stub API surface today; method bodies are placeholders. The contract
shape (the `McpServer` / `McpClient` traits, `McpServerManifest`,
transport variants) is stable for early authoring; runtime execution
lands in a later release. Track the crate's `CHANGELOG.md` for status.

---

## Where this leads

You graduate out of the hobbyist tier when:

- You're managing **multiple users** on the same workspace, or
- You need **audit trails / SSO / data-residency** for compliance, or
- You're running across **multiple machines** with shared state.

At that point you're an enterprise operator — see
[`enterprise-install.md`](enterprise-install.md). You'll pick up L9
(orchestration / mesh) and L10 (governance / policy / identity / audit)
as new layers to think about.

If instead you want to **contribute to Sauce itself** — add a backend at
L4, a graph engine at L6, a scheduler at L9 — you're a framework
contributor. The framework repo's `docs/architecture/` is the entry
point.

---

## Cross-references

- [`user-install.md`](user-install.md) — how you got here
- [`getting-started.md`](getting-started.md) — first 5 minutes after install
- [`enterprise-install.md`](enterprise-install.md) — the next tier up
- Framework repo `docs/architecture/layer-stack.md` — the canonical L1–L12 contract
- Framework repo `docs/architecture/install-ladder.md` — the persona map
- [LM Studio](https://lmstudio.ai) — local model runtime
- [Model Context Protocol](https://modelcontextprotocol.io) — the agent-tool protocol Sauce speaks

---

*This guide is part of OpenSauce — the public install surface. It
covers L7+L8 conceptually only; implementation detail for any layer
lives behind the binary boundary in the framework repo.*
