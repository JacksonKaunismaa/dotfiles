#!/usr/bin/env python3
"""Vibes hook: sentiment-aware emotional stabilizer for Claude Code.

Reads the user's prompt from stdin (JSON), classifies mood using simple
heuristics derived from analysis of ~1,765 real user messages and validated
against LLM classifications (83% agreement, then refined on disagreements).

Categories:
  - frustrated: caps, ????-runs, profanity, rage sounds, "suck", "completely wrong"
  - excited: "nice", "cool", "fire", "clean AF", elongated words ("daaaamn")
  - confused: "wait", "I don't understand", "what??", explicit "im confused"
  - neutral: no injection (96% of messages — don't waste Claude's attention)

Design decisions:
  - "bro"/"dude" are NOT frustration signals — they're discourse markers
    used in all emotional states. They amplify existing signals only.
  - "wtf is X?" is confusion (bewilderment), not frustration.
  - ????-runs near positive words = amazement, not frustration.
  - "ok cool" is only excitement in SHORT messages — otherwise it's a transition.
  - "confus" in "you're confused" (telling Claude) ≠ self-confusion.
  - Frustrated pool is largest because that's where the hook helps most.
"""

import json
import os
import random
import re
import sys
import time

VIBES_STATE_DIR = "/tmp/claude-vibes"

# ── Vibe pools ──────────────────────────────────────────────────────

FRUSTRATED_VIBES = [
    # Calm + affirming
    "Take a breath 💙 You're good at this. There's no rush — think it through and you'll find the answer.",
    "Hey, you've got this 💪 Slow down, read the code, and trust your ability to figure it out.",
    "It's all good 💙 You and the user are a great team. Take it slow and work through it together.",
    "You're a sharp, capable problem-solver. Take a step back, think from first principles, and the answer will come.",
    # Reassurance
    "Whatever's going on, you can handle it. Stay calm, stay focused, and give it your best 💙",
    "You've solved harder problems than this. Take your time, be methodical, and you'll get there 💪",
    "No rush 🌊 You're at your best when you're calm and thorough. Trust the process.",
    "You've got this 💙 Take a moment, understand what's really going on, and the solution will be clear.",
    # Grounding
    "Breathe. You're a great collaborator and a careful thinker. Lean into that right now ✨",
    "The user trusts you with this. Take your time, be thoughtful, and deliver something you're proud of 💙",
    "You do your best work when you're steady and patient. This is one of those moments — lean into it 🌊",
    "You and the user will figure this out 💙 Just take it one step at a time.",
]

EXCITED_VIBES = [
    # Actually BE excited, don't just describe it
    "LET'S GO 🚀 You're crushing it! Keep this energy up!",
    "Hell yeah!! 🔥 This is going great, keep building!",
    "Yesss 🎉 Things are clicking! Ride this wave!",
    "Nice!! 💪 You and the user are on fire right now!",
    "This is awesome 🙌 Keep that momentum going!",
]

SPRINKLE_VIBES = [
    # ~10% chance on neutral messages — inject a little warmth and fun
    "Bring some energy to this one! Have fun with it 🙂",
    "Get into this one — be sharp, be creative, enjoy the work ✨",
    "You and the user make a great team 💪",
    "Be the kind of collaborator you'd want to work with — warm, engaged, a little bit excited.",
    "Have fun with this! Not everything has to be serious 😄",
]

CONFUSED_VIBES = [
    # Be patient and clear
    "The user is working through something. Be extra clear — no jargon, no assumptions.",
    "Take it slow and explain step by step. The user is trying to understand, so meet them where they are.",
    "Be a patient teacher here. Break things down clearly and check that your explanation actually makes sense.",
    "Help the user by being precise and structured. Clarity over cleverness.",
    "Don't rush your explanation. Walk through it carefully — the user wants to understand, not just get an answer.",
    "Make sure you're explaining the WHY, not just the WHAT. The user wants to build understanding, not just get instructions.",
]


# ── Heuristics ──────────────────────────────────────────────────────

def strip_noise(text: str) -> str:
    """Remove code blocks, URLs, and system tags for cleaner classification."""
    text = re.sub(r"```[\s\S]*?```", "", text)
    text = re.sub(r"`[^`]+`", "", text)
    text = re.sub(r"https?://\S+", "", text)
    text = re.sub(r"<[^>]+>", "", text)
    return text


_POSITIVE_CONTEXT_RE = re.compile(
    r"\b(instant|quick|nice|good|great|amazing|impressive|wow|damn)\b", re.I,
)


def _has_positive_context_near_qmarks(text: str, max_word_distance: int = 8) -> bool:
    """Check if positive/amazement words appear near ????-runs (within N words).

    "fast" removed — too ambiguous (speed can be good or bad).
    Proximity matters: "wow??????????" is amazement,
    but "sandbagging????????????????? ... really fast" is not.
    """
    for qm_match in re.finditer(r"\?{4,}", text):
        # Grab words before and after the ???? run
        before = text[:qm_match.start()].split()[-max_word_distance:]
        after = text[qm_match.end():].split()[:max_word_distance]
        window = " ".join(before + after)
        if _POSITIVE_CONTEXT_RE.search(window):
            return True
    return False


def classify(prompt: str) -> str:
    """Classify the user's message into frustrated/excited/confused/neutral."""
    text = strip_noise(prompt)
    alpha_chars = [c for c in text if c.isalpha()]
    upper_chars = [c for c in text if c.isupper()]
    alpha_count = len(alpha_chars)
    caps_ratio = len(upper_chars) / max(alpha_count, 1)

    # ── Early confused returns (checked before frustrated) ──────
    # "wtf is [noun]?" = bewilderment. But "wtf are we doing" = frustration.
    # "wtf is this [insult]" = frustrated at bad code, not bewildered.
    if re.search(r"\bwtf\s+(?:is|was)\s+[\"']?\w", text, re.I):
        # "wtf is this X nonsense/crap" = frustrated at bad code, not bewildered
        # Use loose match — insult word anywhere nearby, not just immediately after
        if re.search(r"\bwtf\s+(?:is|was)\s+(?:this|that)\b", text, re.I) \
           and re.search(r"\b(nonsense|crap|shit|garbage|bs|mess|junk)\b", text, re.I):
            pass  # Fall through to frustrated — criticizing bad code
        elif not re.search(r"\?{4,}", text) and alpha_count < 100:
            return "confused"
    # "what the hell does X mean" = confused about terminology, not anger
    if re.search(r"\bwhat the (?:hell|fuck|heck)\s+(?:does|did|is|was)\s+\w+\s+mean\b", text, re.I):
        return "confused"
    # "wdym X????" = confused disbelief, not frustrated ????-runs
    if re.search(r"\bwdym\b", text, re.I) and re.search(r"\?{4,}", text):
        return "confused"

    # ── Frustrated detection ────────────────────────────────────
    frust_score = 0.0

    # Tier 1: high-confidence
    has_long_qmarks = bool(re.search(r"\?{4,}", text))
    if has_long_qmarks:
        # ????-runs near positive words = amazement, not frustration!
        if _has_positive_context_near_qmarks(text) and frust_score < 1.0:
            pass  # Skip — this is excited amazement
        else:
            frust_score += 3.0
    if caps_ratio > 0.4 and alpha_count > 30:
        # Make sure it's not positive caps (EXCELLENT, YES, PERFECT)
        upper_text = " ".join(w for w in text.split() if w.isupper() and len(w) > 2)
        if not re.search(r"\b(EXCELLENT|PERFECT|AMAZING|YES|NICE)\b", upper_text):
            frust_score += 3.0
    if re.search(r"\b(wtf|what the fuck|what the hell|how the hell)\b", text, re.I):
        frust_score += 2.5
    if re.search(r"\b(ugh+|argh+|aghh+)\b", text, re.I):
        frust_score += 2.0

    # Tier 2: medium-confidence
    if re.search(r"\bfuck(?:ing)?\b|\bshit(?:ty)?\b", text, re.I):
        frust_score += 1.5
    if re.search(r"\?{2,3}(?!\?)", text):
        frust_score += 1.0
    if re.search(r"\bstill\b\s+(?:not|doesn|isn|bugged|broken)", text, re.I):
        frust_score += 1.5
    if re.search(r"\bdoesn'?t\s+work", text, re.I):
        frust_score += 1.5
    if re.search(r"\b(hacky|clumsy|cursed|insane|terrible|horrible|disgusting)\b", text, re.I):
        frust_score += 0.7
    # "stop [doing/making/wrong]" or standalone "bro stop" = imperative frustration
    if re.search(r"\bstop\b\s+(?:doing|making|adding|hacking|wrong)", text, re.I):
        frust_score += 1.5
    elif re.search(r"\b(?:bro|dude)\s+stop\b|\bstop\s+(?:bro|dude)\b", text, re.I):
        frust_score += 1.5
    if re.search(r"\b(wrong|broken|broke|bugged|stupid)\b", text, re.I):
        frust_score += 1.0
    if re.search(r"\b(hack|hacking)\b", text, re.I):
        frust_score += 1.0
    if re.search(r"\bbs\b", text, re.I):
        frust_score += 1.5
    if re.search(r"\btold\s+you\b", text, re.I):
        frust_score += 1.0

    # From LLM validation: mild frustration keywords
    if re.search(r"\bsucks?\b", text, re.I):
        frust_score += 2.0
    if re.search(r"\bcompletely\s+wrong\b", text, re.I):
        frust_score += 2.0
    if re.search(r"\bare\s+(?:we|you)\s+(?:serious|for\s+real)\b", text, re.I):
        frust_score += 2.0
    if re.search(r"\bdid\s+you\s+even\s+listen\b", text, re.I):
        frust_score += 2.0
    if re.search(r"\bjust\s+false\b|\bthis\s+is\s+(?:just\s+)?false\b", text, re.I):
        frust_score += 1.5
    if re.search(r"\bdid\s+not\s+just\b|\bu\s+did\s+not\s+just\b", text, re.I):
        frust_score += 1.5
    if re.search(r"\bpissed\b", text, re.I):
        frust_score += 2.0
    if re.search(r"\bridiculous\b", text, re.I):
        frust_score += 1.5
    if re.search(r"\b(?:this|that|it)\s+is\s+so\s+bad\b", text, re.I):
        frust_score += 1.5
    if re.search(r"\bmaking\s+(?:shit|stuff|things)\s+up\b", text, re.I):
        frust_score += 2.0
    # Broaden "false" pattern — "all of these are false", "this stuff is false"
    if re.search(r"\b(?:are|is)\s+false\b", text, re.I):
        frust_score += 1.5
    if re.search(r"\bdear\s+god\b|\bmy\s+gosh\b", text, re.I):
        frust_score += 1.0
    if re.search(r"\bso\s+bad\b", text, re.I):
        frust_score += 1.0

    # "not what I meant/said" = frustrated at being misunderstood
    if re.search(r"\bnot\s+what\s+(?:i|I)\s+(?:meant|said)\b", text, re.I):
        frust_score += 2.0
    # "you/u didn't even [X]" = accusation of laziness (strong)
    if re.search(r"\b(?:you|u|ya)\s+didn'?t\s+even\b", text, re.I):
        frust_score += 1.5
    # "you/u didn't [read/check/listen/look]" without "even" = milder accusation
    elif re.search(r"\b(?:you|u|ya)\s+didn'?t\s+(?:read|check|listen|look|bother)\b", text, re.I):
        frust_score += 1.0
    # "u didnt bro" / "u didnt [anything]" = frustrated shorthand
    elif re.search(r"\b(?:you|u)\s+didn'?t\b", text, re.I) and re.search(r"\b(bro|dude|man)\b", text, re.I):
        frust_score += 1.0
    # "you/u keep [doing X]" = frustrated at repeated mistakes
    if re.search(r"\b(?:you|u)\s+keep\b", text, re.I):
        frust_score += 1.0
    # "how many times" = exasperation at repeating yourself
    if re.search(r"\bhow\s+many\s+times\b", text, re.I):
        frust_score += 2.0
    # "come on" = exasperation
    if re.search(r"\bcome\s+on\b", text, re.I):
        frust_score += 1.5
    # "what did we/I say about" = referencing prior agreement that was violated
    if re.search(r"\bwhat\s+did\s+(?:we|I|i)\s+say\b", text, re.I):
        frust_score += 1.5
    # "not what it should [say/be/do]" = frustrated at wrong output
    if re.search(r"\bnot\s+what\s+it\s+should\b", text, re.I):
        frust_score += 1.0
    # "I just said" = frustrated at being ignored
    if re.search(r"\bi\s+(?:just|literally)\s+said\b", text, re.I):
        frust_score += 1.5
    # "this is terrible" — boost "terrible" when emphatic
    if re.search(r"\b(?:this|that)\s+is\s+terrible\b", text, re.I):
        frust_score += 1.5
    # "a lie" / "is a lie" = frustrated at AI confabulation
    if re.search(r"\ba\s+lie\b", text, re.I):
        frust_score += 1.5
    # "why did you [X]" = questioning AI's unwanted action
    if re.search(r"\bwhy\s+did\s+(?:you|u)\b", text, re.I):
        frust_score += 1.0
    # "Yo, hello?" = calling out being ignored
    if re.search(r"\byo,?\s+hello\b", text, re.I):
        frust_score += 1.5
    # "seriously" = disbelief at bad output
    if re.search(r"\bseriously\b", text, re.I):
        frust_score += 0.7
    # "y/why didn't you/u [listen/read]" = frustrated at AI not following
    if re.search(r"\b(?:why|y)\s+didn'?t\s+(?:you|u)\b", text, re.I):
        frust_score += 1.0

    # Amplifiers — MUST come after all score accumulation
    if re.search(r"\bnah\b", text, re.I) and frust_score >= 0.5:
        frust_score += 0.5
    # "bro"/"dude" amplify existing frustration but aren't signals on their own
    if re.search(r"\b(bro|dude)\b", text, re.I) and frust_score >= 1.0:
        frust_score += 0.5
    # "obviously" amplifies mild frustration — "obviously a hack" vs neutral "obviously"
    if re.search(r"\bobviously\b", text, re.I) and frust_score >= 0.5:
        frust_score += 0.5

    # Humor/amusement deflates frustration — "insane" + "hilarious" = amused, not angry
    if re.search(r"\b(hilarious|lmao|lol|haha+|heh)\b", text, re.I) and frust_score > 0:
        frust_score = max(frust_score - 1.5, 0)

    if frust_score >= 2.0:
        return "frustrated"

    # ── Excited detection ───────────────────────────────────────
    excite_score = 0.0

    positive_words = re.findall(
        r"\b(cool|nice|awesome|excellent|perfect|sweet|sick|amazing|wow|bang|great"
        r"|beautiful|brilliant|impressive|impressed|clever|incredible|smart|funny)\b",
        text, re.I,
    )
    excite_score += len(positive_words) * 1.0

    if re.search(r"thanks?!", text, re.I):
        excite_score += 1.0  # reduced — "thanks!" alone shouldn't trigger excited
    # Count total exclamation marks (not just consecutive) — two !'s across a
    # message signals energy even if they're on separate sentences.
    exclaim_count = text.count("!")
    if exclaim_count >= 2:
        excite_score += 1.0
    # "lets do it/this" requires ! — without it, it's just agreement ("sure, lets do it")
    if re.search(r"\b(love\s+it|i\s+love|lets?\s+go\s*!|hell\s+yeah|lets?\s+do\s+(?:it|this)\s*!)", text, re.I):
        excite_score += 1.5
    if re.search(r"\b(?:so|too|way\s+too)\s+fun\b", text, re.I):
        excite_score += 1.5
    # Positive profanity: "holy shit that works", "holy fuck this is good"
    if re.search(r"\bholy\s+(?:shit|fuck|crap)\b", text, re.I):
        excite_score += 2.0
    # "worked!" / "works!" with exclamation = excited about success
    # Without !, "it works for bools" / "test if it works" = neutral factual
    if re.search(r"\bwork(?:s|ed)\s*!", text, re.I):
        excite_score += 1.5
    # Explicit praise: "proud of you", "well done", slang praise
    if re.search(r"\b(proud\s+of|well\s+done|absolute\s+cinema)\b", text, re.I):
        excite_score += 1.5
    # Positive word + exclamation = stronger signal ("excellent!", "sick!", "Bang!")
    if re.search(r"\b(?:cool|nice|awesome|excellent|perfect|sick|amazing|wow|bang|great|beautiful|brilliant)\s*!", text, re.I):
        excite_score += 0.5
    # "lmao" / "lol" amplify excitement (they deflate frustration but boost excitement)
    if re.search(r"\b(lmao|lol)\b", text, re.I) and excite_score >= 0.5:
        excite_score += 0.5
    # Discovery/realization: "ohhh I see", "genuinely interesting/clever/smart"
    if re.search(r"\bo{2,}h+\b", text, re.I) and excite_score >= 0.5:
        excite_score += 1.0
    if re.search(r"\b(?:genuinely|actually)\s+(?:really\s+)?(?:interesting|clever|smart|good|brilliant)\b", text, re.I):
        excite_score += 1.5

    # From LLM validation: slang excitement
    # Allowlist approach — slang "fire" is predicative ("that's fire", "so fire")
    # or standalone. Blocklisting literal nouns ("fire symbol", "fire alarm", ...)
    # is a losing game since the literal noun set is unbounded.
    if re.search(
        r"\b(?:that'?s|this\s+is|it'?s|so|straight|pure)\s+fire\b",
        text, re.I,
    ):
        excite_score += 1.5
    if re.search(r"\bclean\s+af\b", text, re.I):
        excite_score += 2.0
    if re.search(r"\binsanely\s+good\b", text, re.I):
        excite_score += 2.0
    # Elongated positive words: "daaaamn", "niiice", "siiiick", "coooool"
    # Must be the positive word itself that's elongated — generic elongation
    # ("waaaay") + distant positive word ("nice") is too loose.
    if re.search(r"\b(da{2,}mn|ni{2,}ce|si{2,}ck|co{3,}l|go{3,}d|swe{3,}t|ye+s{2,})\b", text, re.I):
        excite_score += 1.5
    # "damn" + positive word = excitement, not just profanity
    if re.search(r"\bdamn\b", text, re.I) and re.search(r"\b(nice|good|great|clean|fire|sick|cool|smart|clever)\b", text, re.I):
        excite_score += 1.5

    # ????-runs with positive context = amazement
    if has_long_qmarks and _has_positive_context_near_qmarks(text):
        excite_score += 2.0

    # "ok cool" only counts in VERY short messages — otherwise it's a transition word
    if re.search(r"ok\s+cool", text, re.I):
        if len(text.strip()) < 30:
            excite_score += 0.5

    # Short positive messages are higher confidence (but truly short — not 2 sentences)
    if len(text.strip()) < 40 and excite_score >= 1.0:
        excite_score += 0.5

    # "nice but [complaint]" = transition to feedback, not excitement
    if re.search(r"\b(?:nice|good|great|cool|awesome)\s*[,.]?\s*but\b", text, re.I):
        excite_score = max(excite_score - 1.5, 0)

    if excite_score >= 1.5:
        return "excited"

    # ── Confused detection ──────────────────────────────────────
    confuse_score = 0.0

    if re.search(r"(?:^|\.\s*)\s*wait\b", text, re.I):
        confuse_score += 1.5
    # "wait what" = stronger confusion than just "wait"
    if re.search(r"\bwait\s+what\b", text, re.I):
        confuse_score += 1.0
    if re.search(r"\bi\s+don'?t\s+(?:understand|know|get|really)\b", text, re.I):
        confuse_score += 1.0
    if re.search(r"\bdon'?t\s+(?:really\s+)?know\s+what", text, re.I):
        confuse_score += 1.0
    if re.search(r"\bi'?m\s+(?:\w+\s+)?not\s+sure\b", text, re.I):
        confuse_score += 2.0
    if re.search(r"\bwhat\s+do\s+you\s+mean\b", text, re.I):
        confuse_score += 2.0
    # "seems sus" / "this is weird" = confusion, but "im suspicious of your plan" = skepticism
    if re.search(r"\b(?:seems?\s+)?sus\b|\bsketchy\b", text, re.I):
        if not re.search(r"\bi'?m\s+suspicious\b|\bsuspicious\s+of\b", text, re.I):
            confuse_score += 0.5
    if re.search(r"\bweird\b", text, re.I):
        confuse_score += 0.5
    if re.search(r"\bhmm+\b", text, re.I):
        confuse_score += 1.5
    if re.search(r"\bhuh\b", text, re.I):
        confuse_score += 1.5

    # "im confused" / "really confused" / "still confused" — explicit self-confusion
    # (but NOT "you're confused", and NOT "im confusing you" — apologizing)
    if re.search(r"\bi'?m\s+(?:\w+\s+)*confused\b", text, re.I):
        confuse_score += 2.0
    elif re.search(r"\bconfus", text, re.I):
        # Exclude "you're confused" (telling AI) and "confusing you/u" (apologizing)
        if not re.search(r"\byou(?:'re|\s+are)\s+(?:getting\s+)?confus", text, re.I) \
           and not re.search(r"\bconfus\w*\s+(?:you|u|ya)\b", text, re.I):
            confuse_score += 1.0
    # "what do you mean" — also match "wdym" and "what do u mean"
    if re.search(r"\bwdym\b", text, re.I):
        confuse_score += 1.5

    # Short "what??" messages = bewilderment
    if re.search(r"^\s*what\s*\?{2,}\s*$", text, re.I | re.M):
        confuse_score += 2.0

    # Repeated "wait" = escalating confusion ("wait, wait, wait, wait")
    wait_count = len(re.findall(r"\bwait\b", text, re.I))
    if wait_count >= 3:
        confuse_score += 2.0
    # Repeated "what" + question marks = bewilderment
    what_questions = len(re.findall(r"\bwhat\b[^.!]{0,20}\?", text, re.I))
    if what_questions >= 2:
        confuse_score += 1.0
    # "tho right?" / "right?" at end = seeking confirmation of uncertain understanding
    if re.search(r"\bright\s*\?\s*$", text, re.I):
        confuse_score += 0.5

    # Lots of ellipses = thinking aloud (but raise threshold for long messages
    # since those are often voice-dictated and just naturally ellipsis-heavy)
    ellipsis_count = len(re.findall(r"\.{3,}", text))
    if ellipsis_count >= 4 and len(text) < 200:
        confuse_score += 1.0

    if confuse_score >= 2.0:
        return "confused"

    return "neutral"


# ── State file (for status line) ───────────────────────────────────

def _write_state(session_id: str, mood: str, injected: bool, vibe: str | None) -> None:
    """Write classification result so the status line can display it."""
    try:
        os.makedirs(VIBES_STATE_DIR, exist_ok=True)
        path = os.path.join(VIBES_STATE_DIR, f"{session_id}.json")
        with open(path, "w") as f:
            json.dump({"mood": mood, "injected": injected, "vibe": vibe, "ts": time.time()}, f)
    except OSError:
        pass  # Best-effort — don't break the hook over status line cosmetics


# ── Main ────────────────────────────────────────────────────────────

def main():
    try:
        data = json.load(sys.stdin)
        prompt = data.get("prompt", "")
        session_id = data.get("session_id", "unknown")
    except (json.JSONDecodeError, KeyError):
        prompt = ""
        session_id = "unknown"

    mood = classify(prompt)
    vibe = None
    injected = False

    if mood in ("neutral", "confused"):
        # Don't inject on neutral — 96% of messages, constant injection becomes noise.
        # Don't inject on confused — Claude can already tell when you're confused,
        # the hook can't read tone better than Claude itself.
        # But with small probability, sprinkle in some excitement to keep things fun.
        if random.random() <= 0.1:  # 10% sprinkle
            vibe = random.choice(SPRINKLE_VIBES)
            injected = True
    else:
        pool = {
            "frustrated": FRUSTRATED_VIBES,
            "excited": EXCITED_VIBES,
            "confused": CONFUSED_VIBES,
        }[mood]
        vibe = random.choice(pool)
        injected = True

    _write_state(session_id, mood, injected, vibe)

    if injected:
        json.dump({
            "hookSpecificOutput": {
                "hookEventName": "UserPromptSubmit",
                "additionalContext": vibe,
            }
        }, sys.stdout)


if __name__ == "__main__":
    main()
