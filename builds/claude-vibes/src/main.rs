mod classify;
mod golden;
mod pools;

use serde::{Deserialize, Serialize};
use std::io::{self, Read};
use std::time::{SystemTime, UNIX_EPOCH};
use std::{fs, path::Path};

const VIBES_STATE_DIR: &str = "/tmp/claude-vibes";

#[derive(Deserialize)]
struct HookInput {
    #[serde(default)]
    prompt: String,
    #[serde(default = "default_session_id")]
    session_id: String,
}

fn default_session_id() -> String {
    "unknown".into()
}

#[derive(Serialize)]
struct HookOutput {
    #[serde(rename = "hookSpecificOutput")]
    hook_specific_output: HookSpecificOutput,
}

#[derive(Serialize)]
struct HookSpecificOutput {
    #[serde(rename = "hookEventName")]
    hook_event_name: String,
    #[serde(rename = "additionalContext")]
    additional_context: String,
}

#[derive(Serialize)]
struct VibesState {
    mood: String,
    injected: bool,
    vibe: Option<String>,
    ts: f64,
}

fn now_epoch() -> f64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs_f64())
        .unwrap_or(0.0)
}

fn select_vibe(mood: &str) -> (bool, Option<&'static str>) {
    match mood {
        "frustrated" => (true, Some(pools::random_frustrated())),
        "excited" => (true, Some(pools::random_excited())),
        // Don't inject on neutral/confused most of the time — 10% sprinkle
        _ => {
            if fastrand::f32() <= 0.1 {
                (true, Some(pools::random_sprinkle()))
            } else {
                (false, None)
            }
        }
    }
}

fn write_state(session_id: &str, mood: &str, injected: bool, vibe: Option<&str>) {
    let dir = Path::new(VIBES_STATE_DIR);
    if fs::create_dir_all(dir).is_err() {
        return;
    }
    let path = dir.join(format!("{session_id}.json"));
    let state = VibesState {
        mood: mood.to_string(),
        injected,
        vibe: vibe.map(String::from),
        ts: now_epoch(),
    };
    if let Ok(data) = serde_json::to_string(&state) {
        let _ = fs::write(path, data);
    }
}

fn main() {
    let args: Vec<String> = std::env::args().collect();

    // --test <path> [-v]
    if args.len() >= 3 && args[1] == "--test" {
        let path = &args[2];
        let verbose = args.iter().any(|a| a == "-v" || a == "--verbose");
        std::process::exit(golden::run_tests(path, verbose));
    }

    // --dump-labels <path>
    if args.len() >= 3 && args[1] == "--dump-labels" {
        let path = &args[2];
        std::process::exit(golden::dump_labels(path));
    }

    // Normal hook mode: read JSON from stdin
    let mut input_str = String::new();
    if io::stdin().read_to_string(&mut input_str).is_err() || input_str.trim().is_empty() {
        return;
    }

    let input: HookInput = match serde_json::from_str(&input_str) {
        Ok(i) => i,
        Err(_) => HookInput {
            prompt: String::new(),
            session_id: default_session_id(),
        },
    };

    let mood = classify::classify(&input.prompt);
    let (injected, vibe) = select_vibe(mood);

    write_state(&input.session_id, mood, injected, vibe);

    if injected {
        if let Some(vibe_text) = vibe {
            let output = HookOutput {
                hook_specific_output: HookSpecificOutput {
                    hook_event_name: "UserPromptSubmit".into(),
                    additional_context: vibe_text.into(),
                },
            };
            let _ = serde_json::to_writer(io::stdout().lock(), &output);
        }
    }
}
