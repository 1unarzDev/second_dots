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
sleep and lid handling. Disabling the toggle releases it. The bridge is a supervised systemd user service, enabled by chezmoi and
started independently of Caelestia. It discovers the active desktop even after
applying through SSH. Normal lid-close and sleep behavior remains when the toggle
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

User-tool automation restores DVC with S3 support through `uv tool install`, preserving existing tool extras, and installs Claude
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

## Cloudflare networking

`warp-lan-priority` installs a root-owned service and NetworkManager dispatcher
that give connected LAN subnets priority over WARP. It follows interface changes,
leaves default/remote mesh routes alone, and refuses to replace unrelated rules.
Install with `sudo ~/.local/bin/warp-lan-priority --install`; inspect without sudo
using `warp-lan-priority --check`. Chezmoi installs it in setup stage 26 on the
managed Arch hosts. The Ubuntu mesh server also needs this helper installed before
changing the shared profile. Existing forwarding/NAT configuration is not changed.

`warp-network-setup` performs the three installations with sudo authentication,
applies the personal policy, allows Cloudflare's documented ten-minute propagation window, retries checks, and accepts only after
validation. Run it from innovation in a terminal.

`cloudflare-network-policy --plan` shows the proposed personal profile.
`--apply` requires exported `CLOUDFLARE_API_KEY` and successful LAN-rule checks on
innovation, tranquility and verybeautifulserver. It changes only the existing
personal enrollment profile, preserves its DNS/mesh settings, and arms a fifteen-minute
rollback. Keep the rollback pending until all hosts pass route/Internet/LAN checks,
mesh SSH and cx remote file access, plus cloudflared readiness and the public
Codex web endpoint. Deleting the displayed rollback-pending file accepts the
change. `--rollback` restores the saved profile manually. API credentials are never
written into backups or this repository.

The intended policy tunnels public Internet through MASQUE and keeps the mesh
ranges and remote home LAN (`192.168.1.0/24`) inside WARP. Other private subnets
remain direct; connected LAN rules override the tunnel when physically on the
home subnet. Cloudflared transport networks are direct to avoid tunnel recursion.
The account-default profile and unrelated enrollment identities remain unchanged.
Physical robot forwarding is managed separately in cx. Physical downstream-device
Internet access cannot be validated when no edge device is connected.

## Boot lock screen

SDDM autologin starts Hyprland; Caelestia provides the password lock screen.
`caelestia-startup-lock` wakes/refreshes outputs before requesting the lock, retries
until shell IPC confirms it is locked, then wakes/refreshes again. There is no
fixed startup delay or input-event dependency. The lock uses the wallpaper
background rather than the first-frame screencopy path, whose upstream code notes
a startup capture race. The helper supports Lua and legacy Hyprland dispatchers
and checks their response text as well as exit status.

Run `python tests/check-startup-lock.py` for delayed IPC/lock readiness, wake retry,
and exit-zero dispatcher errors. Actual cold-boot visibility requires a physical
boot check; configuration reload does not trigger the startup lock.

## Keep Awake persistence

`caelestia-keep-awake.service` is enabled at user-manager startup and automatically
restarts after failure. It follows Caelestia's toggle with logind block inhibitors
for idle, sleep and lid handling. An unavailable shell/IPC preserves the last
state; a replacement shell has its enabled toggle restored before its initial
default is read. The enabled preference is stored under
`~/.local/state/caelestia-keep-awake/`, so bridge restarts preserve it too. Turning
the toggle off releases the bridge's inhibitors and restores normal lid behavior.

The helper and service belong to chezmoi, not Caelestia's package files. Setup
stage 66 reloads updated bridge code; shell/package updates do not stop the
service. `systemctl --user status caelestia-keep-awake.service` and
`systemd-inhibit --list` show its live state. State-transition regression checks
are in `tests/check-keep-awake.py`. Physical lid-close behavior needs a laptop
check; toggle release/acquisition and bridge crash recovery were verified live.

## Container files across devices

`cx-container` is a chezmoi-managed companion to cx. It streams files/directories
between local paths, SSH hosts, and running Docker/devcontainers. No container
SSH daemon, mounted filesystem, agent forwarding, or full temporary transfer
copy is required. Use an existing SSH alias for each host; Docker access must
already work as that account. Container names resolve to immutable IDs before
execution. Devcontainer `remoteUser` metadata is respected, otherwise Docker's
configured container user is used.

```sh
cx-container containers --device tranquility
cx-container ls docker://tranquility/CONTAINER/workspaces/project
cx-container preview docker://tranquility/CONTAINER/workspaces/project/README.md
cx-container edit docker://tranquility/CONTAINER/workspaces/project/README.md

# Copy OUT to a device's existing directory.
cx-container copy docker://tranquility/CONTAINER/workspaces/project/results ssh://innovation/home/lunarz/Downloads
# Copy IN from this device.
cx-container copy ./dataset docker://tranquility/CONTAINER/workspaces/project
# Container to container, including different hosts.
cx-container copy docker://tranquility/SOURCE/data/results docker://verybeautifulserver/DESTINATION/workspaces/project
```

Use `docker://local/CONTAINER/path` for containers on the current device. Remote
paths are absolute. Copy always retains the source basename inside the existing
destination directory. Quote spaces and URL-encode `#`, `?`, and literal `%` in
URLs. Existing files are refused unless `--overwrite` is explicitly supplied.
Directory transfers preserve modes and symlinks without following symlinks.
Failures can leave partial output; this command does not implement resumed jobs,
source deletion, or a filesystem snapshot. The existing `cx copy` job machinery
remains available for durable host-to-host transfers, and cx's container browser
remains available for browsing/previews.

Bulk transfers use tar streams with OS pipe backpressure and SSH encryption.
Remote-to-remote transfers relay through the device running the command, avoiding
new SSH trust/key requirements. Containers need `sh`, `tar`, `ls`, and `head`.
Editing additionally needs GNU-compatible `stat`, `chmod --reference`, `mktemp`,
`sha256sum`, and `mv`. Edited files stage privately on the viewer (64 MiB default
limit), open with `$VISUAL`, `$EDITOR`, or nvim, then save through the container
user with an atomic same-directory rename after a content-hash check. Concurrent
changes refuse upload and preserve the edited local file for recovery. Edits
require a regular file, preserve permission bits, and do not preserve special
ACLs/xattrs or another user's ownership. An editor that detaches needs its wait
option, e.g. `--editor 'code --wait'`. Binary previews are summarized and terminal
control sequences are escaped; `--limit` controls preview/edit size limits.

The helper is installed by ordinary chezmoi apply on innovation/tranquility;
remote endpoints need only SSH and Docker/tools, not the helper. Live regression
checks use task-owned disposable containers and directories:

```sh
CX_CONTAINER_TEST_DOCKER=1 CX_CONTAINER_TEST_SSH=verybeautifulserver python3 tests/check-container-files.py
```
