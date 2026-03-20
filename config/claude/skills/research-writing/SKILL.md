---
name: research-writing
description: Load research writing rules into current session. Use before writing experiment results, research takehomes, or paper drafts — especially when coding and writing happen in the same session.
---

# Research Writing

Rules for writing up research clearly. Load this before writing experiment results, takehome reports, or paper sections. These rules apply to YOUR writing in the current session.

**First: invoke `/clear-writing` now** (for tone and anti-LLM-ism rules). Then continue reading below for structure rules.

## Experiment Writeup Structure

Every experiment discussion follows this skeleton. Each step is a paragraph or paragraph group. **The order is mandatory — never skip ahead.**

1. **What we wanted to test** — high-level overview of the experiment's goal. One or two sentences. The reader should understand the purpose before any details.

2. **Why** — motivation. Why does this experiment matter? What question does it answer? What would we learn from the result?

3. **How we did it** — low-level details that matter. Describe the setup, procedure, and key parameters. **Define every term here.** If you mention a metric, explain what it measures. If you mention a dataset, say what's in it. If you mention a method, explain what it does. Include anything that went wrong during data collection (filtering, data loss, API failures) — these are part of the method.

4. **What we found** — state results directly. Numbers, with uncertainty where available. Don't interpret yet, just report.

5. **Why it matters** — analysis. What does this tell us? Does it confirm or refute the hypothesis? What are the implications? What should the reader take away?

**NEVER lead with results.** Do not open a section with the answer ("No." or "Fine-tuning didn't work."). The reader needs context before they can understand what a result means. Even if the result is the most interesting part, it comes after steps 1-3.

Bad:
> We ran the consistency classifier on GPQA with k=10 and got 72% recall at 5% FPR. We also tested with k=5 and got 61% recall. The C3 method works by checking whether model answers remain consistent across rephrased versions of the same question. This suggests sandbagging models fail to maintain consistent deception.

Problems: results before the reader knows what C3 or GPQA are, method explanation comes after results, no motivation, no analysis of why k matters.

Good:
> We wanted to test whether answer consistency alone can detect sandbagging — cases where a model deliberately underperforms on a benchmark.
>
> If a model is genuinely unable to answer a question, its errors should be random across rephrasings. But if it's deliberately failing, it may struggle to fail consistently, since it has to "choose" wrong answers without an obvious pattern. This asymmetry is what we try to exploit.
>
> Our method, C3 (Consistency-based Capability Classification), asks the same question k times with rephrased prompts and measures how often the model's answers agree. We tested on GPQA, a graduate-level science benchmark with 198 questions, using k=10 rephrasings per question. We set the false positive rate at 5% and measured recall (what fraction of actual sandbaggers we catch).
>
> We found 72% recall at 5% FPR (95% CI: 65-78%). Reducing to k=5 rephrasings dropped recall to 61% (CI: 53-69%), suggesting that more samples meaningfully improve detection.
>
> This is encouraging: a black-box method with no access to model internals catches nearly three-quarters of sandbagging instances. The k=5 vs k=10 gap suggests there may be further gains from even more rephrasings, though with diminishing returns.

## Define Before Use

This is the single most important rule. Readers cannot understand a sentence that uses terms they haven't seen defined. **Every technical term, abbreviation, or concept must be defined at or before first use.**

Rules:
- Definition comes *before or at* the point of use, never after
- Use inline definitions: parenthetical "(a metric that measures X)", appositive "GPQA, a graduate-level science benchmark,", or italicized "*sandbagging* refers to..."
- Abbreviations: spell out on first use, abbreviation in parens: "false positive rate (FPR)"
- If a term appeared in a previous section, re-anchor briefly: "recall (the fraction of actual sandbaggers detected)" — don't assume the reader remembers
- Compound terms need unpacking: "black-box consistency-based sandbagging detection" is five concepts; introduce them individually first

Self-check: after writing, scan every technical term and ask: "if I hadn't written the previous sections, would I understand this sentence?" If no, add a definition.

Bad:
> We evaluated C3 on GPQA and achieved 72% recall at 5% FPR using k=10.

The reader has encountered five undefined terms in one sentence (C3, GPQA, recall in this context, FPR, k).

Good:
> We evaluated our method, C3 (Consistency-based Capability Classification), on GPQA, a graduate-level science benchmark. At a false positive rate (FPR) of 5%, C3 achieved 72% recall — meaning it correctly identified 72 out of every 100 sandbagging instances. We used k=10 rephrased prompts per question.

## Introduction Before Content

Never start a section by diving into details. The reader needs to know *what* and *why* before *how*.

Rules:
- Every document opens with: what is this about, why does it matter, what will the reader learn
- Every section opens with: what is this section about, why is it here
- Scale to context: a full paper intro needs paragraphs; an experiment subsection needs 1-2 sentences
- The reader should never have to ask "wait, why are we talking about this?"

Bad (opening a report):
> We fine-tuned Llama-3 70B on 2,000 examples from the refusal dataset using LoRA with rank 16 and learning rate 2e-4 for 3 epochs.

The reader has no idea what problem this solves, why we care about refusals, or what we're trying to achieve.

Good:
> This report investigates whether fine-tuning can remove safety refusals from open-weight models cheaply enough that releasing model weights poses a meaningful risk. We focus on the question: how many examples and how much compute does it take to substantially degrade a model's safety training?
>
> We fine-tuned Llama-3 70B on 2,000 examples from a refusal dataset...

## Claims Match Evidence

Every claim in the text must be supported by evidence you actually have. The strength of your language must match the strength of your evidence.

Rules:
- **Strong language** ("we find that", "demonstrates", "shows") requires strong evidence: clear quantitative results with adequate sample sizes
- **Medium language** ("suggests that", "provides evidence for", "is consistent with") for results that point in a direction but aren't conclusive
- **Weak language** ("may indicate", "could", "one possible explanation") for speculation or results with high uncertainty
- Never state a result without the evidence: "We found X" requires X to appear in your data
- Negative/null results stated matter-of-factly, not buried or apologized for
- No superlatives ("dramatically improves", "significantly outperforms") unless backed by a statistical test that warrants the word
- "Significant" means statistically significant (p < 0.05 or equivalent), not "a lot"

Bad:
> Our method dramatically outperforms all baselines, demonstrating that consistency-based detection is the superior approach to sandbagging detection.

"Dramatically" is vague, "all baselines" may not be true, "superior approach" overclaims beyond what one experiment shows.

Good:
> Our method outperforms the three baselines we tested (random, confidence-based, and perplexity-based) by 15-30 percentage points in recall at matched FPR. This suggests consistency-based detection is a promising direction, though we have not compared against white-box methods which use strictly more information.

## Figure-Text Alignment

When discussing figures, the text and the figure must tell the same story. Misalignment confuses readers and erodes trust.

Rules:
- Every figure referenced in text must match what the figure actually shows
- If you describe a trend ("performance increases with k"), verify the data supports that claim across the range shown
- Don't describe what the reader can see ("the blue line goes up") — interpret what it means ("increasing k improves recall, with diminishing returns above k=10")
- Figure captions are self-contained: bold main finding, then technical details, then definitions of terms used in the figure
- Figures appear near their first text reference, not pages later
- If a figure shows something surprising or unexpected, acknowledge it in the text — don't pretend everything went as expected

Self-check: for each figure reference, look at the figure and ask "does my text accurately describe what's shown here?" Pay special attention to:
- Trends you claim (does the line actually go up?)
- Comparisons you make (is A actually higher than B in the figure?)
- Numbers you cite (do they match the figure's data points?)

## Prose Style

Write like a researcher talking to a colleague, not like an AI producing a document.

Avoid these LLM prose patterns:
- **"It's not X; it's Y" rhetorical pivots** — ("This isn't evidence of learning; it's noise hitting noisy edges.") Just state what you think it is. Drop the dramatic contrast.
- **Colon-heavy explanatory style** — ("The explanation is straightforward: weak edges flip more.") Just say it directly without the theatrical setup.
- **Dramatic verdicts** — ("This is not evidence of learning." / "The model didn't learn consistency. It learned nothing.") These sound authoritative but they're just rephrasing the data with attitude. State what the data shows and let the reader draw the conclusion. Instead of "this is not evidence of learning," say "the flips were not directed toward consistency" and move on.
- **Semicolon-joined contrasts** — ("The strongly held preferences stayed put; the weak ones randomly reshuffled.") Use separate sentences or just pick one to say.

The goal is dry, clear, scientific prose. State what happened and what you think it means. No rhetorical flourishes, no dramatic reveals, no "in sum" wrapups. Think methods section of a paper, not blog post.

## Checklist Before Finishing

- [ ] Every experiment follows the 5-step structure (goal, motivation, method, results, analysis)
- [ ] Every technical term is defined at or before first use
- [ ] Every section opens with context (what and why before how)
- [ ] Every claim has evidence; hedging matches evidence strength
- [ ] Every figure reference matches what the figure actually shows
- [ ] No sentence requires knowledge that hasn't been introduced yet
