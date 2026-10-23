local replacements = {
    COMBAT_TEXT_MISS = "Miss",
    COMBAT_TEXT_DODGE = "Dodge",
    COMBAT_TEXT_PARRY = "Parry",
    COMBAT_TEXT_EVADE = "Evade",
    COMBAT_TEXT_IMMUNE = "Immune",
    COMBAT_TEXT_DEFLECT = "Deflect",
    COMBAT_TEXT_REFLECT = "Reflect",
    COMBAT_TEXT_MISFIRE = "Misfire",
    COMBAT_TEXT_BLOCK = "Block",
    COMBAT_TEXT_ABSORB = "Absorb",
    COMBAT_TEXT_RESIST = "Resist",

    COMBAT_TEXT_BLOCK_REDUCED = "%s (Block)",

    MISS = "Miss",
    DODGE = "Dodge",
    PARRY = "Parry",
    EVADE = "Evade",
    IMMUNE = "Immune",
    DEFLECT = "Deflect",
    REFLECT = "Reflect",
    BLOCK = "Block",
    ABSORB = "Absorb",
    RESIST = "Resist",

    BLOCK_TRAILER = " (%d blocked)",
    ABSORB_TRAILER = " (%d absorbed)",
    RESIST_TRAILER = " (%d resisted)",

    TEXT_MODE_A_STRING_RESULT_BLOCK = "(%s Blocked)",

    ACTION_SWING_MISSED_BLOCK = "(Blocked)",
    ACTION_RANGE_MISSED_BLOCK = "(Blocked)",
    ACTION_SPELL_MISSED_BLOCK = "Blocked",
    ACTION_SPELL_PERIODIC_MISSED_BLOCK = "(Tick Blocked)",
    ACTION_DAMAGE_SHIELD_MISSED_BLOCK = "(Blocked)",

    HEALTH_LOW = "Health Low",
    MANA_LOW = "Mana Low",
    ENTERING_COMBAT = "Entering Combat",
    LEAVING_COMBAT = "Leaving Combat",
    AURA_END = "<%s> fades",
    COMBAT_TEXT_HONOR_GAINED = "Honor %s",
    COMBAT_TEXT_COMBO_POINTS = "<%d Combo |4Point:Points;>",
    COMBAT_TEXT_RUNE_DEATH = "Rune",
    XP_GAIN = "XP:%s",

    COMBAT_THREAT_DECREASE_0 = "Changed Target!",
    COMBAT_THREAT_DECREASE_1 = "Changed Target!",
    COMBAT_THREAT_DECREASE_2 = "Losing Threat",
    COMBAT_THREAT_INCREASE_1 = "High Threat",
    COMBAT_THREAT_INCREASE_3 = "Attacking You!",
}

local messageReplacements = {
    ["<\208\158\209\130\208\178\208\181\209\130\208\189\209\139\208\185 \209\131\208\180\208\176\209\128>"] = "<Riposte>",
}

local originalCombatTextAddMessage

local function ApplyReplacements()
    for globalName, value in pairs(replacements) do
        _G[globalName] = value
    end
end

local function InstallMessageReplacementHook()
    local combatText = _G.CombatText
    if originalCombatTextAddMessage or not combatText or type(combatText.AddMessage) ~= "function" then
        return
    end

    originalCombatTextAddMessage = combatText.AddMessage
    combatText.AddMessage = function(self, message, ...)
        if not issecretvalue(message) then
            message = messageReplacements[message] or message
        end
        return originalCombatTextAddMessage(self, message, ...)
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

frame:SetScript("OnEvent", function()
    ApplyReplacements()
    InstallMessageReplacementHook()
    if C_Timer and C_Timer.After then
        C_Timer.After(0, ApplyReplacements)
        C_Timer.After(0.5, ApplyReplacements)
        C_Timer.After(1, ApplyReplacements)
        C_Timer.After(3, ApplyReplacements)
    end
end)

SLASH_SHORTCOMBATTEXT1 = "/sctfix"
SlashCmdList.SHORTCOMBATTEXT = function()
    ApplyReplacements()
    InstallMessageReplacementHook()
    print("Short Combat Text: labels reapplied.")
end

SLASH_SHORTCOMBATTEXTDEBUG1 = "/sctdebug"
SlashCmdList.SHORTCOMBATTEXTDEBUG = function()
    print("COMBAT_TEXT_BLOCK =", tostring(_G.COMBAT_TEXT_BLOCK))
    print("COMBAT_TEXT_BLOCK_REDUCED =", tostring(_G.COMBAT_TEXT_BLOCK_REDUCED))
    print("BLOCK_TRAILER =", tostring(_G.BLOCK_TRAILER))
    print("COMBAT_THREAT_INCREASE_1 =", tostring(_G.COMBAT_THREAT_INCREASE_1))
    print("COMBAT_THREAT_INCREASE_3 =", tostring(_G.COMBAT_THREAT_INCREASE_3))
    print("XP_GAIN =", tostring(_G.XP_GAIN))
    print("Riposte message hook =", originalCombatTextAddMessage and "installed" or "waiting")
end
