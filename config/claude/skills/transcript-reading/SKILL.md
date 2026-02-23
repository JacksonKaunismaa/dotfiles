---
name: transcript-reading
description: "Reading and analyzing transcript files. Use when the user asks to read, review, summarize, or analyze transcripts, interview logs, or conversation records."
---

# Transcript Reading

Procedure for reading transcript files thoroughly and accurately.

## Core Principles

### 1. Never Skip Samples

If the user asks you to read every sample, entry, or segment in a transcript, **read every single one**. Do not summarize, do not skip "similar" entries, do not say "and N more like this." The user is asking for exhaustive coverage because they need it.

### 2. Use Subagents to Read

Always delegate transcript reading to subagents (Task tool with Explore or general-purpose type). This serves two purposes:
- Keeps the main conversation context clean for analysis and discussion
- Allows parallel reading of multiple files or sections

### 3. Subagents Must Return Full Context

**This is the most important rule.** Subagent results must include:
- **Full sentences and paragraphs**, not snippets or fragments
- **Generous surrounding context** so quotes are understandable on their own
- **Speaker attribution** when available
- **Enough text** that someone reading only the subagent's output can understand what was said. err on the side of including too much context

**NEVER** return results like:
- "The speaker mentions concerns about..." (vague paraphrase)
- "...related to safety..." (fragment without context)
- "Lines 45-67 discuss X" (reference without content)

**ALWAYS** return results like:
- Full paragraphs with an abundance of surrounding context

### 4. NEVER Use Keyword/Regex Search — READ the Transcript

**This is non-negotiable.** When instructed to read a transcript, you must **actually read it sequentially** using the Read tool. You are a language model — your job is to read and comprehend, not to run text searches.

**NEVER do any of the following:**
- Use Grep, rg, or any regex/keyword search on transcript content
- Search for keywords and only return matching lines
- Use regex patterns to find "relevant" sections
- Skip sections that don't match a search term
- Pre-filter content based on what you think matters
- Use any tool other than Read to access transcript content

**Why this matters:** Keyword search is catastrophically brittle for transcripts. It misses paraphrases, context, indirect references, and anything not phrased exactly as expected. It catches false positives. It defeats the entire purpose of using a subagent to read with comprehension. A transcript subagent that uses Grep is doing the job wrong — it's a glorified text search, not a reader.

**The correct approach:** Use the Read tool to read the transcript sequentially (in sections if large). Comprehend the content as you read. Extract what was asked for based on understanding, not pattern matching.

## Procedure

1. **Identify all transcript files** the user wants read
2. **Launch subagents** to read the files (one per file, or split large files into sections)
3. **Instruct each subagent clearly** — the prompt MUST include all of these instructions:
   > Read the full transcript using the Read tool. NEVER use Grep, rg, or any keyword/regex search on transcript content — read it sequentially and comprehend it. Return [what the user asked for] with full sentences and paragraphs, not snippets. Include speaker attribution and surrounding context for every point you extract.
4. **Synthesize** the subagent results in the main conversation
5. If the user asked for exhaustive coverage, **verify nothing was skipped** before presenting results
