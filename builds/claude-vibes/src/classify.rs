use regex::Regex;
use std::sync::LazyLock;

// ── Strip noise patterns ──────────────────────────────────────────

static STRIP_CODE_BLOCKS: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"```[\s\S]*?```").unwrap());
static STRIP_INLINE_CODE: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"`[^`]+`").unwrap());
static STRIP_URLS: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"https?://\S+").unwrap());
static STRIP_HTML_TAGS: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"<[^>]+>").unwrap());

// ── Shared patterns ──────────────────────────────────────────────

static LONG_QMARKS: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"\?{4,}").unwrap());
static POSITIVE_CONTEXT: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\b(?:instant|quick|nice|good|great|amazing|impressive|wow|damn)\b").unwrap()
});

// ── Early confused patterns ──────────────────────────────────────

static WTF_IS_NOUN: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r#"(?i)\bwtf\s+(?:is|was)\s+["']?\w"#).unwrap()
});
static WTF_IS_THIS_THAT: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\bwtf\s+(?:is|was)\s+(?:this|that)\b").unwrap()
});
static INSULT_WORDS: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\b(?:nonsense|crap|shit|garbage|bs|mess|junk)\b").unwrap()
});
static WHAT_THE_HELL_MEAN: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\bwhat the (?:hell|fuck|heck)\s+(?:does|did|is|was)\s+\w+\s+mean\b").unwrap()
});
static WDYM: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"(?i)\bwdym\b").unwrap());

// ── Frustrated tier 1 ────────────────────────────────────────────

static POSITIVE_CAPS: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"\b(?:EXCELLENT|PERFECT|AMAZING|YES|NICE)\b").unwrap()
});
static WTF_TIER1: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\b(?:wtf|what the fuck|what the hell|how the hell)\b").unwrap()
});
static RAGE_SOUNDS: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\b(?:ugh+|argh+|aghh+)\b").unwrap()
});

// ── Frustrated tier 2 ────────────────────────────────────────────

static PROFANITY: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\bfuck(?:ing)?\b|\bshit(?:ty)?\b").unwrap()
});
// \?{2,3}(?!\?) — negative lookahead, needs fancy-regex
static SHORT_QMARKS: LazyLock<fancy_regex::Regex> = LazyLock::new(|| {
    fancy_regex::Regex::new(r"\?{2,3}(?!\?)").unwrap()
});
static STILL_BROKEN: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\bstill\b\s+(?:not|doesn|isn|bugged|broken)").unwrap()
});
static DOESNT_WORK: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\bdoesn'?t\s+work").unwrap()
});
static NEGATIVE_ADJECTIVES: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\b(?:hacky|clumsy|cursed|insane|terrible|horrible|disgusting)\b").unwrap()
});
static STOP_DOING: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\bstop\b\s+(?:doing|making|adding|hacking|wrong)").unwrap()
});
static BRO_STOP: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\b(?:bro|dude)\s+stop\b|\bstop\s+(?:bro|dude)\b").unwrap()
});
static WRONG_BROKEN: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\b(?:wrong|broken|broke|bugged|stupid)\b").unwrap()
});
static HACK_HACKING: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\b(?:hack|hacking)\b").unwrap()
});
static BS: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"(?i)\bbs\b").unwrap());
static TOLD_YOU: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\btold\s+you\b").unwrap()
});

// ── Frustrated: LLM validation keywords ──────────────────────────

static SUCKS: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"(?i)\bsucks?\b").unwrap());
static COMPLETELY_WRONG: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\bcompletely\s+wrong\b").unwrap()
});
static ARE_YOU_SERIOUS: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\bare\s+(?:we|you)\s+(?:serious|for\s+real)\b").unwrap()
});
static DID_YOU_LISTEN: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\bdid\s+you\s+even\s+listen\b").unwrap()
});
static JUST_FALSE: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\bjust\s+false\b|\bthis\s+is\s+(?:just\s+)?false\b").unwrap()
});
static DID_NOT_JUST: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\bdid\s+not\s+just\b|\bu\s+did\s+not\s+just\b").unwrap()
});
static PISSED: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"(?i)\bpissed\b").unwrap());
static RIDICULOUS: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"(?i)\bridiculous\b").unwrap());
static SO_BAD_EMPHATIC: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\b(?:this|that|it)\s+is\s+so\s+bad\b").unwrap()
});
static MAKING_STUFF_UP: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\bmaking\s+(?:shit|stuff|things)\s+up\b").unwrap()
});
static IS_FALSE: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\b(?:are|is)\s+false\b").unwrap()
});
static DEAR_GOD: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\bdear\s+god\b|\bmy\s+gosh\b").unwrap()
});
static SO_BAD: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"(?i)\bso\s+bad\b").unwrap());

// ── Frustrated: interpersonal ────────────────────────────────────

static NOT_WHAT_I_MEANT: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\bnot\s+what\s+(?:i|I)\s+(?:meant|said)\b").unwrap()
});
static DIDNT_EVEN: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\b(?:you|u|ya)\s+didn'?t\s+even\b").unwrap()
});
static DIDNT_READ: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\b(?:you|u|ya)\s+didn'?t\s+(?:read|check|listen|look|bother)\b").unwrap()
});
static DIDNT_BRO: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\b(?:you|u)\s+didn'?t\b").unwrap()
});
static BRO_DUDE_MAN: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\b(?:bro|dude|man)\b").unwrap()
});
static YOU_KEEP: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\b(?:you|u)\s+keep\b").unwrap()
});
static HOW_MANY_TIMES: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\bhow\s+many\s+times\b").unwrap()
});
static COME_ON: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\bcome\s+on\b").unwrap()
});
static WHAT_DID_WE_SAY: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\bwhat\s+did\s+(?:we|I|i)\s+say\b").unwrap()
});
static NOT_WHAT_IT_SHOULD: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\bnot\s+what\s+it\s+should\b").unwrap()
});
static I_JUST_SAID: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\bi\s+(?:just|literally)\s+said\b").unwrap()
});
static THIS_IS_TERRIBLE: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\b(?:this|that)\s+is\s+terrible\b").unwrap()
});
static A_LIE: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"(?i)\ba\s+lie\b").unwrap());
static WHY_DID_YOU: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\bwhy\s+did\s+(?:you|u)\b").unwrap()
});
static YO_HELLO: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\byo,?\s+hello\b").unwrap()
});
static SERIOUSLY: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"(?i)\bseriously\b").unwrap());
static WHY_DIDNT_YOU: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\b(?:why|y)\s+didn'?t\s+(?:you|u)\b").unwrap()
});

// ── Frustrated: amplifiers & deflators ───────────────────────────

static NAH: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"(?i)\bnah\b").unwrap());
static BRO_DUDE: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\b(?:bro|dude)\b").unwrap()
});
static OBVIOUSLY: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"(?i)\bobviously\b").unwrap());
static HUMOR: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\b(?:hilarious|lmao|lol|haha+|heh)\b").unwrap()
});

// ── Excited patterns ─────────────────────────────────────────────

static POSITIVE_WORDS: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\b(?:cool|nice|awesome|excellent|perfect|sweet|sick|amazing|wow|bang|great|beautiful|brilliant|impressive|impressed|clever|incredible|smart|funny)\b").unwrap()
});
static THANKS_EXCLAIM: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)thanks?!").unwrap()
});
static LOVE_IT: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\b(?:love\s+it|i\s+love|lets?\s+go\s*!|hell\s+yeah|lets?\s+do\s+(?:it|this)\s*!)").unwrap()
});
static SO_FUN: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\b(?:so|too|way\s+too)\s+fun\b").unwrap()
});
static HOLY_PROFANITY: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\bholy\s+(?:shit|fuck|crap)\b").unwrap()
});
static WORKED_EXCLAIM: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\bwork(?:s|ed)\s*!").unwrap()
});
static EXPLICIT_PRAISE: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\b(?:proud\s+of|well\s+done|absolute\s+cinema)\b").unwrap()
});
static POSITIVE_WORD_EXCLAIM: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\b(?:cool|nice|awesome|excellent|perfect|sick|amazing|wow|bang|great|beautiful|brilliant)\s*!").unwrap()
});
static LMAO_LOL: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\b(?:lmao|lol)\b").unwrap()
});
static OHHH: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"(?i)\bo{2,}h+\b").unwrap());
static GENUINELY_GOOD: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\b(?:genuinely|actually)\s+(?:really\s+)?(?:interesting|clever|smart|good|brilliant)\b").unwrap()
});
static SLANG_FIRE: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\b(?:that'?s|this\s+is|it'?s|so|straight|pure)\s+fire\b").unwrap()
});
static CLEAN_AF: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\bclean\s+af\b").unwrap()
});
static INSANELY_GOOD: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\binsanely\s+good\b").unwrap()
});
static ELONGATED_POSITIVE: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\b(?:da{2,}mn|ni{2,}ce|si{2,}ck|co{3,}l|go{3,}d|swe{3,}t|ye+s{2,})\b").unwrap()
});
static DAMN_POSITIVE: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\bdamn\b").unwrap()
});
static DAMN_POSITIVE_WORDS: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\b(?:nice|good|great|clean|fire|sick|cool|smart|clever)\b").unwrap()
});
static OK_COOL: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"(?i)ok\s+cool").unwrap());
static NICE_BUT: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\b(?:nice|good|great|cool|awesome)\s*[,.]?\s*but\b").unwrap()
});

// ── Confused patterns ────────────────────────────────────────────

static WAIT_START: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)(?:^|\.\s*)\s*wait\b").unwrap()
});
static WAIT_WHAT: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\bwait\s+what\b").unwrap()
});
static I_DONT_UNDERSTAND: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\bi\s+don'?t\s+(?:understand|know|get|really)\b").unwrap()
});
static DONT_KNOW_WHAT: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\bdon'?t\s+(?:really\s+)?know\s+what").unwrap()
});
static IM_NOT_SURE: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\bi'?m\s+(?:\w+\s+)?not\s+sure\b").unwrap()
});
static WHAT_DO_YOU_MEAN: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\bwhat\s+do\s+you\s+mean\b").unwrap()
});
static SUS_SKETCHY: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\b(?:seems?\s+)?sus\b|\bsketchy\b").unwrap()
});
static IM_SUSPICIOUS: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\bi'?m\s+suspicious\b|\bsuspicious\s+of\b").unwrap()
});
static WEIRD: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"(?i)\bweird\b").unwrap());
static HMM: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"(?i)\bhmm+\b").unwrap());
static HUH: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"(?i)\bhuh\b").unwrap());
static IM_CONFUSED: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\bi'?m\s+(?:\w+\s+)*confused\b").unwrap()
});
static CONFUS: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"(?i)\bconfus").unwrap());
static YOURE_CONFUSED: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\byou(?:'re|\s+are)\s+(?:getting\s+)?confus").unwrap()
});
static CONFUSING_YOU: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\bconfus\w*\s+(?:you|u|ya)\b").unwrap()
});
static SHORT_WHAT_QQ: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?im)^\s*what\s*\?{2,}\s*$").unwrap()
});
static WAIT_COUNT: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"(?i)\bwait\b").unwrap());
static WHAT_QUESTION: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\bwhat\b[^.!]{0,20}\?").unwrap()
});
static RIGHT_QUESTION_END: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\bright\s*\?\s*$").unwrap()
});
static ELLIPSES: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"\.{3,}").unwrap());

// ── Helpers ──────────────────────────────────────────────────────

fn strip_noise(text: &str) -> String {
    let text = STRIP_CODE_BLOCKS.replace_all(text, "");
    let text = STRIP_INLINE_CODE.replace_all(&text, "");
    let text = STRIP_URLS.replace_all(&text, "");
    let text = STRIP_HTML_TAGS.replace_all(&text, "");
    text.into_owned()
}

fn has_positive_context_near_qmarks(text: &str) -> bool {
    let max_word_distance = 8;
    for qm_match in LONG_QMARKS.find_iter(text) {
        let before: Vec<&str> = text[..qm_match.start()]
            .split_whitespace()
            .rev()
            .take(max_word_distance)
            .collect();
        let after: Vec<&str> = text[qm_match.end()..]
            .split_whitespace()
            .take(max_word_distance)
            .collect();
        let window: String = before
            .into_iter()
            .rev()
            .chain(after)
            .collect::<Vec<_>>()
            .join(" ");
        if POSITIVE_CONTEXT.is_match(&window) {
            return true;
        }
    }
    false
}

// ── Main classifier ──────────────────────────────────────────────

pub fn classify(prompt: &str) -> &'static str {
    let text = strip_noise(prompt);
    let alpha_count = text.chars().filter(|c| c.is_alphabetic()).count();
    let upper_count = text.chars().filter(|c| c.is_uppercase()).count();
    let caps_ratio = upper_count as f64 / alpha_count.max(1) as f64;

    // ── Early confused returns (checked before frustrated) ──────
    if WTF_IS_NOUN.is_match(&text) {
        if WTF_IS_THIS_THAT.is_match(&text) && INSULT_WORDS.is_match(&text) {
            // Fall through to frustrated — criticizing bad code
        } else if !LONG_QMARKS.is_match(&text) && alpha_count < 100 {
            return "confused";
        }
    }
    if WHAT_THE_HELL_MEAN.is_match(&text) {
        return "confused";
    }
    if WDYM.is_match(&text) && LONG_QMARKS.is_match(&text) {
        return "confused";
    }

    // ── Frustrated detection ────────────────────────────────────
    let mut frust_score: f64 = 0.0;

    // Tier 1: high-confidence
    let has_long_qmarks = LONG_QMARKS.is_match(&text);
    if has_long_qmarks {
        if has_positive_context_near_qmarks(&text) && frust_score < 1.0 {
            // Skip — this is excited amazement
        } else {
            frust_score += 3.0;
        }
    }
    if caps_ratio > 0.4 && alpha_count > 30 {
        let upper_text: String = text
            .split_whitespace()
            .filter(|w| w.chars().all(|c| !c.is_alphabetic() || c.is_uppercase()) && w.chars().filter(|c| c.is_alphabetic()).count() > 2)
            .collect::<Vec<_>>()
            .join(" ");
        if !POSITIVE_CAPS.is_match(&upper_text) {
            frust_score += 3.0;
        }
    }
    if WTF_TIER1.is_match(&text) {
        frust_score += 2.5;
    }
    if RAGE_SOUNDS.is_match(&text) {
        frust_score += 2.0;
    }

    // Tier 2: medium-confidence
    if PROFANITY.is_match(&text) {
        frust_score += 1.5;
    }
    if SHORT_QMARKS.is_match(&text).unwrap_or(false) {
        frust_score += 1.0;
    }
    if STILL_BROKEN.is_match(&text) {
        frust_score += 1.5;
    }
    if DOESNT_WORK.is_match(&text) {
        frust_score += 1.5;
    }
    if NEGATIVE_ADJECTIVES.is_match(&text) {
        frust_score += 0.7;
    }
    // "stop [doing/making/wrong]" or standalone "bro stop" — elif chain
    if STOP_DOING.is_match(&text) {
        frust_score += 1.5;
    } else if BRO_STOP.is_match(&text) {
        frust_score += 1.5;
    }
    if WRONG_BROKEN.is_match(&text) {
        frust_score += 1.0;
    }
    if HACK_HACKING.is_match(&text) {
        frust_score += 1.0;
    }
    if BS.is_match(&text) {
        frust_score += 1.5;
    }
    if TOLD_YOU.is_match(&text) {
        frust_score += 1.0;
    }

    // LLM validation: mild frustration keywords
    if SUCKS.is_match(&text) {
        frust_score += 2.0;
    }
    if COMPLETELY_WRONG.is_match(&text) {
        frust_score += 2.0;
    }
    if ARE_YOU_SERIOUS.is_match(&text) {
        frust_score += 2.0;
    }
    if DID_YOU_LISTEN.is_match(&text) {
        frust_score += 2.0;
    }
    if JUST_FALSE.is_match(&text) {
        frust_score += 1.5;
    }
    if DID_NOT_JUST.is_match(&text) {
        frust_score += 1.5;
    }
    if PISSED.is_match(&text) {
        frust_score += 2.0;
    }
    if RIDICULOUS.is_match(&text) {
        frust_score += 1.5;
    }
    if SO_BAD_EMPHATIC.is_match(&text) {
        frust_score += 1.5;
    }
    if MAKING_STUFF_UP.is_match(&text) {
        frust_score += 2.0;
    }
    if IS_FALSE.is_match(&text) {
        frust_score += 1.5;
    }
    if DEAR_GOD.is_match(&text) {
        frust_score += 1.0;
    }
    if SO_BAD.is_match(&text) {
        frust_score += 1.0;
    }

    // Interpersonal frustration
    if NOT_WHAT_I_MEANT.is_match(&text) {
        frust_score += 2.0;
    }
    // elif chain: "didn't even" / "didn't read" / "didn't + bro"
    if DIDNT_EVEN.is_match(&text) {
        frust_score += 1.5;
    } else if DIDNT_READ.is_match(&text) {
        frust_score += 1.0;
    } else if DIDNT_BRO.is_match(&text) && BRO_DUDE_MAN.is_match(&text) {
        frust_score += 1.0;
    }
    if YOU_KEEP.is_match(&text) {
        frust_score += 1.0;
    }
    if HOW_MANY_TIMES.is_match(&text) {
        frust_score += 2.0;
    }
    if COME_ON.is_match(&text) {
        frust_score += 1.5;
    }
    if WHAT_DID_WE_SAY.is_match(&text) {
        frust_score += 1.5;
    }
    if NOT_WHAT_IT_SHOULD.is_match(&text) {
        frust_score += 1.0;
    }
    if I_JUST_SAID.is_match(&text) {
        frust_score += 1.5;
    }
    if THIS_IS_TERRIBLE.is_match(&text) {
        frust_score += 1.5;
    }
    if A_LIE.is_match(&text) {
        frust_score += 1.5;
    }
    if WHY_DID_YOU.is_match(&text) {
        frust_score += 1.0;
    }
    if YO_HELLO.is_match(&text) {
        frust_score += 1.5;
    }
    if SERIOUSLY.is_match(&text) {
        frust_score += 0.7;
    }
    if WHY_DIDNT_YOU.is_match(&text) {
        frust_score += 1.0;
    }

    // Amplifiers — MUST come after all score accumulation
    if NAH.is_match(&text) && frust_score >= 0.5 {
        frust_score += 0.5;
    }
    if BRO_DUDE.is_match(&text) && frust_score >= 1.0 {
        frust_score += 0.5;
    }
    if OBVIOUSLY.is_match(&text) && frust_score >= 0.5 {
        frust_score += 0.5;
    }

    // Humor/amusement deflates frustration
    if HUMOR.is_match(&text) && frust_score > 0.0 {
        frust_score = (frust_score - 1.5).max(0.0);
    }

    if frust_score >= 2.0 {
        return "frustrated";
    }

    // ── Excited detection ───────────────────────────────────────
    let mut excite_score: f64 = 0.0;

    let positive_count = POSITIVE_WORDS.find_iter(&text).count();
    excite_score += positive_count as f64;

    if THANKS_EXCLAIM.is_match(&text) {
        excite_score += 1.0;
    }
    let exclaim_count = text.chars().filter(|&c| c == '!').count();
    if exclaim_count >= 2 {
        excite_score += 1.0;
    }
    if LOVE_IT.is_match(&text) {
        excite_score += 1.5;
    }
    if SO_FUN.is_match(&text) {
        excite_score += 1.5;
    }
    if HOLY_PROFANITY.is_match(&text) {
        excite_score += 2.0;
    }
    if WORKED_EXCLAIM.is_match(&text) {
        excite_score += 1.5;
    }
    if EXPLICIT_PRAISE.is_match(&text) {
        excite_score += 1.5;
    }
    if POSITIVE_WORD_EXCLAIM.is_match(&text) {
        excite_score += 0.5;
    }
    if LMAO_LOL.is_match(&text) && excite_score >= 0.5 {
        excite_score += 0.5;
    }
    if OHHH.is_match(&text) && excite_score >= 0.5 {
        excite_score += 1.0;
    }
    if GENUINELY_GOOD.is_match(&text) {
        excite_score += 1.5;
    }

    // Slang excitement
    if SLANG_FIRE.is_match(&text) {
        excite_score += 1.5;
    }
    if CLEAN_AF.is_match(&text) {
        excite_score += 2.0;
    }
    if INSANELY_GOOD.is_match(&text) {
        excite_score += 2.0;
    }
    if ELONGATED_POSITIVE.is_match(&text) {
        excite_score += 1.5;
    }
    if DAMN_POSITIVE.is_match(&text) && DAMN_POSITIVE_WORDS.is_match(&text) {
        excite_score += 1.5;
    }

    // ????-runs with positive context = amazement
    if has_long_qmarks && has_positive_context_near_qmarks(&text) {
        excite_score += 2.0;
    }

    // "ok cool" only counts in VERY short messages
    if OK_COOL.is_match(&text) && text.trim().len() < 30 {
        excite_score += 0.5;
    }

    // Short positive messages are higher confidence
    if text.trim().len() < 40 && excite_score >= 1.0 {
        excite_score += 0.5;
    }

    // "nice but [complaint]" = transition to feedback, not excitement
    if NICE_BUT.is_match(&text) {
        excite_score = (excite_score - 1.5).max(0.0);
    }

    if excite_score >= 1.5 {
        return "excited";
    }

    // ── Confused detection ──────────────────────────────────────
    let mut confuse_score: f64 = 0.0;

    if WAIT_START.is_match(&text) {
        confuse_score += 1.5;
    }
    if WAIT_WHAT.is_match(&text) {
        confuse_score += 1.0;
    }
    if I_DONT_UNDERSTAND.is_match(&text) {
        confuse_score += 1.0;
    }
    if DONT_KNOW_WHAT.is_match(&text) {
        confuse_score += 1.0;
    }
    if IM_NOT_SURE.is_match(&text) {
        confuse_score += 2.0;
    }
    if WHAT_DO_YOU_MEAN.is_match(&text) {
        confuse_score += 2.0;
    }
    // "seems sus" / "sketchy" but not "I'm suspicious of"
    if SUS_SKETCHY.is_match(&text) && !IM_SUSPICIOUS.is_match(&text) {
        confuse_score += 0.5;
    }
    if WEIRD.is_match(&text) {
        confuse_score += 0.5;
    }
    if HMM.is_match(&text) {
        confuse_score += 1.5;
    }
    if HUH.is_match(&text) {
        confuse_score += 1.5;
    }

    // "im confused" / elif "confus" (with exclusions)
    if IM_CONFUSED.is_match(&text) {
        confuse_score += 2.0;
    } else if CONFUS.is_match(&text)
        && !YOURE_CONFUSED.is_match(&text)
        && !CONFUSING_YOU.is_match(&text)
    {
        confuse_score += 1.0;
    }
    if WDYM.is_match(&text) {
        confuse_score += 1.5;
    }

    // Short "what??" messages = bewilderment (multiline mode)
    if SHORT_WHAT_QQ.is_match(&text) {
        confuse_score += 2.0;
    }

    // Repeated "wait" = escalating confusion
    let wait_count = WAIT_COUNT.find_iter(&text).count();
    if wait_count >= 3 {
        confuse_score += 2.0;
    }
    // Repeated "what" + question marks = bewilderment
    let what_questions = WHAT_QUESTION.find_iter(&text).count();
    if what_questions >= 2 {
        confuse_score += 1.0;
    }
    // "right?" at end = seeking confirmation
    if RIGHT_QUESTION_END.is_match(&text) {
        confuse_score += 0.5;
    }

    // Lots of ellipses = thinking aloud
    let ellipsis_count = ELLIPSES.find_iter(&text).count();
    if ellipsis_count >= 4 && text.len() < 200 {
        confuse_score += 1.0;
    }

    if confuse_score >= 2.0 {
        return "confused";
    }

    "neutral"
}
