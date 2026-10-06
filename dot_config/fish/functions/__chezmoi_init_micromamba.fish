function __chezmoi_init_micromamba
    set -q MAMBA_EXE; or set -gx MAMBA_EXE /usr/bin/micromamba
    set -q MAMBA_ROOT_PREFIX; or set -gx MAMBA_ROOT_PREFIX "$HOME/micromamba"
    set -l hook ("$MAMBA_EXE" shell hook --shell fish --root-prefix "$MAMBA_ROOT_PREFIX")
    or return
    # Source trusted hook code only after the command succeeds. Preserve argv below.
    printf '%s\n' $hook | source
    or return
    functions -q __fish_mamba_wrapper; or return 1
    function micromamba
        __fish_mamba_wrapper $argv
    end
    function mamba
        micromamba $argv
    end
    function conda
        micromamba $argv
    end
end
