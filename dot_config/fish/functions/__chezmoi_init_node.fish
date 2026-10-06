function __chezmoi_init_node
    functions --erase node npm npx pnpm
    if set -q nvm_default_version; and not set -q nvm_current_version
        nvm use --silent "$nvm_default_version"
    end
end
