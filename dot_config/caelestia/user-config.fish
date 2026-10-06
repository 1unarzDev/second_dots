# Bindings
set -g fish_key_bindings fish_vi_key_bindings

# Developer tools use Fish autoload functions; initialization stays lazy.

# Optional local credentials are deliberately unmanaged.
if test -f ~/.config/caelestia/.env.secrets
    source ~/.config/caelestia/.env.secrets
end

# Claude Code needs service authentication in addition to its provider token.
# Keep per-user Access credentials outside chezmoi and version control.
if test -f ~/.config/claude/access.fish
    source ~/.config/claude/access.fish
end
