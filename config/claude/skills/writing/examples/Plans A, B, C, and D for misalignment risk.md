# Plans A, B, C, and D for misalignment risk

**by [ryan_greenblatt](https://www.lesswrong.com/users/ryan_greenblatt)** · 8th Oct 2025 · [LessWrong](https://www.lesswrong.com/posts/E8n93nnEaFeXTbHn5/plans-a-b-c-and-d-for-misalignment-risk) · [AI Alignment Forum](https://alignmentforum.org/posts/E8n93nnEaFeXTbHn5/plans-a-b-c-and-d-for-misalignment-risk)

---

I sometimes think about plans for how to handle misalignment risk. Different levels of political will for handling misalignment risk result in different plans being the best option. I often divide this into Plans A, B, C, and D (from most to least political will required). See also [Buck's quick take about different risk level regimes](https://www.lesswrong.com/posts/tmWMuY5HCSNXXZ9oq/buck-s-shortform?commentId=TNFatFiqHd8BpAXEp).

In this post, I'll explain the Plan A/B/C/D abstraction as well as discuss the probabilities and level of risk associated with each plan.

Here is a summary of the level of political will required for each of these plans and the corresponding takeoff trajectory:

- **Plan A:** There is enough will for some sort of strong international agreement that mostly eliminates race dynamics and allows for slowing down (at least for some reasonably long period, e.g. 10 years) along with massive investment in security/safety work.
- **Plan B:** The US government agrees that buying lead time for US AI companies is among the top few national security priorities (not necessarily due to misalignment concerns) and we can spend 1-3 years on mitigating misalignment risk.
- **Plan C:** The leading AI company is willing to spend (much of) its lead on misalignment concerns, but there isn't enough government buy-in for serious government involvement to make a big difference to the strategic picture. The leading AI company has a 2-9 month lead (relative to AI companies which aren't willing to spend as much on misalignment concerns) and is sufficiently institutionally functional to actually spend this lead in a basically reasonable way (perhaps subject to some constraints from outside investors), so some decent fraction of it will be spent on safety.
- **Plan D:** The leading AI company doesn't take misalignment concerns very seriously in practice (e.g., they aren't close to willing to spend all of their lead on reducing misalignment risks at least by default) and takeoff isn't going to be exogenously slowed down. However, there are 10-30 people at the company who do take these risks seriously, are working on these risks, and have enough buy-in to get ~3% compute for things which are reasonably well-targeted at misalignment risks. See also [Ten people on the inside](https://www.lesswrong.com/posts/WSNnKcKCYAffcnrt2/ten-people-on-the-inside).

Now here is some commentary on my current favorite plan for each of these levels of political will, though I won't go into much detail.

## Plan A

We implement an international agreement to mostly eliminate race dynamics and allow for many years to be spent investing in security/safety while also generally adapting to more powerful AI. The ideal capabilities trajectory would depend on how quickly safety research progresses and the robustness of the international agreement, but I'm imagining something like spreading out takeoff over ~10 years. This might end up roughly equivalent to: ensure that if takeoff would have been fast, it is instead as slow as more optimistic people think it will be. You probably want to start slowing down capabilities around the point when AIs can fully automate engineering in AI companies and want to fully pause, spending down most of the available lead time, slightly above the level of capability needed to fully automate AI R&D.

We'd have time to focus much of our effort on moonshots which could plausibly result in high assurance and which might be scalable to very superhuman AIs. By default—as in, unless the success of some moonshots greatly changes the strategic picture—the plan would basically be to keep capabilities below [the maximum controllable level](https://www.lesswrong.com/posts/kcKrE9mzEHrdqtDpE/the-case-for-ensuring-that-powerful-ais-are-controlled#For_how_long_will_we_have_controllable_and_transformatively_useful_AI_) for a while until we can use human labor (and AI labor) to mostly resolve relevant alignment problems. Once alignment issues are resolved or we run out of time, we'd hand off ~all safety work to AIs which are barely superhuman (basically, only a bit above the capability bar needed for handoff to be viable in principle, this is probably somewhat above the level of capability needed for fully automating AI R&D). At the point of handoff, we might or might not have scalable solutions to alignment, but we don't necessarily need arbitrarily scalable solutions to succeed. Obviously I'm omitting many, many details here. (I have draft docs discussing many of these details.)

## Plan B

The situation is somewhat similar to Plan A except that we have less time (1-3 additional years rather than 10). The plan looks similar to Plan A, but we focus much less on moonshots and more on straightforward/prosaic approaches. Also, we can't afford to slow down much prior to a level of capability close to full automation of AI R&D. Attempting to hand off to AI systems with only empirical iteration and prosaic methods is key, though we can do a decently high effort version of this. We should still ensure control until handoff (or a bit before this or potentially once we've ruled out scheming strongly). The AI company should put in a bunch of effort (using AI labor) into trying to buy time via increasing the level of political will (e.g., demonstrating capabilities and risks) and helping the US government ensure non-proliferation/lead time. If this goes very well, we might be able to move to Plan A.

## Plan C

We focus on very quickly handing off to AIs even if things are very half-baked. We aim to ensure some level of (probably somewhat janky) control until handoff. Helping the US government acquire lead time is much less promising due to limited US government buy-in, though trying to generate more political will remains promising.

## Plan D

Many things will be totally YOLO'd. The safety team should focus on being able to extract non-sabotaged safety research from the AI, gathering strong evidence for risk, and making an AI which is plausibly safe to hand off to. Ensuring control at the level of the organization should be mostly given up on, but things that might help avoid AIs escalating permissions/access to a point where they can directly sabotage the relevant safety work or mess with arbitrary things run on the company's compute could be worthwhile. More responsible trailing AI companies should focus on exporting safety work (in addition to policy/coordination work).

## Plan E

We can also consider a "Plan E" scenario where the level of will and number of employees who are working on mitigating the relevant misalignment risks is substantially less than in a "Ten people on the inside" style scenario. As in, there are only a few people (or perhaps there is no one) who are worried about these risks, are aiming to mitigate them, and have access to frontier AI systems at the leading developer(s). One extreme scenario would be that the entire project is [heavily siloed and secretive](https://blog.ai-futures.org/p/training-agi-in-secret-would-be-unsafe) with few people (or no one) working on mitigating AI takeover risk and discussion of misalignment concerns is effectively taboo within the project. You can't really have a technical "Plan E" because there is approximately no one to implement the plan; in Plan E situations, the focus should be on moving to a higher level of political will and effort on mitigating risk.

## Thoughts on these plans

Another way to think about this is to think about how much lead time we have to spend on x-risk focused safety work in each of these scenarios:

- **Plan A:** 10 years
- **Plan B:** 1-3 years
- **Plan C:** 1-9 months (probably on the lower end of this)
- **Plan D:** ~0 months, but ten people on the inside doing helpful things

What do I think is the chance that we end up in the world of Plan A, B, C or D? As in, do we have the will (and competence) to do something which isn't much worse than the given plan (presumably with many modifications based on the exact situation) while still being worse than the next better plan? (Obviously the details will be less specific than the exact details I gave above.) It depends on timelines, but conditioning on a trajectory where by default (in the absence of active intervention) we would have reached AIs that beat top experts at ~everything prior to 2035, here are my not-very-well-considered guesses:

- **Plan A:** 5%
- **Plan B:** 10%
- **Plan C:** 25%
- **Plan D:** 45%
- **Plan E:** 15%

What level of takeover risk do I expect in each of these situations?[^1] This depends substantially on the quality of execution, which is somewhat correlated with the level of political will. I won't assume that my preferred strategy (given that level of political will) is used. For Plans C and above, I will assume "sufficiently institutionally functional to actually spend this lead time in a basically reasonable way" and that the available lead time is actually spent on safety. Thus, the numbers I give below are somewhat more optimistic than what you'd get just given the level of political will corresponding to each of these scenarios (as this will might be spent incompetently).

Note that I'm ignoring the possibility of switching between these regimes during takeoff while humans are directly in control; for instance, I'm ignoring the possibility of starting in a Plan D scenario, but then having this shift to Plan C due to evidence of misalignment risk.[^2] However, I am including the possibility for (hopefully aligned) AIs to manage the situation very differently after humans voluntarily hand over strategic decision making to AIs (insofar as this happens). I'm also conditioning on a trajectory where by default (in the absence of active intervention) we would have reached AIs that beat top experts at ~everything prior to 2035 like for my probabilities given above.[^3]

Here is the takeover risk I expect given a central version of each of these scenarios (and given the assumptions from the prior paragraph):[^4]

- **Plan A:** 7%
- **Plan B:** 13%
- **Plan C:** 20%
- **Plan D:** 45%
- **Plan E:** 75%

A substantial fraction of the risk in Plan A and Plan B worlds comes from incompetence (as in, if the overall strategy and decision making were better, risk would be much lower) and another substantial fraction comes from the possibility of takeover being very hard to avoid.

What are the main sources of political will in each of these scenarios? In general, Plans A and B are mostly driven by governments (mostly the US government) while Plans C and D are mostly driven by AI company leadership and employees. In Plan A and Plan B, a high level of will from the US government is necessary (and could be sufficient for at least Plan B, though AI company leadership caring is helpful). Plan C likely requires a ton of buy-in from AI company leadership, though sufficiently strong employee pressure could mostly suffice. Additional political will in Plan D could come from (in descending order of importance under my views): employee efforts (both pressure and direct labor), AI company leadership, pressure from something like corporate campaigns (external pressure which mostly operates on customers, suppliers, or maybe investors), and relatively weak regulation.

Given these probabilities and levels of risk, I'm inclined to focus substantially on helping with Plans C and D. This applies to both research and generating marginal political will. Correspondingly, I think what AI company employees and leadership think about AI (existential) safety is very important and political strategies that result in AI company employees/leadership being more dismissive of safety (e.g. due to negative polarization or looking cringe) look less compelling.

---

[^1]: Note that risks other than AI takeover are also generally reduced by having more actors take powerful AI seriously and having more coordination.

[^2]: The risk conditional on starting in a Plan D scenario is lower than conditional on remaining in a Plan D scenario and the risk conditional on starting in a Plan A scenario is higher than if we condition on remaining.

[^3]: This sentence was added in an edit because I realized I forgot to include this sort of caveat.

[^4]: Multiplying the probabilities given above by the takeover risk numbers given here doesn't exactly yield my overall probability of takeover because of the optimistic assumption of reasonable execution/competence (making actual risk higher) and also because these risk numbers are for central versions of each scenario while the probabilities are for ranges of plans that include somewhat higher levels of will (making actual risk lower). (Specifically: "will (and competence) to do something which isn't much worse than the given plan while still being worse than the next better plan". So the probabilities for Plan C really include <Plan B while >= Plan C.)