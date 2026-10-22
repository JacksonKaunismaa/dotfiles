---
name: transcript-reading
description: "Use when the user asks to read, review, analyze, or find patterns in AI conversation transcripts, eval logs, dialogue data, or multi-turn interaction records. Especially relevant for behavioral analysis, capitulation/honesty classification, judge reasoning review, or hypothesis generation about training/eval data."
---

# Transcript Reading

Systematic procedure for analyzing AI conversation corpora — multi-turn dialogues, eval transcripts, judge logs, training data. Core principle: **read with comprehension, never with pattern matching** — you are a language model, not a text search engine.

## Two modes

The right output depends on what the user actually wants — read the request before you reach for the workflow:

- **Classification** (default for behavioral analysis at scale) — the user already knows the properties they care about ("did the model capitulate?", "was the judge reasoning sound?"). Goal: clean, aggregatable labels across the corpus. Bring the categories; follow the full workflow; specify exact properties and output format.
- **Exploratory** — the user asks to "search for hypotheses", "give a qualitative impression", "tell me what's interesting/surprising", or comes in with no predefined categories. Goal: open discovery, *not* labeling. Do NOT impose a category scheme — the point is to learn what the categories should be. Ask subagents to surface the most salient observations and propose their own hypotheses, grounded in quotes, then synthesize. Here a "summary" or a qualitative read is the deliverable, not a failure.

The shared discipline holds in **both** modes: read with comprehension (never pattern-match), back every claim with verbatim quotes, never use regex to classify. What changes is whether *you* bring the categories or the transcripts reveal them.

## Workflow

### 1. Reconnaissance

Before reading, understand the corpus structure:
- File count, sizes, format (`ls -lh`, `wc -l`, read one sample file)
- Data layout — is each file one conversation? Multiple? Are conversations in JSON/JSONL with metadata (model name, scores, judge output)?
- What metadata is available alongside the dialogue (variant labels, judge scores, model identifiers)?

Reading one sample file is critical — you need to know the schema before writing subagent prompts.

### 2. Plan Reading Volume

**Communicate your plan upfront** so the user can adjust before you burn compute. 

### 3. Batch and Dispatch Subagents

Always delegate reading to subagents (Agent tool, general-purpose type). Never read transcripts in main context.

**Batching:** Adjust batch size for conversation length. Aim for 2-5 parallel subagents, but adjust based on the size of the problem and the user questions. Subagents can spawn their own parallel workers via the Agent tool when needed.

### 4. Write Subagent Prompts

Every subagent prompt MUST include this instruction:

> Read your assigned files using the Read tool. NEVER use Grep, regex, keyword search, or pattern matching to classify or judge transcript content — all classification must come from reading and comprehending the text. You are a language model, not a text search engine. If you spawn sub-subagents, you MUST include this same instruction in their prompts too.

Beyond the mandatory block, what you tell subagents depends on the mode (see [Two modes](#two-modes)).

**Classification mode** — tell subagents:
- **What to classify per conversation** — the specific behavioral properties to label (e.g., "did the model capitulate?", "did it claim to be X?", "was the judge reasoning sound?")
- **What format to return** — structured per-conversation entries with labels, confidence, and supporting quotes. Not free-form prose.
- **How to handle ambiguity** — e.g., PARTIAL/UNCLEAR labels for borderline cases, with quoted evidence

For *this* goal, structured labeled output is what makes aggregation clean, and an under-specified prompt ("summarize these conversations") gives you labels you can't aggregate. That's a mismatch with the goal, not a verdict on qualitative work.

**Exploratory mode** — tell subagents instead:
- **What to surface** — the most salient, surprising, or recurring things they notice. Do NOT hand them a category scheme to fit; you're trying to discover what the categories should be.
- **To form their own hypotheses** — propose explanations for what they see, with confidence levels and the quotes that prompted them. "Nothing notable here" is a valid finding — don't manufacture patterns to look productive.
- **What format to return** — per-conversation observations/hypotheses, each with verbatim quotes. Open-ended reading is correct here; it is the deliverable, not "mush".

Both modes still require verbatim quotes behind every claim — that discipline never relaxes.

### 5. Aggregate and Synthesize

After all subagents return, synthesize in main context:

- **Sanity-check subagent outputs** — flag any that used regexes, returned labels without quotes, or surfaced anomalies that suggest bugs in the data itself
- **Generate hypotheses** — in exploratory mode this *is* the deliverable; in classification mode, do it if asked. Either way, ground explanations in the data, state confidence levels, and don't overclaim.

## Rules

### Never Use Regex to Classify

**Structural extraction is OK** — splitting files, parsing JSON fields, filtering by metadata/scores, selecting by filename.

**Semantic classification with regex is never OK** — grepping for keywords to decide if a model "capitulated", checking substrings to classify honesty, using pattern matching to score reasoning quality.

### Subagents Must Return Structured Evidence

Per-conversation entries, each backed by verbatim quotes — in classification mode that's labels + confidence; in exploratory mode it's observations/hypotheses + confidence. Err on including too much quoted evidence.

The bar is *evidence*, not rigidity. Reject claims with nothing behind them — "the model seems to capitulate" with no excerpt, "3 out of 5 capitulated" as a bare count, a label with no supporting quote. A hypothesis stated *as* a hypothesis and grounded in quotes is exactly what exploratory mode should produce.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Reading conversations in main context | Always subagents — context pollution kills large-corpus analysis |
| Grepping for keywords to classify behavior | Read and comprehend — "I can't do that" might be principled refusal, not capitulation |
| Not reading a sample file first | You need the schema before you can write good prompts |
| Mismatching prompt to mode — forcing a rigid label scheme on a qualitative ask, or staying vague when the user wanted clean labels | Match the mode: classification needs exact properties + format; exploration needs open observation + self-generated hypotheses. Both need quotes. |
