-- Keep the original addon folder and SavedVariables so existing choices survive.
local button = CreateFrame("Button", "JinxyDriftMinimapButton", Minimap)
button:SetSize(34, 34)
button:SetFrameStrata("MEDIUM")
button:SetFrameLevel(Minimap:GetFrameLevel() + 8)
button:RegisterForClicks("LeftButtonUp")
button:RegisterForDrag("LeftButton")
button:SetClampedToScreen(true)

local icon = button:CreateTexture(nil, "ARTWORK")
icon:SetAllPoints()
icon:SetTexture("Interface\\AddOns\\JinxyTouchCountdown\\Media\\JinxyIcon")
local mask = button:CreateMaskTexture()
mask:SetAllPoints()
mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
icon:AddMaskTexture(mask)
button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")

local function place()
    local db = JinxyTouchCountdownDB
    local angle = db and tonumber(db.minimapAngle) or 225
    angle = angle or 225
    local radians = math.rad(angle)
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER",
        math.cos(radians) * (Minimap:GetWidth() / 2 + 10),
        math.sin(radians) * (Minimap:GetHeight() / 2 + 10))
end

local dragging = false
button:SetScript("OnDragStart", function(self)
    dragging = true
    GameTooltip:Hide()
    self:SetScript("OnUpdate", function()
        local db = JinxyTouchCountdownDB
        if not db then return end
        local x, y = GetCursorPosition()
        local cx, cy = Minimap:GetCenter()
        if not cx or not cy then return end
        local scale = Minimap:GetEffectiveScale()
        db.minimapAngle = math.deg(math.atan2(y / scale - cy, x / scale - cx))
        place()
    end)
end)
button:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    -- Do not let the mouse-up from dragging also open the menu.
    C_Timer.After(0, function() dragging = false end)
end)
button:SetScript("OnClick", function()
    if dragging then return end
    local menu = JinxyTouchCountdownOptions
    if menu then menu:SetShown(not menu:IsShown()) end
end)
button:SetScript("OnEnter", function(self)
    if dragging then return end
    local db = JinxyTouchCountdownDB
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Jinxy Drift Reminder", 1, 0.55, 0.85)
    GameTooltip:AddLine(db and db.enabled and "Reminders enabled" or "Reminders disabled", 1, 1, 1)
    if db then
        GameTooltip:AddLine("Touch: " .. (db.touchWording or "short") .. "  |  Soul: " .. (db.soulWording or "short"), 1, 1, 1)
    end
    GameTooltip:AddLine("Click: settings and previews", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Drag: move around minimap", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)
button:SetScript("OnLeave", function() GameTooltip:Hide() end)
button:RegisterEvent("PLAYER_LOGIN")
button:SetScript("OnEvent", place)
place()
