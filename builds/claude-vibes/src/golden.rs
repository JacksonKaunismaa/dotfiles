use crate::classify;
use serde::Deserialize;
use std::fs;

#[derive(Deserialize)]
struct GoldenCase {
    msg: String,
    expected: String,
    #[serde(default)]
    note: Option<String>,
}

pub fn run_tests(path: &str, verbose: bool) -> i32 {
    let content = match fs::read_to_string(path) {
        Ok(c) => c,
        Err(e) => {
            eprintln!("Cannot read golden file {path}: {e}");
            return 1;
        }
    };

    let mut passed = 0u32;
    let mut failed = 0u32;

    for (i, line) in content.lines().enumerate() {
        let line = line.trim();
        if line.is_empty() {
            continue;
        }

        let case: GoldenCase = match serde_json::from_str(line) {
            Ok(c) => c,
            Err(e) => {
                eprintln!("Bad JSON on line {}: {e}", i + 1);
                return 1;
            }
        };

        let actual = classify::classify(&case.msg);

        if actual == case.expected {
            passed += 1;
            if verbose {
                let note = case.note.as_deref().unwrap_or("");
                eprintln!("  PASS [{}] {:11}  {}", i + 1, case.expected, note);
            }
        } else {
            failed += 1;
            let preview: String = case.msg.chars().take(70).collect();
            let ellipsis = if case.msg.chars().count() > 70 { "..." } else { "" };
            eprintln!("  FAIL [{}] expected={}, got={}", i + 1, case.expected, actual);
            eprintln!("         msg: {preview}{ellipsis}");
            if let Some(note) = &case.note {
                eprintln!("         note: {note}");
            }
        }
    }

    let total = passed + failed;
    eprint!("\n{passed}/{total} passed");
    if failed > 0 {
        eprintln!(", {failed} FAILED");
    } else {
        eprintln!(" — all good!");
    }

    if failed > 0 { 1 } else { 0 }
}

pub fn dump_labels(path: &str) -> i32 {
    let content = match fs::read_to_string(path) {
        Ok(c) => c,
        Err(e) => {
            eprintln!("Cannot read golden file {path}: {e}");
            return 1;
        }
    };

    for (i, line) in content.lines().enumerate() {
        let line = line.trim();
        if line.is_empty() {
            continue;
        }

        let case: GoldenCase = match serde_json::from_str(line) {
            Ok(c) => c,
            Err(e) => {
                eprintln!("Bad JSON on line {}: {e}", i + 1);
                return 1;
            }
        };

        println!("{}", classify::classify(&case.msg));
    }

    0
}
