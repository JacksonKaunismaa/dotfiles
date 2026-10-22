# Optional private overlay: a second checkout laid out like this repo, deployed on top of it.
# Its custom_bins/ win over ours by name, its config/claude/{hooks,skills,rules,...} entries are
# linked next to ours, config/claude/settings.overlay.json is merged into settings.json,
# config/claude/preserve-env.txt names extra live env keys to keep, its builds/ are built, and
# files under home/ are symlinked to the same path under $HOME, and an executable deploy-extra.sh
# runs last (deploy.sh only) for anything else machine-specific.
# Point at it with DOTFILES_OVERLAY, or record its path in ~/.config/dotfiles/overlay.
if [[ -z "${DOTFILES_OVERLAY:-}" && -f "$HOME/.config/dotfiles/overlay" ]]; then
    DOTFILES_OVERLAY=$(<"$HOME/.config/dotfiles/overlay")
fi
export DOTFILES_OVERLAY="${DOTFILES_OVERLAY:-}"
if [[ -n "$DOTFILES_OVERLAY" && ! -d "$DOTFILES_OVERLAY" ]]; then
    echo "ERROR: dotfiles overlay not found: $DOTFILES_OVERLAY" >&2
    exit 1
fi
