# Arch desktop configuration

This chezmoi source supports `innovation` and `tranquility`. Hostname selects Zen
transparency: enabled on innovation, disabled on tranquility. No host-specific
chezmoi data file is needed. Home paths use the current user's home directory.

Run `chezmoi apply` locally on either device. Package installation, system services,
groups, SDDM and the Sine application bootloader require sudo. Close Zen before
applying changes to Sine; the script fails rather than recording a skipped setup
as successful. User preferences can be updated while Zen runs and take effect on
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
errors leave setup pending instead of silently marking it successful; the
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
