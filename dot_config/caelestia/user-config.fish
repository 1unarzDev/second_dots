# Bindings
set -g fish_key_bindings fish_vi_key_bindings

# Aliases
set -gx MAMBA_EXE "/usr/bin/micromamba"
set -gx MAMBA_ROOT_PREFIX "$HOME/micromamba"
function __init_micromamba
    functions --erase micromamba mamba conda
    $MAMBA_EXE shell hook --shell fish --root-prefix $MAMBA_ROOT_PREFIX | source
    alias mamba="micromamba"
    alias conda="micromamba"
end

function micromamba
    __init_micromamba
    eval micromamba $argv
end

function mamba
    __init_micromamba
    eval micromamba $argv
end

function conda
    __init_micromamba
    eval micromamba $argv
end
