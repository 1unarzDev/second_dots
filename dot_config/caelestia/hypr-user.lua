local vars = require("variables")
local fn   = require("utils.functions")

-- Cursor variables hl.env("XCURSOR_THEME", vars.cursorTheme)
hl.env("HYPRCURSOR_THEME", vars.cursorTheme)
hl.env("XCURSOR_SIZE", vars.cursorSize)
hl.env("HYPRCURSOR_SIZE", vars.cursorSize)

-- Misc variables
hl.env("EDITOR", "nvim")

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

-- Lockscreen
hl.on("hyprland.start", function()
    hl.exec_cmd([[
        # Discard stderr/stdout so it loops silently until Caelestia accepts the command
        until caelestia shell --help >/dev/null 2>&1; do
            sleep 0.1
        done
        caelestia shell lock lock
    ]])
end)

-- Notes bind
hl.bind(
    "SUPER + O",
    hl.dsp.exec_cmd(
       "obsidian" 
    )
)
