local vars = require("variables")
local fn   = require("utils.functions")

-- Cursor variables hl.env("XCURSOR_THEME", vars.cursorTheme)
hl.env("HYPRCURSOR_THEME", vars.cursorTheme)
hl.env("XCURSOR_SIZE", vars.cursorSize)
hl.env("HYPRCURSOR_SIZE", vars.cursorSize)

-- Misc variables
hl.env("EDITOR", "nvim")

--- Certain app dark mode theme 
hl.env("GTK_THEME", "adw-gtk3-dark")

-- Remove upstream arrow movement before registering media controls.
for _, key in ipairs({ "up", "down", "left", "right" }) do
    hl.unbind("SUPER + SHIFT + " .. key)
end

-- Player binds
hl.bind(
    "SUPER + SHIFT + up",
    hl.dsp.exec_cmd(
        "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l " ..
        (vars.volumeMax / 100) .. " @DEFAULT_AUDIO_SINK@ " .. vars.volumeStep .. "%+"
    ),
    { locked = true, repeating = true }
)
hl.bind(
    "SUPER + SHIFT + down",
    hl.dsp.exec_cmd(
        "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume @DEFAULT_AUDIO_SINK@ " .. vars.volumeStep .. "%-"
    ),
    { locked = true, repeating = true }
)
hl.bind("SUPER + SHIFT + right", hl.dsp.global("caelestia:mediaNext"), { locked = true })
hl.bind("SUPER + SHIFT + left", hl.dsp.global("caelestia:mediaPrev"), { locked = true })
hl.bind("SUPER + SHIFT + Space", hl.dsp.global("caelestia:mediaToggle"), { locked = true })

-- Laptop controls
hl.bind("ALT + A", hl.dsp.exec_cmd("caelestia shell idleInhibitor toggle"))
hl.bind(
    "ALT + SHIFT + M",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
    { locked = true }
)
hl.bind("ALT + SHIFT + up", hl.dsp.global("caelestia:brightnessUp"), { locked = true, repeating = true })
hl.bind("ALT + SHIFT + down", hl.dsp.global("caelestia:brightnessDown"), { locked = true, repeating = true })

-- Register arrow focus ourselves; older installations may have patched these out.
for _, direction in ipairs({ "left", "right", "up", "down" }) do
    hl.unbind("SUPER + " .. direction)
    hl.bind("SUPER + " .. direction, hl.dsp.focus({ direction = direction }))
end

-- Movement binds
hl.bind("SUPER + H", hl.dsp.focus({ direction = "left" }))
hl.bind("SUPER + L", hl.dsp.focus({ direction = "right" }))
hl.bind("SUPER + K", hl.dsp.focus({ direction = "up" }))
hl.bind("SUPER + J", hl.dsp.focus({ direction = "down" }))
hl.bind("SUPER + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind("SUPER + SHIFT + L", hl.dsp.window.move({ direction = "right" }))
hl.bind("SUPER + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind("SUPER + SHIFT + J", hl.dsp.window.move({ direction = "down" }))
hl.bind("SUPER + ALT + H", fn.resize_active_window(-10, 0), { repeating = true })
hl.bind("SUPER + ALT + L", fn.resize_active_window(10, 0), { repeating = true })
hl.bind("SUPER + ALT + K", fn.resize_active_window(0, -10), { repeating = true })
hl.bind("SUPER + ALT + J", fn.resize_active_window(0, 10), { repeating = true })

-- Lock
hl.on("hyprland.start", function()
    hl.exec_cmd([[
        (
            while true; do
                if caelestia shell lock lock && caelestia shell lock isLocked | grep -q true; then
                    exit 0
                fi
                sleep 0.1
            done
        ) &
    ]])
end)

-- Notes use the same launch/move/toggle behavior as music and communication.
hl.bind("SUPER + O", fn.toggle("notes"))

-- Keep the system sleep inhibitor connected to the shell's Keep Awake toggle.
hl.on("hyprland.start", function()
    hl.exec_cmd("$HOME/.local/bin/caelestia-keep-awake")
end)
