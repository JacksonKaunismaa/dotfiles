# [Research Task Name] Specification

**Date**: [YYYY-MM-DD]
**Author**: [Your Name]
**DRI (Directly Responsible Individual)**: [Name if different from author]
**Status**: Ideation / Exploration / Understanding / Distillation
**Research Mode**: De-risk Sprint / Extended Project
**Timeline**: [Expected duration]

---

## Quick Start: Most Important Questions

*For rapid project scoping via speech-to-text brain dump. Answer these ~10 questions to capture your core ideas, then use AI to expand into full spec.*

1. **What specific question are you trying to answer?** What would change if you had the answer?

2. **Why should anyone care?** How does this lead to real-world impact? (Your theory of change)

3. **What's your riskiest assumption?** What needs to be true for your approach to work? How will you test it quickly (<1 day)?

4. **What stage are you in?**
   - Ideation: Still choosing the problem
   - Exploration: Don't know the right questions yet, need to play around
   - Understanding: Have hypotheses to test systematically
   - Distillation: Have results to write up

5. **What's your first experiment?** The quickest test that could invalidate your whole approach. What would you learn?

6. **What does success look like?** Specific, measurable outcome in [timeline]. Not "understand X better" but "show Y improves by Z%"

7. **What's your competition?** Strong baselines you must beat. What would a skeptical reviewer compare your work against?

8. **What resources do you need?** Compute (GPUs?), data access, collaborator skills, time budget

9. **What could go wrong?** Top 2-3 risks. For each: How likely? How bad? How will you know early? What's plan B?

10. **Who's your audience?** Conference/journal? Blog post? Policy brief? What decision are they making that your research informs?

---

## 1. Problem Statement & Theory of Change

### Core Research Question
[What specific question are you trying to answer? Be precise, measurable, and action-relevant.]

### Theory of Change
[How will answering this question lead to real-world impact?]

### Why This Matters (Motivation)
[Brief context about importance.]

### Is This the Right Question?
- [ ] **Action-relevant**: Would the answer change any important decisions?
- [ ] **Neglected**: Are others already solving this well?
- [ ] **Tractable**: Can we make meaningful progress in [timeline]?
- [ ] **Important**: Does this matter for [specific impact area]?

### Success Criteria (Measurable)
- [ ] [Specific claim we'll have evidence for]
- [ ] [Concrete metric or threshold we'll achieve]
- [ ] [Deliverable that demonstrates understanding]

## 2. Critical Assumptions to Validate

### Core Assumptions
1. **Assumption**: [What needs to be true]
   - **Why critical**: [What fails if this is false]
   - **Validation method**: [How to test quickly]
   - **Backup plan**: [What to do if false]

### Known Failure Modes to Avoid
- [ ] **Scaling/Bitter Lesson**: Is my approach robust to scale?
- [ ] **Unrealistic Assumptions**: Am I assuming things that won't hold in practice?
- [ ] **Cherry-picking**: Am I designing experiments that could mislead through selection?
- [ ] **Weak Baselines**: Do I have strong baselines that actually test my contribution?

## 3. Research Stages & Technical Approach

### Current Stage: [Ideation/Exploration/Understanding/Distillation]

#### Exploration Phase
**North Star**: Maximize information gain per unit time
- [ ] Quick experiments to test core assumptions (<1 day feedback loops)
- [ ] Explore multiple hypotheses in parallel
- [ ] Keep highlights doc of interesting observations

#### Understanding Phase
**North Star**: Find convincing evidence for specific claims
- [ ] Design experiments that distinguish between hypotheses
- [ ] Implement strong baselines for comparison
- [ ] Quantitative evaluation with statistical rigor
- [ ] Systematic ablation studies

### Data Requirements
- **Source & Quality**: [Where from? How reliable? Biases?]
- **Size for Signal**: [Minimum N for statistical power]
- **Access**: [Any blockers? IRB? Compute?]

## 4. De-risking & Experimental Design

### Information-Theoretic Prioritization

| Experiment | Info Gain | Time | Priority | Status |
|------------|-----------|------|----------|---------|
| [Quick test of core assumption] | High | 2h | 1 | [ ] |
| [Baseline implementation] | Medium | 1d | 2 | [ ] |
| [Full implementation] | Low | 1w | 3 | [ ] |

### Strong Baselines Required
- **Baseline 1**: [Why it's the right comparison + implementation plan]
- **Baseline 2**: [Why it's the right comparison + implementation plan]

### Evaluation Framework
1. **Distinguishing Evidence**: What results would convince a skeptic?
2. **Statistical Rigor**: Significance threshold, sample size calculation
3. **Sanity Checks**: Reproducible with different seeds, no initialization dependence

## 5. Implementation Plan

### Phase 1: De-risk Core Ideas (<1 week)
- [ ] Implement minimal test of key technical insight
- [ ] Verify data has properties we need
- [ ] Check computational feasibility
**Exit criteria**: Core approach is viable or pivot needed

### Phase 2: Rapid Prototyping (1-2 weeks)
- [ ] Implement simplest version that could work
- [ ] Use existing tools/libraries maximally
- [ ] Daily experiments with tight feedback loops
**Exit criteria**: Have results to analyze

### Phase 3: Systematic Evaluation (1-2 weeks)
- [ ] Implement all baselines properly
- [ ] Run experiments with proper statistics
- [ ] Systematic ablations and sensitivity analysis
**Exit criteria**: Confident in claims with evidence

### Phase 4: Distillation & Communication (1 week)
- [ ] Identify 1-3 key claims supported by evidence
- [ ] Create compelling figures
- [ ] Write clear, accessible explanation
**Exit criteria**: Others can understand and build on work

## 6. Resource Planning & Constraints

### Time Budget
- **Total timeline**: [X weeks/months]
- **Key deadline**: [Conference/thesis/etc]
- **Buffer**: 30% extra time minimum

### Computational Requirements
- **Experiments < 1 day**: Critical for fast iteration
- **Memory**: [RAM/VRAM needs]
- **Parallelization**: [How many experiments simultaneously?]

## 7. Risk Analysis & Mitigation

| Risk | Probability | Impact | Mitigation | Early Warning |
|------|------------|---------|------------|---------------|
| Core assumption false | Medium | High | Quick validation experiment | Initial tests fail |
| Compute insufficient | Low | High | Profile early, have backup | Early runs OOM |
| No improvement over baseline | Medium | Medium | Multiple approaches | Early results flat |

### Go/No-Go Decision Points
1. **After Phase 1**: Core assumption false → Pivot or abort
2. **After Phase 2**: No signal over baseline → Try alternative
3. **After Phase 3**: Claims not supported → Reduce scope

## 8. Truth-Seeking & Quality Checks

- [ ] **No P-hacking**: Decided on metrics before seeing results
- [ ] **No Cherry-picking**: Reporting all relevant experiments
- [ ] **Strong Baselines**: Honestly tried to make baselines work well
- [ ] **Acknowledged Limitations**: Clearly stated where approach fails
- [ ] **Reproducible**: Another researcher could replicate from writeup

### Red Team Your Own Work
1. **Alternative Explanations**: What else could explain these results?
2. **Robustness Checks**: Different seeds/data splits/hyperparameters?
3. **Limiting Cases**: Where does the approach break down?

## 9. Output & Dissemination Plan

### Target Audience & Venue
- **Primary audience**: [Researchers/practitioners/policymakers in X]
- **Publication venue**: [Conference/journal/blog/preprint]
- **Submission deadline**: [Date]

### Key Deliverables
- [ ] Clean, documented, runnable code
- [ ] Clear writeup of method and findings
- [ ] Reproduction package with data/configs
