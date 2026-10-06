local scheme = require("scheme.current")

return {
    ------------------
    ---- HYPRLAND ----
    ------------------

    -- Apps
    terminal                   = "foot",
    browser                    = "zen-browser",
    editor                     = "code",
    fileExplorer               = "foot fish -C yazi",
    audioSettings              = "pavucontrol",

    -- Misc
    cursorTheme                = "Bibata-Modern-Ice",
    cursorSize                 = 24,

    ------------------
    ---- KEYBINDS ----
    ------------------

    -- Workspaces
    kbMoveWinToWs              = "SUPER + SHIFT",
    kbMoveWinToWsGroup         = "CTRL + SUPER + SHIFT",
    kbGoToWs                   = "SUPER",
    kbGoToWsGroup              = "CTRL + SUPER",
    kbNextWs                   = "SUPER + Right",
    kbPrevWs                   = "SUPER + Left",
    kbMoveWinToWsNext          = { "CTRL + SUPER + Right", "CTRL + SUPER + SHIFT + Right" },
    kbMoveWinToWsPrev          = { "CTRL + SUPER + Left", "CTRL + SUPER + SHIFT + Left" },

    -- Window Group
    kbWindowGroupCycleNext     = "CTRL + ALT + TAB",
    kbWindowGroupCyclePrev     = "CTRL + SHIFT + ALT + TAB",
    kbUngroup                  = "SUPER + SHIFT + G",
    kbToggleGroup              = "SUPER + G",

    -- Window Action
    -- Upstream already registers Super+mouse dragging and resizing.
    kbMoveWindow               = {},
    kbResizeWindow             = {},
    kbWindowPip                = "SUPER + ALT + backslash",
    kbPinWindow                = "SUPER + P",
    kbWindowFullscreen         = "SUPER + SHIFT + F",
    kbWindowBorderedFullscreen = "ALT + F",
    kbToggleWindowFloating     = "ALT + SHIFT + F",
    kbCloseWindow              = "SUPER + C",

    -- Special workspaces toggles
    kbSpecialWs                = "SUPER + U",
    kbSystemMonitorWs          = "CTRL + SHIFT + Escape",
    kbMusicWs                  = "SUPER + S",
    kbCommunicationWs          = "SUPER + T",
    kbTodoWs                   = "SUPER + R",

    -- Apps
    kbTerminal                 = "SUPER + Q",
    kbBrowser                  = "SUPER + B",
    kbEditor                   = "SUPER + E",
    kbFileExplorer             = "SUPER + F",

    -- Misc
    kbSession                  = "SUPER + M",
    kbShowSidebar              = "SUPER + N",
    kbClearNotifs              = "CTRL + ALT + C",
    kbShowPanels               = "ALT + SHIFT + P",
    kbLock                     = "SUPER + Escape",
    kbRestoreLock              = "ALT + SHIFT + L",
    -- Super+Shift+L moves windows; suspend through the session menu.
    kbSleep                    = {},
}
