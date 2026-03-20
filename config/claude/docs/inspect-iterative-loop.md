---
name: inspect-iterative-loop
description: "Explains how to structure iterative pipelines (red-teaming, realism editing, refinement loops) so all model calls appear in a single Inspect AI transcript. Use when: user asks about getting multiple iteration steps into one transcript, building a pipeline with repeated model calls, mentions 'iterative', 'refinement loop', or 'red team iteration', or is confused about fragmented transcripts."
---

# Inspect Iterative Pipeline Skill

## Pattern Overview

The key insight: **run the entire iteration loop inside a single solver's `solve()` function**.

Inspect records all `model.generate()` calls made during a sample's processing. If you structure your iterations as separate tasks or samples, you get fragmented transcripts. Keep everything in one solver loop.

```
┌─────────────────────────────────────────────────────┐
│  iterative_solver (single solve() call)            │
│                                                     │
│  for iteration in range(max_iterations):           │
│    1. model_a.generate() → output_a                │
│    2. model_b.generate() → feedback on output_a    │
│    3. model_c.generate() → refined input           │
│    4. append to history                            │
│    5. check termination condition                  │
│                                                     │
│  state.metadata["history"] = history               │
└─────────────────────────────────────────────────────┘
```
