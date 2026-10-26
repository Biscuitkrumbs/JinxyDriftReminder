-- Cast-timed reminder for build 12.1.5. This estimates the normal 45s cooldown;
-- it does not read protected cooldown values or decide when Touch should be cast.
local _, addon = ...
local frame = CreateFrame("Frame")
local timers = {touch = {}, soul = {}}
local soundHandles = {touch = {}, soul = {}}
local soulSeconds = 17.4 -- Observed Surge gain -> Soul gain in this character's 12.1.5 logs.
-- A cast-timed estimate, not an aura-expiration measurement; configurable below.
local db
local options
local refreshMenu
local arcaneActive, soulAvailable = false, false
addon.GetSettings = function() return db end
addon.GetEligibility = function() return arcaneActive, soulAvailable end
addon.SetMenu = function(menu, refresh) options = menu; refreshMenu = refresh end
local function refreshEligibility()
    local getSpec = C_SpecializationInfo and C_SpecializationInfo.GetSpecialization or GetSpecialization
    local getInfo = C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo or GetSpecializationInfo
    local spec = getSpec and getSpec()
    arcaneActive = spec and getInfo and getInfo(spec) == 62 or false
    -- Memory of Al'ar is the selected passive granting Arcane Soul, not the
    -- temporary Soul aura (451038). Unknown eligibility disables automatic Soul.
    local known = IsPlayerSpell or (C_SpellBook and C_SpellBook.IsSpellKnown)
    local ok, selected = false, false
    if arcaneActive and known then ok, selected = pcall(known, 449619) end
    soulAvailable = ok and selected == true
    if refreshMenu then refreshMenu() end
end

-- UI construction is deferred until all command handlers are ready (below).
local function cancel(kind)
    if not kind then
        cancel("touch"); cancel("soul")
        return
    end
    for _, timer in ipairs(timers[kind]) do timer:Cancel() end
    wipe(timers[kind])
    for _, handle in ipairs(soundHandles[kind]) do StopSound(handle) end
    wipe(soundHandles[kind])
end
local function say(clip, kind)
    -- Let a short label finish before its numbers. Separate timers never cancel
    -- one another; overlapping cues can share the Master channel.
    local _, handle = PlaySoundFile("Interface\\AddOns\\JinxyTouchCountdown\\Sounds\\" .. clip .. ".wav", "Master")
    if handle then soundHandles[kind][#soundHandles[kind] + 1] = handle end
end
local function schedule(kind, duration, preview)
    cancel(kind)
    if not db or not db.enabled then return end
    if not preview and (not arcaneActive or (kind == "soul" and not soulAvailable)) then return end
    local deadline = GetTime() + duration
    local function at(remaining, clip)
        timers[kind][#timers[kind] + 1] = C_Timer.NewTimer(duration - remaining, function()
            local allowed = preview or (arcaneActive and (kind ~= "soul" or soulAvailable))
            if db.enabled and allowed and math.abs(deadline - GetTime() - remaining) < 0.5 then say(clip, kind) end
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
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
frame:RegisterEvent("PLAYER_TALENT_UPDATE")
frame:RegisterEvent("TRAIT_CONFIG_UPDATED")
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
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        if unit ~= "player" then return end
        cancel(); refreshEligibility()
    elseif event == "TRAIT_CONFIG_UPDATED" then
        local active = C_ClassTalents and C_ClassTalents.GetActiveConfigID()
        if active and unit ~= active then return end
        cancel(); refreshEligibility()
    elseif event == "PLAYER_TALENT_UPDATE" or event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        cancel(); refreshEligibility()
    elseif event == "PLAYER_DEAD" then
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
        if refreshMenu then refreshMenu() end
    elseif soulWording == "short" or soulWording == "long" then
        db.soulWording = soulWording; cancel("soul")
        message("Soul wording: " .. soulWording .. ".")
        if refreshMenu then refreshMenu() end
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
        if db.enabled then cancel(); schedule(command == "test soul" and "soul" or "touch", db.lead + 3.25, true); message("Audio test starting shortly.")
        else message("Enable first with /jinxytouch on.") end
    elseif command == "stop" then cancel(); message("Current countdown cancelled.")
    else
        message((db.enabled and "On" or "Off") .. ", Touch " .. db.touchWording .. ", Soul " .. db.soulWording .. ", " .. db.lead .. " second lead. Commands: menu, short, long, soul short, soul long, 3, 5, on, off, test, test soul, soul SECONDS, stop.")
    end
    if refreshMenu then refreshMenu() end
end

