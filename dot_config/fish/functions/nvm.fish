function nvm --description 'Lazy Fish-native Node version manager'
    set -q nvm_mirror; or set -g nvm_mirror https://nodejs.org/dist
    if not set -q nvm_data
        set -l data "$HOME/.local/share"
        set -q XDG_DATA_HOME; and set data "$XDG_DATA_HOME"
        set -g nvm_data "$data/nvm"
    end
    set -l root (path dirname (status filename))/../chezmoi-nvm
    for file in "$root"/*.fish
        source "$file"; or return
    end
    nvm $argv
end
