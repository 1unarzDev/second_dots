# Bindings
set -g fish_key_bindings fish_vi_key_bindings

# Developer tools use Fish autoload functions; initialization stays lazy.

# Optional local credentials are deliberately unmanaged.
if test -f ~/.config/caelestia/.env.secrets
    source ~/.config/caelestia/.env.secrets
end
