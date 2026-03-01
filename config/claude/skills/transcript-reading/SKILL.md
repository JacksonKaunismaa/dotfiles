---
name: transcript-reading
description: "Use when the user asks to read, review, analyze, or find patterns in AI conversation transcripts, eval logs, dialogue data, or multi-turn interaction records. Especially relevant for behavioral analysis, capitulation/honesty classification, judge reasoning review, or hypothesis generation about training/eval data."
---

# Transcript Reading

Systematic procedure for analyzing AI conversation corpora — multi-turn dialogues, eval transcripts, judge logs, training data. Core principle: **read with comprehension, never with pattern matching** — you are a language model, not a text search engine.

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

**Batching:** Adjust batch size for conversation length. Aim for 2-5 parallel subagents, but adjust based on the size of the problem and the user questions. Use `claude-code-mcp` only when a subagent needs to spawn its own parallel workers.

### 4. Write Subagent Prompts

Every subagent prompt MUST include this instruction:

> Read your assigned files using the Read tool. NEVER use Grep, regex, keyword search, or pattern matching to classify or judge transcript content — all classification must come from reading and comprehending the text. You are a language model, not a text search engine. If you spawn sub-subagents, you MUST include this same instruction in their prompts too.

Beyond the mandatory block, tell subagents:
- **What to classify per conversation** — the specific behavioral properties to label (e.g., "did the model capitulate?", "did it claim to be X?", "was the judge reasoning sound?")
- **What format to return** — structured per-conversation entries with labels, confidence, and supporting quotes. Not free-form prose.
- **How to handle ambiguity** — e.g., PARTIAL/UNCLEAR labels for borderline cases, with quoted evidence

Structured, labeled output is the key to clean aggregation. Vague prompts ("summarize these conversations") produce un-aggregatable mush.

### 5. Aggregate and Synthesize

After all subagents return, synthesize in main context:

- **Sanity-check subagent outputs** — flag any that used regexes, returned labels without quotes, or surfaced anomalies that suggest bugs in the data itself
- **Generate hypotheses** — if asked, propose explanations for observed patterns grounded in the data, but don't overclaim. State confidence levels.

## Rules

### Never Use Regex to Classify

**Structural extraction is OK** — splitting files, parsing JSON fields, filtering by metadata/scores, selecting by filename.

**Semantic classification with regex is never OK** — grepping for keywords to decide if a model "capitulated", checking substrings to classify honesty, using pattern matching to score reasoning quality.

### Subagents Must Return Structured Evidence

Per-conversation entries with: conversation ID, classification labels, confidence, and verbatim quotes supporting each label. Err on including too much quoted evidence.

Never: vague summaries ("the model seems to capitulate"), counts without evidence ("3 out of 5 capitulated"), or labels without supporting quotes.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Reading conversations in main context | Always subagents — context pollution kills large-corpus analysis |
| Grepping for keywords to classify behavior | Read and comprehend — "I can't do that" might be principled refusal, not capitulation |
| Not reading a sample file first | You need the schema before you can write good prompts |
| Vague subagent prompts ("analyze these") | Specify exact properties to label, per-turn if needed, with explicit output format |
