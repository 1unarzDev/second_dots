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

    -- Window Group
    kbWindowGroupCycleNext     = "ALT + TAB",
    kbWindowGroupCyclePrev     = "SHIFT + ALT + TAB",
    kbUngroup                  = "SUPER + SHIFT + G",
    kbToggleGroup              = "SUPER + G",

    -- Window Action
    kbMoveWindow               = "SUPER + mouse:272",
    kbResizeWindow             = "SUPER + mouse:273",
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
    kbShowPanels               = "SUPER + P",
    kbLock                     = "ALT + L",
    kbRestoreLock              = "ALT + SHIFT + L",
}
