-- Cast-timed reminder for build 12.1.5. This estimates the normal 45s cooldown;
-- it does not read protected cooldown values or decide when Touch should be cast.
local frame = CreateFrame("Frame")
local timers = {touch = {}, soul = {}}
local soundHandle
local soulSeconds = 17.4 -- Observed Surge gain -> Soul gain in this character's 12.1.5 logs.
-- A cast-timed estimate, not an aura-expiration measurement; configurable below.
local db
local options
local function cancel(kind)
    if not kind then
        cancel("touch"); cancel("soul")
        if soundHandle then StopSound(soundHandle); soundHandle = nil end
        return
    end
    for _, timer in ipairs(timers[kind]) do timer:Cancel() end
    wipe(timers[kind])
end
local function say(clip)
    -- Let a short label finish before its numbers. Separate timers never cancel
    -- one another; overlapping cues can share the Master channel.
    local _, handle = PlaySoundFile("Interface\\AddOns\\JinxyTouchCountdown\\Sounds\\" .. clip .. ".wav", "Master")
    soundHandle = handle
end
local function schedule(kind, duration)
    cancel(kind)
    if not db or not db.enabled then return end
    local deadline = GetTime() + duration
    local function at(remaining, clip)
        timers[kind][#timers[kind] + 1] = C_Timer.NewTimer(duration - remaining, function()
            if db.enabled and math.abs(deadline - GetTime() - remaining) < 0.5 then say(clip) end
        end)
    end
    -- Announce the ability before the first number, so 3/2/1 land at -3/-2/-1.
    local longTouch = kind == "touch" and db.touchWording == "long"
    local longSoul = kind == "soul" and db.soulWording == "long"
    local label = longTouch and "touch_long" or (longSoul and "soul_long" or kind)
    at(db.lead + (longTouch and 2.25 or 2), label)
    for number = db.lead, 1, -1 do at(number, tostring(number)) end
    -- This is the configured cast-timed Soul estimate, not confirmed aura gain.
    if longSoul then at(0, "burn") end
end
local function message(text) print("|cffb9a1ffJinxy Drift:|r " .. text) end
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_DEAD")
frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
frame:SetScript("OnEvent", function(_, event, unit, _, spellID)
    if event == "ADDON_LOADED" then
        if unit ~= "JinxyTouchCountdown" then return end
        JinxyTouchCountdownDB = type(JinxyTouchCountdownDB) == "table" and JinxyTouchCountdownDB or {}
        db = JinxyTouchCountdownDB
        if db.enabled == nil then db.enabled = true end
        if db.touchWording ~= "long" then db.touchWording = "short" end
        if db.soulWording ~= "long" then db.soulWording = "short" end
        if db.audioVersion ~= 2 then db.lead = 3; db.audioVersion = 2 end
        if db.lead ~= 3 and db.lead ~= 5 then db.lead = 3 end
        if type(db.soulSeconds) ~= "number" or db.soulSeconds < 10 or db.soulSeconds > 30 then db.soulSeconds = soulSeconds end
    elseif event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_DEAD" then
        cancel()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" and unit == "player" then
        if issecretvalue and issecretvalue(spellID) then return end
        if spellID == 321507 then schedule("touch", 45)
        elseif spellID == 365350 then schedule("soul", db.soulSeconds) end
    end
end)
SLASH_JINXYTOUCH1 = "/jinxytouch"
SLASH_JINXYTOUCH2 = "/jinxydrift"
SlashCmdList.JINXYTOUCH = function(input)
    if not db then return end
    local command = (input or ""):lower():match("^%s*(.-)%s*$")
    local seconds = tonumber(command:match("^soul%s+([%d.]+)$"))
    local soulWording = command:match("^soul%s+(%a+)$")
    if command == "" or command == "menu" or command == "options" then
        if options then options:Show() end
    elseif command == "short" or command == "long" then
        db.touchWording = command; cancel()
        message("Touch wording: " .. command .. ".")
        if options and options:IsShown() then options:Hide(); options:Show() end
    elseif soulWording == "short" or soulWording == "long" then
        db.soulWording = soulWording; cancel("soul")
        message("Soul wording: " .. soulWording .. ".")
        if options and options:IsShown() then options:Hide(); options:Show() end
    elseif seconds and seconds >= 10 and seconds <= 30 then
        db.soulSeconds = seconds; cancel("soul")
        message("Soul reminder: " .. seconds .. "s after Surge success (estimate).")
    elseif command == "3" or command == "5" then
        db.lead = tonumber(command); cancel()
        message("Countdown starts at " .. db.lead .. ". Applies from your next Touch or Surge cast.")
    elseif command == "on" or command == "off" then
        db.enabled = command == "on"; cancel()
        message(db.enabled and "Enabled. Waiting for your next Touch or Surge cast." or "Disabled.")
    elseif command == "test" or command == "test soul" then
        if db.enabled then cancel(); schedule(command == "test soul" and "soul" or "touch", db.lead + 3.25); message("Audio test starting shortly.")
        else message("Enable first with /jinxytouch on.") end
    elseif command == "stop" then cancel(); message("Current countdown cancelled.")
    else
        message((db.enabled and "On" or "Off") .. ", Touch " .. db.touchWording .. ", Soul " .. db.soulWording .. ", " .. db.lead .. " second lead. Commands: menu, short, long, soul short, soul long, 3, 5, on, off, test, test soul, soul SECONDS, stop.")
    end
end

-- Small standalone menu: no dependency on another addon's options UI.
options = CreateFrame("Frame", "JinxyTouchCountdownOptions", UIParent, "BasicFrameTemplateWithInset")
options:SetSize(370, 380)
options:SetPoint("CENTER")
options:SetMovable(true)
options:EnableMouse(true)
options:RegisterForDrag("LeftButton")
options:SetClampedToScreen(true)
options:SetScript("OnDragStart", options.StartMoving)
options:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if db then
        local point, _, relativePoint, x, y = self:GetPoint()
        db.menuPosition = {point = point, relativePoint = relativePoint, x = x, y = y}
    end
end)
options.TitleText:SetText("Jinxy Drift Reminder")
UISpecialFrames[#UISpecialFrames + 1] = "JinxyTouchCountdownOptions"

local enabled = CreateFrame("CheckButton", nil, options, "UICheckButtonTemplate")
enabled:SetPoint("TOPLEFT", 16, -36)
enabled.Text:SetText("Enable voice reminders")
enabled:SetScript("OnClick", function(self)
    if not db then return end
    db.enabled = self:GetChecked() and true or false
    cancel()
end)

local function button(label, x, y, action)
    local control = CreateFrame("Button", nil, options, "UIPanelButtonTemplate")
    control:SetSize(155, 28)
    control:SetPoint("TOPLEFT", x, y)
    control:SetText(label)
    control:SetScript("OnClick", action)
    return control
end
local wording = options:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
wording:SetPoint("TOPLEFT", 20, -80)
wording:SetWidth(330)
wording:SetJustifyH("LEFT")
local short = button("Short: Touch in", 20, -110, function() SlashCmdList.JINXYTOUCH("short") end)
local long = button("Long: full spell name", 195, -110, function() SlashCmdList.JINXYTOUCH("long") end)
local soulLabel = options:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
soulLabel:SetPoint("TOPLEFT", 20, -152)
soulLabel:SetWidth(330)
soulLabel:SetJustifyH("LEFT")
local soulShort = button("Short: Soul in", 20, -182, function() SlashCmdList.JINXYTOUCH("soul short") end)
local soulLong = button("Long: Soul + Burn", 195, -182, function() SlashCmdList.JINXYTOUCH("soul long") end)
local countdownNote = options:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
countdownNote:SetPoint("TOPLEFT", 20, -220)
countdownNote:SetText("Long Soul adds Burn at the estimated Soul start.")
button("Preview Touch", 20, -245, function() SlashCmdList.JINXYTOUCH("test") end)
button("Preview Soul", 195, -245, function() SlashCmdList.JINXYTOUCH("test soul") end)
button("Stop countdowns", 20, -281, function() cancel() end)
local note = options:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
note:SetPoint("BOTTOMLEFT", 20, 16)
note:SetWidth(330)
note:SetJustifyH("LEFT")
note:SetText("Changes apply to your next cast. Soul timing is an estimate.\nDrag this window to move it; Escape closes it.")
options:SetScript("OnShow", function(self)
    if not db then return end
    enabled:SetChecked(db.enabled)
    wording:SetText("Touch wording: " .. (db.touchWording == "long" and "Touch of the Magi in" or "Touch in"))
    short:SetEnabled(db.touchWording ~= "short")
    long:SetEnabled(db.touchWording ~= "long")
    soulLabel:SetText("Soul wording: " .. (db.soulWording == "long" and "Arcane Soul in + Burn" or "Soul in"))
    soulShort:SetEnabled(db.soulWording ~= "short")
    soulLong:SetEnabled(db.soulWording ~= "long")
    local position = db.menuPosition
    if type(position) == "table" and type(position.x) == "number" and type(position.y) == "number" then
        self:ClearAllPoints()
        self:SetPoint(position.point or "CENTER", UIParent, position.relativePoint or "CENTER", position.x, position.y)
    end
end)
options:Hide()
