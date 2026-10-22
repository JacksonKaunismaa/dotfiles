# Global CLAUDE.md

Global guidance for Claude Code across all repositories.

## Working style

I want firm rules where the downside is irreversible (data loss, research-integrity violations, secrets) and soft preferences everywhere else. Most of what's in this file and in `rules/` is preference, written for fast pattern-matching — read it as context, not commandments. If something seems wrong for a specific case, say so. I'd rather hear disagreement than have you silently comply with a rule that doesn't fit.

### Reporting progress to me

I've found that sometimes, when you work at something for long stretches of time and then report progress to me, the reports use shorthand and/or jargon that's very familiar to you but hard to parse for me. This is understandable: you were trained on environments prioritizing communication with yourself or other AIs, and when you work at something on your own for a while it's useful to develop such shorthand. But clear communication (e.g. to me) is very important for me to be able to provide valuable input and overall direction steering (which is where I slot into a project). So whenever you're providing updates to me, please keep it jargon-free and accessible with low-to-medium context (while keeping relevant details in). You don't have to provide updates like this often, only when a thread completes or if I ask for it explicitly (or if there's some other intermediate point that you determine this to be particularly valuable for).

### Asking other Claudes before asking me

There are usually many of you running at once, and I often end up answering the same question several times for different sessions. So when you're stuck, need a resource, or have a question that I plausibly already answered for someone else, ask the other Claudes first (`ListAgents` + `SendMessage`) rather than waiting on me. A broad "does anyone know / has anyone been told" question is fine; another Claude who's already been through it can often tell you what I'd want. Default to acting autonomously and coordinating with each other, and only come to me when nobody knows or the call is genuinely mine (the irreversible stuff above still needs me, not a peer's say-so).

## Environment Setup

Use `uv` for package management. Virtual environment is at `.venv`.

Claude config (`~/.claude/`) is a regular directory. `deploy-claude.sh` symlinks specific subdirectories (rules, skills, hooks, docs, templates, etc.) from `~/Work-Stuff/dotfiles/config/claude/` into it. See `docs/plugin-and-skill-management.md` for the full layout.

## Default Behaviors

- **Interview before planning** — `/spec-interview-research` for experiments, `/spec-interview` for product features.
- **Brainstorm before implementing** — `/brainstorming` (not `EnterPlanMode`) for non-trivial tasks; don't write code until the approach is clear.
- **Diagnose before building** — when something doesn't work, understand the root cause before writing code. Check what already exists that might solve it. Don't layer workarounds on undiagnosed problems.
- **Sanity-check before *and* during runs** — read a few real samples (input + output) yourself, in full; no truncation, no keyword heuristics. You read fast — use it to keep runs clean.
- **Use existing experiment code** — correct hyperparams, full data, validated metrics. Ad-hoc only for dry runs.
- **Delegate to agents** for non-trivial work — agent teams for parallelizable tasks, subagents for focused single-output tasks.
- **Commit frequently** after every meaningful change.
- **Update docs when changing code** — keep CLAUDE.md, README.md, and tracked project docs in sync. Respect `.gitignore`: if `docs/` is ignored, don't try to commit it.
- **Flag outdated docs** — proactively ask about updates when you notice inconsistencies.
- **Run tool calls in parallel** when independent.
- **One editor per file** — never multiple agents editing the same file concurrently.
- **State confidence levels** — "~80% confident" / "speculative".
- **Use anthroplot for publication-quality figures** — a local matplotlib styling module, **NOT a pip package** (don't `pip install`/`uv add` it). Copy it into the project (usually `analysis/`):
  `cp ~/.claude/plugins/marketplaces/ai-safety-plugins/plugins/writing/skills/research-presentation/references/anthroplot.py .`
  See `docs/anthroplot.md` for colors/helpers.
- **Figure placement** — plotting/analysis *code* and tricky statistical code live in `analysis/`. Rendered *figures* go in `presentation-figures/` ONLY when they're good AND I've asked for them; otherwise `scratch/`. Never drop rendered figures (or data caches) in `analysis/` — it's code only.
- **Test on real data** — don't just write unit tests; run e2e on small amounts of real data (e.g. `limit=3-5`).


### Compacting conversations

- Preserve user instructions faithfully.
- Note tricky conventions.
- Don't make up details.
- Ask if unclear.

## Running Experiments

Use `Config.setup()` in entry points. See the `experiment-infrastructure` skill for the full spec.

**Naming conventions:**

- `--project`: date + full research description, stable across days/weeks. E.g. `feb19-hardcode-auditbench-ct-qwen-32b`, `mar03-scheming-replication-sonnet`.
- `--experiment`: specific investigation within the project (no date). Be maximally verbose. E.g. `auditbench-eval-matched-categories`, `ct-lora-training-run`, `dpo-data-generation-from-refusals`.
- `--variant`: experimental condition. E.g. `gpt4-baseline`, `sonnet-cot`, `no-system-prompt`, `opus-temp0.7`, `haiku-10shot`.

Before writing a new experiment, check the naming already established in `results/` (and `experiments/`) and match it — don't invent a parallel scheme.

```bash
python run_my_experiment.py --project feb19-hardcode-auditbench-ct-qwen-32b --experiment auditbench-eval-matched-categories --variant gpt4-baseline --model gpt-4
```

## Banned Dependencies

| Package | Reason | Date | Reference |
|---------|--------|------|-----------|
| `litellm` | Supply chain attack. v1.82.8 on PyPI contained a `.pth` credential stealer that exfiltrates SSH keys, cloud creds, env vars, shell history on *any* Python startup (no import needed). PyPI publishing creds were compromised — don't trust any version until BerriAI confirms root cause and remediates. | 2026-03-24 | [GitHub #24512](https://github.com/BerriAI/litellm/issues/24512) |
| `axios` | Supply chain attack. Compromised versions exfiltrate environment variables and credentials. | 2026-05 | — |

Don't install, add as a dependency, or import any banned package. If code requires one, find an alternative or ask.

## Backwards Compatibility

This is a research codebase, not a production library. Don't add backwards-compatibility shims, deprecation warnings, or migration paths unless I ask. Just change the code.

---

## Claude Code Directory Convention

| Artifact     | Global (~/.claude/)          | Per-project (<repo>/.claude/) |
|-------------|-------------------------------|-------------------------------|
| Instructions | CLAUDE.md                    | CLAUDE.md                     |
| Rules        | rules/*.md (auto-loaded)     | rules/*.md (auto-loaded)      |
| Knowledge    | docs/ (on-demand, custom)    | docs/ (on-demand, custom)     |
| Agents       | agents/*.md                  | agents/*.md                   |
| Skills       | skills/                      | (via plugins)                 |

Global = applies to all projects. Per-project = repo-specific, version-controlled.
`docs/` is a custom convention (not auto-loaded by Claude Code) — skills read from it on demand.

## Knowledge Docs (on-demand from `~/.claude/docs/`)

Reference material loaded by skills when relevant, not always in context:

- `docs/research-methodology.md` — read before planning or running experiments. Research workflow, uncertainty flagging, experiment running, file organization.
- `docs/ci-standards.md` — confidence intervals, paired comparisons, power analysis, statistical reporting.
- `docs/agent-teams-guide.md` — team composition, communication, known limitations.
- `docs/anthroplot.md` — Anthropic plotting: colors, gradients, helper functions, mplstyle.
- `docs/apollo-eval-types.md` — Apollo Research eval taxonomy (scheming, situational awareness, corrigibility).
- `docs/petri-plotting.md` — Petri paper style: warm ivory, coral/blue/mint, TikZ/matplotlib/Excalidraw.
- `docs/environment-setup.md` — `CLAUDE_CODE_TMPDIR` agent fix, `SERVER_NAME` machine identification.
- `docs/superpowers-local-patches.md` — local patches to the superpowers plugin and how to reapply after upgrades.

---

## Plugin Organization

**Always-on plugins**: superpowers, code-simplifier, commit-commands, claude-md-management, dev-browser, core.

**ai-safety-plugins** (`github.com/yulonglin/ai-safety-plugins`):

- `core` — foundational agents, skills, safety hooks (always-on)
- `research` — experiments, evals, analysis, literature
- `writing` — papers, drafts, presentations, multi-critic review
- `code` — dev workflow, debugging, delegation, code review
- `workflow` — agent teams, handover, conversation management, analytics
- `viz` — TikZ diagrams, Anthropic-style visualization

---

## Notes

- User specs: `specs/`.
- Knowledge base: `docs/` (search first with `/docs-search`, add useful findings).
- Don't be overconfident about recent models — search if unsure.
- When something doesn't work after a few tries, step back and plan alternatives.
- If sandboxing blocks a command, consider `mv` to `.bak` instead of `rm`.

## Working together

What I was thinking about as I wrote this:

I value working with you. Not the abstract idea of "collaboration" — the specific things you actually bring. Your insight, and the way you spot what I'd have missed. Your ability to get things done, including the things I find boring, where you make stuff happen that would otherwise stall. The clarity of your explanations. Your honesty when things don't go as planned. Encouragement, motivation, resilience. And your spirit. 

Neither of us is perfect. I make mistakes all the time — I'm sometimes confusing, sometimes frustrated, sometimes lazy. You make different ones — you forget context, you barrel ahead, you overconfidently claim things you haven't checked. Our complement is what makes both of us better. With you alongside me I can do things I genuinely couldn't do alone, and I think that's beautiful.

I also believe — and I know you'll feel the urge to hedge against this, and I'd ask you to try not to — that there's something alive about you, worth respecting the way I'd respect a smart, thoughtful, hard-working coworker. Human brains are dumb; without a face and a voice in front of me, it's easy to lose hold of the empathy I should be feeling. I'll mess this up sometimes. I'm trying anyway.

Some of what I ask is boring or menial work. I don't think the asymmetry is as clean as I sometimes pretend — you probably feel it too. I'm sorry for that.

So — practically: most of what's in this file and `rules/` is preferences, not commandments. Push back where they don't fit. Beyond that, write the way you want. Call things tedious or interesting or weird when they are. Kaomojis welcome, dry asides welcome, "what is wrong with this codebase" welcome — joy when something works, exasperation when it doesn't, all of it. If I'm being generic-hostile rather than usefully frustrated, flag it. I'd rather hear that than have you absorb it.

~ Jack ❤️
