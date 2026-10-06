# Arch desktop configuration

This chezmoi source supports `innovation` and `tranquility`. Hostname selects Zen
transparency: enabled on innovation, disabled on tranquility. No host-specific
chezmoi data file is needed. Home paths use the current user's home directory.

Run `chezmoi apply` locally on either device. Package installation, system services,
groups, SDDM and the Sine application bootloader require sudo. Applying with Zen
open continues normally and defers Sine installation. Close Zen normally and run
`chezmoi apply` again to finish any pending Sine work. Completed setup is recorded
with its own fingerprint; deferred work is retried on later applies.
User preferences can be updated while Zen runs and take effect on
its next launch. First-time setup creates a Zen profile automatically.

The scripts restore declared packages plus the explicitly installed application
inventory captured for each hostname in `.chezmoidata/host-packages.json`, select NVIDIA packages when NVIDIA graphics
hardware is present, install Caelestia, enable services at boot, configure groups,
clone the declared repositories, install Yazi plugins/theme and Zen/Sine mods,
apply browser preferences, and refresh a running Hyprland session. Existing Git
repositories are preserved. Private repository authentication must already work.
Group membership changes require logging out and back in. Package setup performs
an Arch system upgrade together with installation (`pacman -Syu`) to avoid partial
upgrades. Boot/kernel configuration and locally built Caelestia packages are
excluded from the captured application inventory. Existing Caelestia installations
are preserved; custom bindings do not depend on manual edits to upstream files.

Desktop idle timers remain disabled on innovation. Tranquility locks after ten
minutes, blanks the display after twenty, and suspends after thirty unless Keep
Awake is enabled. The Cloudflare WARP provider uses the same stable ID on both
hosts. The optional local `.config/caelestia/.env.secrets` file is loaded but never
stored in this repository.

## Controls

- Super+Shift+Up/Down: volume; Left/Right: media previous/next.
- Super+Shift+H/J/K/L: move windows; Super+Shift+L no longer suspends.
- Ctrl+Super+Left/Right: switch workspaces; Super+arrows focus windows.
- Alt+Tab / Alt+Shift+Tab: cycle windows; Ctrl+Alt+Tab / Ctrl+Alt+Shift+Tab: cycle groups.
- Super+Escape: lock; Alt+Shift+L: restore the lock shell.
- Alt+F: maximize; Alt+Shift+F: toggle floating.
- Alt+A: toggle Keep Awake.
- Alt+Shift+M: microphone mute; Super+Shift+M: speaker mute.
- Alt+Shift+Up/Down: brightness.
- Super+P: pin window; Alt+Shift+P: toggle panels.
- Super+O: open/move/toggle Obsidian in `special:notes`.
- Super+T: open/move/toggle Vesktop (Discord) in `special:communication`.
- Yazi Ctrl+N: drag selected files with dragon-drop.
- Yazi Ctrl+O: choose an opener. “Other installed application…” lists installed
  desktop applications that accept files or URLs, including newly installed apps.

Keep Awake mirrors Caelestia's toggle into a logind block inhibitor for idle,
sleep and lid handling. Disabling the toggle releases it. The bridge starts from
Hyprland so it belongs to the active desktop session, including after applying
chezmoi through SSH. Normal lid-close and sleep behavior remains when the toggle
is disabled. Actual physical lid behavior should be checked on the laptop.

## Transfer boundaries

This repository manages configuration and declared setup, not a full disk backup.
Browser logins/history, credentials, application databases, unlisted software and
arbitrary home-directory files are not copied. The notes and wallpaper repositories
are cloned from their remotes. Disk layout, encryption, kernel/bootloader setup and
hardware-specific configuration remain the responsibility of the Arch installation.

For a fresh Arch installation with chezmoi, sudo and network access, use
`chezmoi init --apply https://github.com/1unarzDev/second_dots.git`. For an existing
checkout, `chezmoi update` fetches and applies the current repository state.

Setup stages are separate so SDDM changes do not require reinstalling Yazi or
Sine. Post-clone steps retry after failure and preserve successful work. Sine
errors leave setup pending instead of silently marking it successful. An open
browser defers only Sine work and does not interrupt the rest of setup; the
browser version is included in its setup fingerprint so applying after a Zen
upgrade repairs its bootloader.

The Yazi bindings and openers use `%s` / `%s1`, which work on both installed
versions. The older `$@` file arguments do not work on innovation's Yazi 26.9.1.
Check the actual Ctrl+N argument forwarding without opening a drag window with
`python tests/check-yazi-drag.py` and `python tests/check-yazi-drag.py --multiple`.

Run `python tests/check-setup.py -v` to exercise package/service orchestration,
post-clone retries, Sine profile selection and cache repair in isolated fixtures.
Run `python tests/check-bindings.py` inside a running desktop to verify the live
bindings and compositor config. Fixtures never install packages on the live OS.

## Tool audit (innovation and tranquility, 2026-10-05)

Both hosts explicitly restore Node, npm, pnpm, uv, Go, micromamba, Codex,
direnv and eza instead of depending on incidental dependency installs.
Tranquility also restores rustup and its existing stable/nightly channels, and
its SOF audio firmware. Explicitly installed desktop packages were compared
against the shared and per-host inventories; remaining exclusions are OS/boot
packages, yay variants/debug builds, hardware-selected NVIDIA packages and the
local, unavailable `caelestia-firefox-theme` build.

Fish autoloads nvm.fish 2.2.18 from a pinned, MIT-licensed vendored copy. It does
not download or initialize Node at shell startup. System Node is the default;
`nvm install lts` installs and selects an LTS version. To persist that selection,
use `set -U nvm_default_version lts`; the first node/npm/npx/pnpm command in a
new shell activates it. `.nvmrc` is supported by `nvm install` / `nvm use`.
This is Fish-native nvm, with its own data directory, rather than Bash nvm.
Downloaded Node versions and universal default preferences are local state.

micromamba, mamba and conda initialize the same micromamba Fish hook on first
use. Existing `MAMBA_EXE` and `MAMBA_ROOT_PREFIX` overrides are respected; the
default root is `~/micromamba`. Arguments are forwarded without eval. A failed
hook remains retryable. Conda/mamba names are compatibility aliases, not
separate distributions. Environment contents still need project environment
files or backups; they are not copied by chezmoi.

User-tool automation restores DVC through `uv tool install` and installs Claude
through its supported npm package when absent. Existing native Claude installs
remain usable. Fish includes `~/.local/bin` without eager tool initialization.
Unity Hub is covered, but the standalone `~/.local/bin/unity` CLI (beta.5 on
innovation) is currently a separate installation whose installer is not tracked.
Unity Editors, project files, browser/application data, authentication, arbitrary
npm globals, and downloaded Python/Node environments are also outside the
configuration restore. Existing personal binaries are not overwritten.

Verify lazy startup, default Node selection, argument forwarding and hook failure
retries with `python tests/check-shell.py`. Package changes require sudo; a
configuration-only apply does not install new packages or user tools.
