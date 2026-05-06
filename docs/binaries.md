# Binary Reference

Full per-binary documentation for all 24 tools shipped in `v0.1.0`. Each entry covers purpose, common usage, key flags, and which ecosystem layer it sits in.

## Core (3)

### `sauce`
The orchestrator CLI. Top-level entry point for `init`, `route`, `serve`, `mrc`, `pipeline`, `registry`, `mcp`. Driven by [`crates/sauce`](https://github.com/Diatonic-AI/opensauce/blob/main/docs/sauce-protocol.md) in the framework.

```sh
sauce --version
sauce init --scope project --profile dev
sauce mrc list
sauce route classify <input>
```

### `sauce-mcp`
MCP server runtime. Hosts the canonical Sauce MCP servers (ast, codegraph, embed, graph, store, timeline) over stdio + HTTP/SSE. Consumable by any MCP client (Claude Code, Continue, Cursor, Aider, custom).

```sh
sauce-mcp serve --port 7100 --service ast
```

### `sauce-registry`
Plugin/skill/MCP registry resolver. Reads the public registry indexes at [`registry/`](../registry/) and resolves capability requests to concrete extension entries.

```sh
sauce-registry list plugins
sauce-registry resolve --capability fs_read --kind tool
```

---

## Pipeline (2)

### `sauce-pipeline`
Generic LM Studio pipeline. Walks a target directory, chunks, dispatches each chunk via `lmswarm route` to a task class, assembles output.

```sh
sauce-pipeline --target ~/code/myapp --task code.patterns.classify
sauce-pipeline --target . --task ontology.synthesize --output ontology.md
```

Key flags: `--include "*.rs,*.md"` · `--exclude "target,node_modules"` · `--max-chunk-tokens 2800` · `--per-chunk-out-tokens 4096`.

### `sauce-tok`
Exact BPE token counter via `dusa-token::Tokenizer::cl100k()`. Replaces 4-chars/token estimators with real counts for budget packing.

```sh
sauce-tok --count crates/lmswarm-mrc/src/run.rs    # → integer
sauce-tok --text "hello world"                     # → 2
```

---

## Task-pinned generalists (3)

Each is a 3-LOC binary over `sauce_pipeline::run_with_bound_task("<class>")` — same CLI surface as `sauce-pipeline` but with `--task` compile-time bound.

| Binary | Bound task | Purpose |
|---|---|---|
| `sauce-classify` | `code.patterns.classify` | Classify code patterns across a target |
| `sauce-ontology` | `ontology.synthesize` | Synthesize a hierarchical taxonomy |
| `sauce-extract` | `entity.extract` | Extract entities (functions, types, modules) |

Example:
```sh
sauce-classify --target ~/code/myapp     # equivalent to: sauce-pipeline --task code.patterns.classify --target ...
```

---

## Cartography (16)

These map a codebase or filesystem into specific kinds of typed knowledge. Each is a 3-LOC `sauce_pipeline::run_with_bound_task("<class>")` binary.

| Binary | Bound task | Output shape |
|---|---|---|
| `sauce-cart-fs-inventory`     | `fs.classify`               | File-classification table |
| `sauce-cart-deps-roles`       | `deps.role.classify`        | Per-dependency role labels |
| `sauce-cart-ts-types`         | `ts.types.extract`          | TypeScript types + locations |
| `sauce-cart-sql-schema`       | `sql.schema.extract`        | Tables + columns + foreign keys |
| `sauce-cart-routes-map`       | `frontend.routes.extract`   | Frontend route → handler map |
| `sauce-cart-api-surface`      | `api.surface.extract`       | API endpoints + verbs + schemas |
| `sauce-cart-configs-canon`    | `config.parse`              | Canonicalized configuration |
| `sauce-cart-docs-canon`       | `docs.canon.extract`        | Canonical documentation graph |
| `sauce-cart-patterns`         | `code.patterns.extract`     | Recognized patterns (singletons, builders, …) |
| `sauce-cart-standards`        | `code.standards.extract`    | Detected coding-standard adherence |
| `sauce-cart-lexicon`          | `lexicon.aggregate`         | Domain vocabulary index |
| `sauce-cart-taxonomy`         | `taxonomy.synthesize`       | Term → parent → definition tree |
| `sauce-cart-ontology`         | `ontology.synthesize`       | Concept ontology bound to repo cartography |
| `sauce-cart-topology`         | `topology.graph`            | Typed nodes + edges |
| `sauce-cart-epistemology`     | `epistemology.synthesize`   | Source-of-truth + evidence graph |
| `sauce-cart-db-rel-graph`     | `db.relationship.graph`     | DB entity relationship graph |

### Composing cartography passes

You typically run the cart binaries in a wave structure — each pass consumes the prior outputs:

```
fs-inventory → deps-roles → patterns → standards
                              ↓             ↓
                         ts-types ──→ sql-schema ──→ db-rel-graph
                              ↓             ↓
                       routes-map → api-surface
                              ↓
                        lexicon → taxonomy → ontology → topology → epistemology
```

See [pipeline.md](pipeline.md) for end-to-end cartography orchestration.

---

## Capability gates

Several builtin tool handlers refuse by default and require explicit opt-in:

| Capability | Handlers | Enable via |
|---|---|---|
| Filesystem write | `fs_write` | `SAUCE_FS_WRITE_OK=1` |
| Shell exec | `bash_run`, `shell_exec` | `SAUCE_BASH_OK=1` |

This is a defense-in-depth measure — the multi-turn loop will see `Denied` errors instead of silently mutating the host.

## Tool-loop ceiling

`SAUCE_MAX_TOOL_TURNS` (default 8, clamped [1, 64]) caps how many `assistant ↔ tool` cycles the loop will run. On hit, returns `RunError::ToolLoopExhausted` with the full call history. Hard ceiling — no retry, no truncation.
