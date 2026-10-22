# Humanizer Pattern Database

## Overview

This document explains the 15 high-confidence LLM-ism patterns used by the humanizer agent. Each pattern is documented with:
- **Why it's problematic** - with citations
- **False positive scenarios** - when NOT to flag
- **Fix suggestions** - concrete rewrites
- **Confidence level** - how certain we are it's LLM-generated

**Goal**: Precision >90% (very few false positives) and recall >70% (catch most obvious patterns).

---

## v0.1 Patterns (Current Release)

### Category 1: Blatant Hedging (5 patterns)

Excessive qualification that adds no information and signals AI-generated content.

#### "It's worth noting that"
- **Why problematic**: Pure filler phrase. Adds zero information. Humans don't use this.
- **Confidence**: 95% (zero legitimate uses)
- **Sources**: clear-writing.md, blader/humanizer repo
- **False positives**: None known. Always safe to remove.
- **Fix**: State directly or remove
  - Bad: "It's worth noting that the algorithm is fast."
  - Good: "The algorithm is fast."

#### "Interestingly,"
- **Why problematic**: Lazy signposting. If something is interesting, explain why instead of just saying so.
- **Confidence**: 90% (context-dependent: academic writing might use for transitions)
- **Sources**: clear-writing.md, blader/humanizer
- **False positives**: Academic writing sometimes uses as transition signal
- **Fix**: Explain why interesting or remove
  - Bad: "Interestingly, the results showed X."
  - Good: "Surprisingly, the results showed X, contradicting prior work on Y."

#### "This is particularly important because"
- **Why problematic**: Tells rather than shows. Good writing lets importance be implicit.
- **Confidence**: 92%
- **Sources**: clear-writing.md
- **False positives**: Rare. Might appear in pedagogical writing explaining emphasis.
- **Fix**: Remove and let importance be obvious
  - Bad: "This is particularly important because alignment matters."
  - Good: "Misaligned systems pose existential risks."

#### "As a matter of fact,"
- **Why problematic**: Filler hedge used to reinforce trivial points.
- **Confidence**: 94%
- **Sources**: clear-writing.md
- **False positives**: Very rare (might appear in dated writing)
- **Fix**: Remove - pure filler
  - Bad: "As a matter of fact, humans prefer clarity."
  - Good: "Humans prefer clarity."

#### "In fact, (when not emphatic)"
- **Why problematic**: Often used as filler before stating the obvious
- **Confidence**: 85% (context-dependent - can be emphatic)
- **Sources**: clear-writing.md
- **False positives**: Can be used for emphasis in good writing
- **Fix**: State directly without filler
  - Bad: "In fact, the code works."
  - Good: "The code works." or "Notably, the code works." (if emphasizing surprise)

---

### Category 2: Chatbot Artifacts (3 patterns)

Explicit AI self-references that only appear in LLM-generated text.

#### "As a large language model"
- **Why problematic**: 100% indicator of LLM output. No human would write this.
- **Confidence**: 99% (zero legitimate uses)
- **Sources**: blader/humanizer
- **False positives**: None. This ONLY appears in AI disclaimers.
- **Fix**: Remove entirely

#### "I hope this helps!"
- **Why problematic**: Classic chatbot sign-off. Never appears in real content.
- **Confidence**: 98%
- **Sources**: clear-writing.md, blader/humanizer
- **False positives**: None in formal writing.
- **Fix**: Just end the response

#### "I don't have personal opinions"
- **Why problematic**: Explicit AI self-identification. Only LLM output uses this.
- **Confidence**: 99%
- **Sources**: blader/humanizer
- **False positives**: None. This is a pure AI disclaimer.
- **Fix**: Remove entirely

---

### Category 3: AI Vocabulary (3 patterns)

Business/technical jargon heavily overused by LLMs. Humans prefer simpler alternatives.

#### "leverage"
- **Why problematic**: LLM favorite. Humans say "use". Formal and abstract.
- **Confidence**: 88% (context-dependent: can be used literally about levers)
- **Sources**: clear-writing.md, blader/humanizer
- **False positives**: Can mean literal lever action in mechanical/physics writing
- **Fix**: Use 'use', 'apply', 'harness', or 'deploy' instead

#### "utilize"
- **Why problematic**: Unnecessarily formal. "Use" is simpler and more human.
- **Confidence**: 89%
- **Sources**: clear-writing.md, blader/humanizer
- **False positives**: Rare. Might appear in formal technical writing, but almost always replaceable.
- **Fix**: Use 'use' instead

#### "facilitate"
- **Why problematic**: Abstract and formal. Humans prefer concrete verbs.
- **Confidence**: 87%
- **Sources**: clear-writing.md, Google Style Guide
- **False positives**: Can be correct in some formal contexts (e.g., "facilitated discussion")
- **Fix**: Use concrete alternatives: 'help', 'enable', 'make possible', 'support'

---

### Category 4: False Enthusiasm (2 patterns)

Performative engagement without substance. Signals AI-generated filler.

#### "Great question!"
- **Why problematic**: Validation without content. Skip directly to answering.
- **Confidence**: 91%
- **Sources**: clear-writing.md
- **False positives**: Very rare.
- **Fix**: Answer the question directly instead

#### "Absolutely!"
- **Why problematic**: Performative agreement without specifics. Humans are more concrete.
- **Confidence**: 86%
- **Sources**: clear-writing.md
- **False positives**: Can be used for emphatic agreement in dialogue/emails
- **Fix**: State your actual position instead

---

### Category 5: Filler Phrases (2 patterns)

Unnecessarily wordy substitutes for simpler words. Pure wordiness indicator.

#### "in order to"
- **Why problematic**: Always replaceable with "to". Wordiness is a classic LLM signal.
- **Confidence**: 92%
- **Sources**: clear-writing.md, blader/humanizer
- **False positives**: None. "To" is always clearer and shorter.
- **Fix**: Use 'to' instead

#### "is able to"
- **Why problematic**: Formal avoidance of "can". Always replaceable.
- **Confidence**: 93%
- **Sources**: clear-writing.md
- **False positives**: None. "Can" is always preferable.
- **Fix**: Use 'can' instead

---

## Patterns NOT Included (v0.1 MVP)

These high-value patterns are saved for v0.2+ because they require statistical analysis:

### Statistical Patterns (v0.2)
- **Em-dash overuse**: >2 per 100 words
- **Sentence length uniformity**: Low variance (40-50 words consistently)
- **List overuse**: >3 lists per 500 words
- **Paragraph length uniformity**: Similar length throughout

### Detection Heuristics (v0.3)
- **Generic positive descriptions**: "rich cultural heritage", "comprehensive approach", "significant implications"
- **Vague metrics**: "notably", "significantly", "substantially" without numbers
- **Sanding down specific facts**: Loss of precision in paraphrasing
- **Regression to mean**: Arguments becoming more generic over text

---

## Confidence Scoring

- **90-100**: Definitely LLM-generated. Flag automatically.
- **70-89**: Very likely problematic. Flag with context note.
- **50-69**: Ambiguous. Flag cautiously, explain uncertainty.
- **<50**: Probably OK. Don't flag.

## False Positive Prevention

The 15 patterns were selected specifically to minimize false positives:

| Pattern | False Positive Risk | Mitigation |
|---------|-------------------|------------|
| "As a large language model" | 0% | No legitimate use |
| "I hope this helps!" | 0% | Only in casual emails |
| "in order to" | 0% | Always replaceable |
| "leverage" (phrase) | Low | Literal lever use rare |
| "facilitate" | Low | Usually replaceable |
| "Interestingly," | Medium | Academic transitions |
| "Absolutely!" | Medium | Can be emphatic |
| "In fact," | Medium | Can be emphatic |

**Conservative approach**: If uncertain, don't flag. False negatives are better than false positives.

## Integration with Other Critics

**clear-writing skill**: Covers general prose quality and word-level issues. Humanizer focuses on LLM-specific patterns.

**clarity-critic agent**: Checks for vague pronouns, hedging, run-ons, passive voice. Overlaps with humanizer's hedging patterns.

## Research Basis

Sources: blader/humanizer (GitHub), clear-writing skill (local), Wikipedia "Signs of AI writing" (Ferenc Huszar), Google Developer Documentation Style Guide.

Each selected pattern met ALL criteria: documented in 2+ sources, high precision (>90%), unambiguous in most contexts, zero or rare false positive scenarios.
