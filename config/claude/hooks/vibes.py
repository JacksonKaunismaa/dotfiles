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


def _has_positive_context(text: str) -> bool:
    """Check if text has positive/amazement words near ????-runs."""
    return bool(re.search(
        r"\b(fast|instant|quick|nice|good|great|amazing|impressive|wow|damn)\b",
        text, re.I,
    ))


def classify(prompt: str) -> str:
    """Classify the user's message into frustrated/excited/confused/neutral."""
    text = strip_noise(prompt)
    alpha_chars = [c for c in text if c.isalpha()]
    upper_chars = [c for c in text if c.isupper()]
    alpha_count = len(alpha_chars)
    caps_ratio = len(upper_chars) / max(alpha_count, 1)

    # ── "wtf is X?" = confused, not frustrated ──────────────────
    # "wtf is [noun]?" = bewilderment. But "wtf are we doing" = frustration.
    # Only match "wtf is/was" + a noun-like word, not "wtf are we [verb]ing".
    if re.search(r"\bwtf\s+(?:is|was)\s+[\"']?\w", text, re.I):
        if not re.search(r"\?{4,}", text) and alpha_count < 100:
            return "confused"

    # ── Frustrated detection ────────────────────────────────────
    frust_score = 0.0

    # Tier 1: high-confidence
    has_long_qmarks = bool(re.search(r"\?{4,}", text))
    if has_long_qmarks:
        # ????-runs near positive words = amazement, not frustration!
        if _has_positive_context(text) and frust_score < 1.0:
            pass  # Skip — this is excited amazement
        else:
            frust_score += 3.0
    if caps_ratio > 0.4 and alpha_count > 30:
        # Make sure it's not positive caps (EXCELLENT, YES, PERFECT)
        upper_text = " ".join(w for w in text.split() if w.isupper() and len(w) > 2)
        if not re.search(r"\b(EXCELLENT|PERFECT|AMAZING|YES|NICE)\b", upper_text):
            frust_score += 3.0
    if re.search(r"\b(wtf|what the fuck|what the hell)\b", text, re.I):
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
    if re.search(r"\bstop\b\s+(?:doing|making|adding|hacking)", text, re.I):
        frust_score += 1.5
    if re.search(r"\b(wrong|broken|bugged|stupid)\b", text, re.I):
        frust_score += 1.0
    if re.search(r"\b(hack|hacking)\b", text, re.I):
        frust_score += 0.7

    # From LLM validation: mild frustration keywords
    if re.search(r"\bsucks?\b", text, re.I):
        frust_score += 2.0
    if re.search(r"\bcompletely\s+wrong\b", text, re.I):
        frust_score += 2.0
    if re.search(r"\bare\s+we\s+serious\b", text, re.I):
        frust_score += 2.0
    if re.search(r"\bdid\s+you\s+even\s+listen\b", text, re.I):
        frust_score += 2.0
    if re.search(r"\bjust\s+false\b|\bthis\s+is\s+(?:just\s+)?false\b", text, re.I):
        frust_score += 1.5
    if re.search(r"\bdid\s+not\s+just\b|\bu\s+did\s+not\s+just\b", text, re.I):
        frust_score += 1.5

    # Amplifiers — MUST come after all score accumulation
    if re.search(r"\bnah\b", text, re.I) and frust_score >= 0.5:
        frust_score += 0.5
    # "bro"/"dude" amplify existing frustration but aren't signals on their own
    if re.search(r"\b(bro|dude)\b", text, re.I) and frust_score >= 1.0:
        frust_score += 0.5

    if frust_score >= 2.0:
        return "frustrated"

    # ── Excited detection ───────────────────────────────────────
    excite_score = 0.0

    positive_words = re.findall(
        r"\b(cool|nice|awesome|excellent|perfect|sweet|sick|amazing|wow|bang|great)\b",
        text, re.I,
    )
    excite_score += len(positive_words) * 1.0

    if re.search(r"thanks?!", text, re.I):
        excite_score += 1.5
    if re.search(r"!{2,}", text):
        excite_score += 1.0
    if re.search(r"\b(love\s+it|lets?\s+go!|hell\s+yeah|lets?\s+do\s+(?:it|this))\b", text, re.I):
        excite_score += 1.5

    # From LLM validation: slang excitement
    if re.search(r"\bfire\b", text, re.I) and not re.search(r"\bfire\s+(?:up|wall|fox)", text, re.I):
        excite_score += 1.5
    if re.search(r"\bclean\s+af\b", text, re.I):
        excite_score += 2.0
    if re.search(r"\binsanely\s+good\b", text, re.I):
        excite_score += 2.0
    # Elongated words: "daaaamn", "niiice", "siiiick"
    if re.search(r"\b\w*(.)\1{3,}\w*\b", text) and re.search(r"\b(damn|nice|sick|cool|good|sweet)\b", text, re.I):
        excite_score += 1.5
    # "damn" + positive word = excitement, not just profanity
    if re.search(r"\bdamn\b", text, re.I) and re.search(r"\b(nice|good|great|clean|fire)\b", text, re.I):
        excite_score += 1.5

    # ????-runs with positive context = amazement
    if has_long_qmarks and _has_positive_context(text):
        excite_score += 2.0

    # "ok cool" only counts in VERY short messages — otherwise it's a transition word
    if re.search(r"ok\s+cool", text, re.I):
        if len(text.strip()) < 30:
            excite_score += 0.5

    # Short positive messages are higher confidence (but truly short — not 2 sentences)
    if len(text.strip()) < 40 and excite_score >= 1.0:
        excite_score += 0.5

    if excite_score >= 1.5:
        return "excited"

    # ── Confused detection ──────────────────────────────────────
    confuse_score = 0.0

    if re.search(r"(?:^|\.\s*)\s*wait\b", text, re.I):
        confuse_score += 1.5
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
    # (but NOT "you're confused" — telling Claude it's confused)
    if re.search(r"\bi'?m\s+(?:\w+\s+)*confus", text, re.I):
        confuse_score += 2.0
    elif re.search(r"\bconfus", text, re.I):
        if not re.search(r"\byou(?:'re|\s+are)\s+(?:getting\s+)?confus", text, re.I):
            confuse_score += 1.0
    # "what do you mean" — also match "wdym" and "what do u mean"
    if re.search(r"\bwdym\b", text, re.I):
        confuse_score += 1.5

    # Short "what??" messages = bewilderment
    if re.search(r"^\s*what\s*\?{2,}\s*$", text, re.I | re.M):
        confuse_score += 2.0

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
