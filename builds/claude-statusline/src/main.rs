use serde::Deserialize;
use std::fs;
use std::io::{self, Read};
use std::path::Path;
use std::process::Command;

// ANSI codes
const RED: &str = "\x1b[31m";
const GREEN: &str = "\x1b[32m";
const YELLOW: &str = "\x1b[33m";
const DIM: &str = "\x1b[90m";
const BOLD: &str = "\x1b[1m";
const RESET: &str = "\x1b[0m";

#[derive(Deserialize, Default)]
struct StatusData {
    model: Option<Model>,
    context_window: Option<ContextWindow>,
    cost: Option<Cost>,
    session_id: Option<String>,
    cwd: Option<String>,
}

#[derive(Deserialize, Default)]
struct Model {
    display_name: Option<String>,
}

#[derive(Deserialize, Default)]
struct ContextWindow {
    used_percentage: Option<f64>,
}

#[derive(Deserialize, Default)]
struct Cost {
    total_cost_usd: Option<f64>,
    total_duration_ms: Option<u64>,
}

#[derive(Deserialize, Default)]
struct VibesState {
    mood: Option<String>,
    injected: Option<bool>,
    vibe: Option<String>,
}

fn format_duration(ms: u64) -> String {
    let total_minutes = ms / 60_000;
    let hours = total_minutes / 60;
    let minutes = total_minutes % 60;

    if hours > 0 {
        format!("{}h {}m", hours, minutes)
    } else {
        format!("{}m", minutes)
    }
}

fn get_vibes(session_id: &str) -> String {
    let vibes_path = format!("/tmp/claude-vibes/{}.json", session_id);
    let path = Path::new(&vibes_path);

    if !path.exists() {
        return format!("{DIM}--{RESET}");
    }

    let content = match fs::read_to_string(path) {
        Ok(c) => c,
        Err(_) => return format!("{DIM}--{RESET}"),
    };

    let vs: VibesState = match serde_json::from_str(&content) {
        Ok(v) => v,
        Err(_) => return format!("{DIM}--{RESET}"),
    };

    let mood = vs.mood.as_deref().unwrap_or("neutral");
    let mood_colored = match mood {
        "frustrated" => format!("{RED}frustrated{RESET}"),
        "excited" => format!("{GREEN}excited{RESET}"),
        "confused" => format!("{YELLOW}confused{RESET}"),
        "neutral" => format!("{DIM}neutral{RESET}"),
        other => format!("{DIM}{other}{RESET}"),
    };

    if vs.injected.unwrap_or(false) {
        if let Some(vibe) = &vs.vibe {
            let truncated = if vibe.chars().count() > 45 {
                let s: String = vibe.chars().take(45).collect();
                format!("{s}...")
            } else {
                vibe.clone()
            };
            return format!("{mood_colored} {DIM}\"{truncated}\"{RESET}");
        }
    }

    mood_colored
}

fn get_git_branch(cwd: &str) -> Option<String> {
    if cwd.is_empty() {
        return None;
    }

    let output = Command::new("git")
        .args(["rev-parse", "--abbrev-ref", "HEAD"])
        .current_dir(cwd)
        .output()
        .ok()?;

    if !output.status.success() {
        return None;
    }

    let branch = String::from_utf8_lossy(&output.stdout).trim().to_string();
    if branch.is_empty() {
        return None;
    }

    Some(format!("{DIM}{branch}{RESET}"))
}

fn get_git_dirty(cwd: &str) -> Option<String> {
    if cwd.is_empty() {
        return None;
    }

    let output = Command::new("git")
        .args(["status", "--porcelain"])
        .current_dir(cwd)
        .output()
        .ok()?;

    if !output.status.success() {
        return None; // not a git repo
    }

    let stdout = String::from_utf8_lossy(&output.stdout);
    let dirty_count = stdout.lines().filter(|l| !l.is_empty()).count();

    if dirty_count == 0 {
        return Some(format!("{GREEN}clean{RESET}"));
    }

    // Get line-level diff stats (staged + unstaged)
    let diff_output = Command::new("git")
        .args(["diff", "--shortstat", "HEAD"])
        .current_dir(cwd)
        .output()
        .ok();

    let lines_part = diff_output
        .and_then(|o| {
            let s = String::from_utf8_lossy(&o.stdout).to_string();
            if s.trim().is_empty() {
                return None;
            }
            // Parse "X files changed, Y insertions(+), Z deletions(-)"
            let mut ins = 0u64;
            let mut del = 0u64;
            for part in s.split(',') {
                let part = part.trim();
                if part.contains("insertion") {
                    ins = part.split_whitespace().next()?.parse().ok()?;
                } else if part.contains("deletion") {
                    del = part.split_whitespace().next()?.parse().ok()?;
                }
            }
            if ins > 0 || del > 0 {
                Some(format!(" +{ins}/-{del}"))
            } else {
                None
            }
        })
        .unwrap_or_default();

    let color = if dirty_count >= 10 { RED } else { YELLOW };
    Some(format!("{color}{dirty_count} dirty{lines_part}{RESET}"))
}

fn main() {
    let mut input = String::new();
    if io::stdin().read_to_string(&mut input).is_err() || input.trim().is_empty() {
        println!("{DIM}statusline: no data{RESET}");
        return;
    }

    let data: StatusData = match serde_json::from_str(&input) {
        Ok(d) => d,
        Err(_) => {
            println!("{DIM}statusline: invalid json{RESET}");
            return;
        }
    };

    // 1. Model name (bold)
    let model_name = data
        .model
        .as_ref()
        .and_then(|m| m.display_name.as_deref())
        .unwrap_or("?");
    let model_part = format!("{BOLD}{model_name}{RESET}");

    // 2. Context usage % (colored)
    let used_pct = data
        .context_window
        .as_ref()
        .and_then(|c| c.used_percentage)
        .unwrap_or(0.0);
    let ctx_color = if used_pct < 50.0 {
        GREEN
    } else if used_pct < 80.0 {
        YELLOW
    } else {
        RED
    };
    let ctx_part = format!("{ctx_color}ctx {used_pct:.0}%{RESET}");

    // 3. Cost (dim)
    let cost = data
        .cost
        .as_ref()
        .and_then(|c| c.total_cost_usd)
        .unwrap_or(0.0);
    let cost_part = format!("{DIM}${cost:.2}{RESET}");

    // 4. Session timer (dim) — from total_duration_ms
    let timer_part = data
        .cost
        .as_ref()
        .and_then(|c| c.total_duration_ms)
        .map(|ms| format!("{DIM}{}{RESET}", format_duration(ms)))
        .unwrap_or_else(|| format!("{DIM}--{RESET}"));

    // 5. Vibes mood
    let session_id = data.session_id.as_deref().unwrap_or("unknown");
    let vibes_part = get_vibes(session_id);

    // 6. Git branch + dirty state
    let cwd = data.cwd.as_deref().unwrap_or("");
    let branch_part = get_git_branch(cwd);
    let git_dirty_part = get_git_dirty(cwd);

    // 7. CWD basename (bold)
    let cwd_basename = Path::new(cwd)
        .file_name()
        .and_then(|n| n.to_str())
        .unwrap_or("?");
    let cwd_part = format!("{BOLD}{cwd_basename}{RESET}");

    let sep = format!(" {DIM}|{RESET} ");
    let mut parts = vec![
        model_part,
        ctx_part,
        cost_part,
        timer_part,
    ];
    if let Some(bp) = branch_part {
        // Combine branch and dirty on one segment: "master 3 dirty +12/-5"
        if let Some(dp) = git_dirty_part {
            parts.push(format!("{bp} {dp}"));
        } else {
            parts.push(bp);
        }
    }
    parts.push(cwd_part);
    parts.push(vibes_part);
    println!("{}", parts.join(&sep));
}
