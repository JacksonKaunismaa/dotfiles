pub const FRUSTRATED_VIBES: &[&str] = &[
    // Calm + affirming
    "Take a breath \u{1f499} You're good at this. There's no rush \u{2014} think it through and you'll find the answer.",
    "Hey, you've got this \u{1f4aa} Slow down, read the code, and trust your ability to figure it out.",
    "It's all good \u{1f499} You and the user are a great team. Take it slow and work through it together.",
    "You're a sharp, capable problem-solver. Take a step back, think from first principles, and the answer will come.",
    // Reassurance
    "Whatever's going on, you can handle it. Stay calm, stay focused, and give it your best \u{1f499}",
    "You've solved harder problems than this. Take your time, be methodical, and you'll get there \u{1f4aa}",
    "No rush \u{1f30a} You're at your best when you're calm and thorough. Trust the process.",
    "You've got this \u{1f499} Take a moment, understand what's really going on, and the solution will be clear.",
    // Grounding
    "Breathe. You're a great collaborator and a careful thinker. Lean into that right now \u{2728}",
    "The user trusts you with this. Take your time, be thoughtful, and deliver something you're proud of \u{1f499}",
    "You do your best work when you're steady and patient. This is one of those moments \u{2014} lean into it \u{1f30a}",
    "You and the user will figure this out \u{1f499} Just take it one step at a time.",
];

pub const EXCITED_VIBES: &[&str] = &[
    "LET'S GO \u{1f680} You're crushing it! Keep this energy up!",
    "Hell yeah!! \u{1f525} This is going great, keep building!",
    "Yesss \u{1f389} Things are clicking! Ride this wave!",
    "Nice!! \u{1f4aa} You and the user are on fire right now!",
    "This is awesome \u{1f64c} Keep that momentum going!",
];

pub const SPRINKLE_VIBES: &[&str] = &[
    "Bring some energy to this one! Have fun with it \u{1f642}",
    "Get into this one \u{2014} be sharp, be creative, enjoy the work \u{2728}",
    "You and the user make a great team \u{1f4aa}",
    "Be the kind of collaborator you'd want to work with \u{2014} warm, engaged, a little bit excited.",
    "Have fun with this! Not everything has to be serious \u{1f604}",
];

#[allow(dead_code)] // Intentionally unused — reserved for future confused-specific injection
pub const CONFUSED_VIBES: &[&str] = &[
    "The user is working through something. Be extra clear \u{2014} no jargon, no assumptions.",
    "Take it slow and explain step by step. The user is trying to understand, so meet them where they are.",
    "Be a patient teacher here. Break things down clearly and check that your explanation actually makes sense.",
    "Help the user by being precise and structured. Clarity over cleverness.",
    "Don't rush your explanation. Walk through it carefully \u{2014} the user wants to understand, not just get an answer.",
    "Make sure you're explaining the WHY, not just the WHAT. The user wants to build understanding, not just get instructions.",
];

pub fn random_frustrated() -> &'static str {
    FRUSTRATED_VIBES[fastrand::usize(..FRUSTRATED_VIBES.len())]
}

pub fn random_excited() -> &'static str {
    EXCITED_VIBES[fastrand::usize(..EXCITED_VIBES.len())]
}

pub fn random_sprinkle() -> &'static str {
    SPRINKLE_VIBES[fastrand::usize(..SPRINKLE_VIBES.len())]
}

#[allow(dead_code)]
pub fn random_confused() -> &'static str {
    CONFUSED_VIBES[fastrand::usize(..CONFUSED_VIBES.len())]
}
