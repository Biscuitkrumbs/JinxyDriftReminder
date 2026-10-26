local _, addon = ...
local menu = CreateFrame("Frame", "JinxyTouchCountdownOptions", UIParent, "BasicFrameTemplateWithInset")
menu:SetSize(260, 252)
menu:SetPoint("CENTER")
menu:SetFrameStrata("DIALOG")
menu:SetClampedToScreen(true)
menu:SetMovable(true)
menu:EnableMouse(true)
menu:RegisterForDrag("LeftButton")
menu:SetScript("OnDragStart", menu.StartMoving)
menu:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local db = addon.GetSettings()
    if db then
        local point, _, relativePoint, x, y = self:GetPoint()
        db.menuPosition = {point = point, relativePoint = relativePoint, x = x, y = y}
    end
end)
menu.TitleText:SetText("Jinxy Drift Reminder")
menu.TitleText:ClearAllPoints()
menu.TitleText:SetPoint("TOPLEFT", 12, -5)
menu.TitleText:SetPoint("TOPRIGHT", -32, -5)
menu.TitleText:SetHeight(18)
menu.TitleText:SetFontObject("GameFontNormal")
UISpecialFrames[#UISpecialFrames + 1] = "JinxyTouchCountdownOptions"
local function text(value, x, y, width, small)
    local label = menu:CreateFontString(nil, "OVERLAY", small and "GameFontHighlightSmall" or "GameFontNormal")
    label:SetPoint("TOPLEFT", x, y)
    label:SetWidth(width)
    label:SetJustifyH("LEFT")
    label:SetText(value)
    return label
end
local enabled = CreateFrame("CheckButton", nil, menu, "UICheckButtonTemplate")
enabled:SetPoint("TOPLEFT", 12, -28)
text("Enable reminders", 44, -37, 198)
enabled:SetScript("OnClick", function(self)
    SlashCmdList.JINXYTOUCH(self:GetChecked() and "on" or "off")
end)
local status = text("", 18, -60, 224, true)
local rows = {}
local function ability(kind, heading, y)
    text(heading, 18, y, 224)
    local controls = {}
    for i, choice in ipairs({"short", "long"}) do
        local control = CreateFrame("CheckButton", nil, menu)
        control:SetSize(22, 22)
        control:SetPoint("TOPLEFT", 18 + (i - 1) * 66, y - 19)
        control:SetNormalTexture("Interface\\Buttons\\UI-RadioButton")
        control:GetNormalTexture():SetTexCoord(0, 0.25, 0, 1)
        control:SetCheckedTexture("Interface\\Buttons\\UI-RadioButton")
        control:GetCheckedTexture():SetTexCoord(0.25, 0.5, 0, 1)
        control:SetHighlightTexture("Interface\\Buttons\\UI-RadioButton")
        control:GetHighlightTexture():SetTexCoord(0.5, 0.75, 0, 1)
        control.label = text(choice == "short" and "Short" or "Long", 40 + (i - 1) * 66, y - 24, 40, true)
        control:SetHitRectInsets(0, -40, 0, 0)
        control:SetScript("OnClick", function()
            SlashCmdList.JINXYTOUCH((kind == "soul" and "soul " or "") .. choice)
        end)
        controls[choice] = control
    end
    local preview = CreateFrame("Button", nil, menu, "UIPanelButtonTemplate")
    preview:SetSize(72, 22)
    preview:SetPoint("TOPRIGHT", -18, y - 19)
    preview:SetText("Preview")
    preview:SetScript("OnClick", function() SlashCmdList.JINXYTOUCH(kind == "soul" and "test soul" or "test") end)
    rows[kind] = controls
end
ability("touch", "Touch of the Magi", -83)
ability("soul", "Arcane Soul", -133)
text("Timing is estimated.\nLong Soul adds Burn.", 18, -183, 224, true)
local stop = CreateFrame("Button", nil, menu, "UIPanelButtonTemplate")
stop:SetSize(112, 24)
stop:SetPoint("BOTTOM", 0, 12)
stop:SetText("Stop countdowns")
stop:SetScript("OnClick", function() SlashCmdList.JINXYTOUCH("stop") end)
local function refresh()
    local db = addon.GetSettings()
    if not db then return end
    local arcane, soul = addon.GetEligibility()
    enabled:SetChecked(db.enabled)
    status:SetText(not db.enabled and "Disabled" or (not arcane and "Paused outside Arcane" or (soul and "Arcane: Touch + Soul" or "Arcane: Touch only")))
    for kind, controls in pairs(rows) do
        for choice, control in pairs(controls) do control:SetChecked(db[kind .. "Wording"] == choice) end
    end
end
addon.RefreshMenu = refresh
addon.SetMenu(menu, refresh)
menu:SetScript("OnShow", function(self)
    refresh()
    local db = addon.GetSettings()
    local p = db and db.menuPosition
    local anchors = {CENTER=true, TOP=true, BOTTOM=true, LEFT=true, RIGHT=true, TOPLEFT=true, TOPRIGHT=true, BOTTOMLEFT=true, BOTTOMRIGHT=true}
    if type(p) == "table" and anchors[p.point] and anchors[p.relativePoint] and type(p.x) == "number" and type(p.y) == "number" then
        self:ClearAllPoints(); self:SetPoint(p.point, UIParent, p.relativePoint, p.x, p.y)
    end
end)
menu:Hide()
