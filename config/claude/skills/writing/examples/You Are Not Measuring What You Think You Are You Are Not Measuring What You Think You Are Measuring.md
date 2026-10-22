# You Are Not Measuring What You Think You Are Measuring

**by [johnswentworth](https://www.lesswrong.com/users/johnswentworth)** · 20th Sep 2022 · 10 min read

---

Eight years ago, I worked as a data scientist at a startup, and we wanted to optimize our sign-up flow. We A/B tested lots of different changes, and occasionally found something which would boost (or reduce) click-through rates by 10% or so.

Then one week I was puzzling over a discrepancy in the variance of our daily signups. Eventually I scraped some data from the log files, and found that during traffic spikes, our server latency shot up to multiple seconds. The effect on signups during these spikes was massive: even just 300 ms was enough that click-through dropped by 30%, and when latency went up to seconds the click-through rates dropped by over 80%. And this happened multiple times per day. Latency was far and away the most important factor which determined our click-through rates.[^1]

Going back through some of our earlier experiments, it was clear in hindsight that some of our biggest effect-sizes actually came from changing latency — for instance, if we changed the order of two screens, then there'd be an extra screen before the user hit the one with high latency, so the latency would be better hidden. Our original interpretations of those experiments — e.g. that the user cared more about the content of one screen than another — were totally wrong. It was also clear in hindsight that our statistics on all the earlier experiments were bunk — we'd assumed that every user's click-through was statistically independent, when in fact they were highly correlated, so many of the results which we thought were significant were in fact basically noise.

Main point of this example: **we were not measuring what we thought we were measuring**. We thought we were testing hypotheses about what information the user cared about, or what order things needed to be presented in, or whether users would be more likely to click on a bigger and shinier button. But in fact, we were mostly measuring latency.

When I look back on experiments I've run over the years, in hindsight the very large majority of cases are like the server latency example. The large majority of the time, experiments did not measure what I thought they were measuring. I'll call this the **First Law of Experiment Design: you are not measuring what you think you are measuring**.

## Against One-Bit Experiments

A one-bit experiment is an experiment designed to answer a yes/no question. It's the prototypical case from high school statistics: which of two mouse diets results in lower bodyweight? Which of two button designs on a website results in higher click-through rates? Does a new vaccine design protect against COVID better than an old design (or better than no vaccine at all)? [Can Muriel Bristol tell whether milk or tea was added first to her teacup?](https://en.wikipedia.org/wiki/Lady_tasting_tea) [Will a neural net trained to navigate to a coin at the end of a level still go to the coin if it's no longer at the end of a level?](https://www.lesswrong.com/posts/oCWk8QpjgyqbFHKtK/finding-the-multiple-ground-truths-of-coinrun-and-image#Working_in_CoinRun) Can a rat navigate a maze just by smell?

There's an obvious criticism of such experiments: at best, they yield one bit of information. (Of course the experimenter probably observes a lot more than one bit of information over the course of the experiment, but usually people are trained to ignore most of that useful information and just report a p-value on the original yes/no question.) The First Law of Experiment Design implies that the situation is much worse: in the large majority of cases, a one-bit experiment yields approximately zero information about the thing the experimenter intended to measure. It inevitably turns out that mouse bodyweight, or Muriel Bristol's tea-tasting, or a neural net's coinrun performance, in fact routes through something entirely different from what we expected.

### Corollary To The First Law: If You Are Definitely Not Measuring Anything Besides What You Think You Are Measuring, You Are Probably Not Measuring Anything

Ok, but aren't there experiments where we in fact understand what's going on well enough that we can actually measure what we thought we were measuring? Like the vaccine test, or maybe those experiments from physics lab back in college?

Yes. And in those cases, we usually have a pretty damn good idea of what the experiment's outcome will be. When we understand what's going on well enough to actually measure the thing we intended to measure, we usually also understand what's going on well enough to predict the result. And if we already know the result, then we gain zero information — in a Bayesian sense, we measure nothing.

Take the physics lab example: in physics lab classes, we know what the result "should" be, and if we get some other result then we messed up the experiment. In other words: either we know what the result is (and therefore gain zero information), or we accidentally measure something other than what we intended. (Well… I say "accidentally", but my college did have a physics professor who would loosen the screws on the pendulum in the freshman physics lab.) Either way, we're definitely not measuring the thing we intended to measure — either we measure something else, or we measure nothing at all.

… though I suppose one could argue that the physics lab experiment result tells us whether or not we've messed up the experiment. In other words, we can test whether we're measuring the thing we thought we were measuring. So if we know the First Law of Experiment Design, then at least we can measure whether or not the corollary applies to the case at hand.

Anyway, for the rest of this post I'll assume we're in a domain where we don't already know what the answer is (or "should" be).

### Solution: Measure Lots of Things

In statistics jargon, the problem is confounders. We never measure what we think we are measuring because there are always confounders, all the time. We can't control for the confounders because in practice we never know what they are, or which potential confounders actually matter, or which confounders are upstream vs downstream. Classical statistics has lots to say about significance and experiment size and so forth, but when we don't even know what the confounders are there's not much to be done.

… or at least that used to be the case. Modern work on causality (e.g. [Pearl](https://www.amazon.com/Book-Why-Science-Cause-Effect/dp/1541698967/)) largely solves that problem — *if* we measure enough stuff. One of the key insights of causality is that, while we can't determine causation from correlation of two variables, we *can* sometimes determine causation from correlation of three or more variables — and the more variables, the better we can nail down causality. Similarly, if we measure enough stuff, we can often back out any latent variables and figure out how they causally link up to everything else. In other words, we can often deal with confounders if we measure enough stuff.

That's the theoretical basis for what I'll call **The Second Law of Experiment Design: if you measure enough different stuff, you might figure out what you're actually measuring**.

[Feynman's story about rat-mazes](https://calteches.library.caltech.edu/51/2/CargoCult.htm) is a good example here:

> He had a long corridor with doors all along one side where the rats came in, and doors along the other side where the food was. He wanted to see if he could train the rats to go in at the third door down from wherever he started them off. No. The rats went immediately to the door where the food had been the time before.
>
> The question was, how did the rats know, because the corridor was so beautifully built and so uniform, that this was the same door as before? Obviously there was something about the door that was different from the other doors. So he painted the doors very carefully, arranging the textures on the faces of the doors exactly the same. Still the rats could tell. Then he thought maybe the rats were smelling the food, so he used chemicals to change the smell after each run. Still the rats could tell. Then he realized the rats might be able to tell by seeing the lights and the arrangement in the laboratory like any commonsense person. So he covered the corridor, and, still the rats could tell.
>
> He finally found that they could tell by the way the floor sounded when they ran over it. And he could only fix that by putting his corridor in sand.

Measure enough different stuff, and sometimes we can figure out what's actually going on.

The biggest problem with one-bit experiments (or low-bit experiments more generally) is that we're not measuring what we think we're measuring, and we're not measuring enough stuff to figure out what's actually going on. When designing experiments, we want a firehose of bits, not just yes/no. Watching something through a microscope yields an enormous number of bits. Looking through server logs yields an enormous number of bits. That's the sort of thing we want — a firehose of information.

## Measurement Devices

What predictions might we make, from the two Laws of Experiment Design?

Here's one: new measurement devices or applications of measurement devices, especially high-bit measurement devices, are much more likely than individual experiments to be bottlenecks to the progress of science. For instance, the microscope is more of a bottleneck than Jenner's controlled trial of the first vaccine. Jenner's experiment enabled only that one vaccine, and it was almost a century before anybody developed another. When the next vaccine came along, it came from Pasteur's work watching bacteria under a microscope — and that method resulted in multiple vaccines in rapid succession, as well as "Pasteurization" as a method of disinfection.

We could make similar predictions for particle accelerators, high-throughput sequencing, electron microscopes, mass spectrometers, etc. In the context of AI/ML, we might predict that interpretability tools are a major bottleneck.

## Betting Markets

For the same reasons that an experiment is usually not measuring what we think it's measuring, a fully operationalized prediction is usually not predicting the thing we think it is predicting.

For instance, maybe what I really want to predict is something about qualitative shifts in political influence in Russia. I can operationalize that into a bunch of questions about Putin, the war in Ukraine, specific laws/policies, etc. Probably it will turn out that none of those questions actually measure the qualitative shift in political influence which I'm trying to get at. On the other hand, with a whole bunch of questions, I could maybe do some kind of principal component analysis and back out whatever main factors the questions *do* measure. For the same reasons that we can sometimes figure out what an experiment actually measures if we measure enough stuff, we can sometimes figure out what questions on a prediction market are actually asking about if we set up markets on enough different questions.

## Reading Papers

Of course the Laws of Experiment Design also apply when reading the experiment designs and results of others.

As an example, here's a [recent abstract](https://www.biorxiv.org/content/10.1101/2022.09.19.508512v1) off biorxiv:

> In this study, we examined whether there is repeatability in the activity levels of juvenile dyeing poison frogs (Dendrobates tinctorius). \[...\] We did not find individual behaviour to be repeatable, however, we detected repeatability in activity at the family level, suggesting that behavioural variation may be explained, at least partially, by genetic factors in addition to a common environment.

Just based on the abstract, I'm going to go out on a limb here and guess that this study did not, in fact, measure "genetic factors". Probably they measured some other confounder, like e.g. family members grew up nearby each other. (Or maybe the whole result was noise + p-hacking, there's always that possibility.)

Ok, time to look at the paper… well, the experiment size sure is suspiciously small, they used a grand total of 17 frogs and tested 4 separate behaviors. That sure does sound like a statistical nothingburger! On the other hand, the effect size was huge and their best p-value was p < 0.001, so maaaaaybe there's something here? I'm skeptical, but let's give the paper the benefit of the doubt on the statistics for now.

Did they actually measure *genetic* effects? Well, they sure didn't *rule out* non-genetic effects. The "husbandry" section of the Methods actually has a whole spiel about how the father-frogs "exhibit an elaborate parental care behaviour" toward their tadpoles: "Recently-hatched tadpoles are transported on their father's back from terrestrial clutches to water-filled plant structures at variable heights". Boy, that sure does sound like a family of tadpoles growing up in a single environment which is potentially different from the environment of another family of tadpoles. The experimenters do talk about their efforts to control the exact environment in which they ran the tests themselves… but they don't seem to have made much effort to control for variables impacting the young frogs *before* the test began. So, yeah, there's ample room for non-genetic correlations between each family of tadpoles.

This is a pretty typical paper: the authors didn't systematically control for confounders, and the experiment is sufficiently low-bit that we can't tell what factors actually mediated the correlations between sibling frogs (assuming those correlations weren't just noise in the first place). Probably the authors weren't measuring what they thought they were measuring; certainly they didn't *rule out* other things they might have been measuring.

## Takeaways

Let's recap the two laws of experiment design:

- **First Law of Experiment Design:** you are not measuring what you think you are measuring.
- **Second Law of Experiment Design:** if you measure enough different stuff, you might figure out what you're actually measuring.

The two laws have a lot of consequences for designing and interpreting experiments. When designing experiments, assume that the experiment will not measure the thing you intend. Include lots of other measurements, to check as many other things as you can. If possible, use instruments which give a massive firehose of information, instruments which would let you notice a huge variety of things you might not have considered, like e.g. a microscope.

Similarly, when interpreting others' experiments, assume that they were not measuring what they thought they were measuring. Ignore the claims and p-values in the abstract, go look at the graphs and images and data, cross-reference with other papers measuring other things, and try to put together enough different things to figure out what the experimenters actually measured.

---

[^1]: The numbers in the latency story are pulled out my ass, I don't remember what they actually were other than that the latency effects were far larger than anything else we'd seen. Consider the story qualitatively true, but fictional in the quantitative details.