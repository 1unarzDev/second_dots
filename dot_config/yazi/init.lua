require("git"):setup()

-- Background-colored separator glyphs stay opaque in transparent terminals.
-- Keep the theme's colored mode/position caps, but omit the dark size/percent caps.
-- Override rendering here so dynamic Caelestia theme regeneration preserves this.
function Status:length()
    local hovered = self._current.hovered
    local size = hovered and hovered.stat.len or 0
    return ui.Line { ui.Span(" " .. ya.readable_size(size) .. " "):style(self:style().alt) }
end

function Status:percent()
    local cursor, length = self._current.cursor, #self._current.files
    local percent = 0
    if cursor ~= 0 and length ~= 0 then
        percent = math.floor((cursor + 1) * 100 / length)
    end
    local label
    if percent == 0 then
        label = " Top "
    elseif percent == 100 then
        label = " Bot "
    else
        label = string.format(" %2d%% ", percent)
    end
    return ui.Line { ui.Span(" "), ui.Span(label):style(self:style().alt) }
end
