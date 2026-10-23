local registeredEvents = {}
local eventHandler
local timers = {}
local messages = {}
local combatTextMessages = {}
local messagesAreSecret = false
local originalPrint = print

local frame = {}

function frame:RegisterEvent(event)
    registeredEvents[event] = true
end

function frame:SetScript(scriptType, handler)
    assert(scriptType == "OnEvent", "unexpected frame script")
    eventHandler = handler
end

CreateFrame = function(frameType)
    assert(frameType == "Frame", "unexpected frame type")
    return frame
end

C_Timer = {
    After = function(delay, callback)
        timers[#timers + 1] = { delay = delay, callback = callback }
    end,
}

issecretvalue = function()
    return messagesAreSecret
end

SlashCmdList = {}

print = function(...)
    local values = {}
    for index = 1, select("#", ...) do
        values[index] = tostring(select(index, ...))
    end
    messages[#messages + 1] = table.concat(values, " ")
end

dofile("ShortCombatText.lua")

assert(registeredEvents.ADDON_LOADED, "ADDON_LOADED was not registered")
assert(registeredEvents.PLAYER_LOGIN, "PLAYER_LOGIN was not registered")
assert(registeredEvents.PLAYER_ENTERING_WORLD, "PLAYER_ENTERING_WORLD was not registered")
assert(type(eventHandler) == "function", "OnEvent handler was not installed")

eventHandler("PLAYER_LOGIN")

local expectedGlobals = {
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

for globalName, expectedValue in pairs(expectedGlobals) do
    assert(_G[globalName] == expectedValue, globalName .. " was not replaced")
end

assert(#timers == 4, "expected four delayed reapplications")
assert(timers[1].delay == 0, "unexpected first timer delay")
assert(timers[2].delay == 0.5, "unexpected second timer delay")
assert(timers[3].delay == 1, "unexpected third timer delay")
assert(timers[4].delay == 3, "unexpected fourth timer delay")

COMBAT_TEXT_MISS = "changed"
timers[1].callback()
assert(COMBAT_TEXT_MISS == "Miss", "timer did not reapply replacements")

CombatText = {}
function CombatText:AddMessage(message, scrollFunction)
    combatTextMessages[#combatTextMessages + 1] = message
    return message, scrollFunction
end

eventHandler("ADDON_LOADED", "Blizzard_CombatText")

local localizedRiposte = "<\208\158\209\130\208\178\208\181\209\130\208\189\209\139\208\185 \209\131\208\180\208\176\209\128>"
local returnedMessage, returnedScroll = CombatText:AddMessage(localizedRiposte, "scroll")
assert(combatTextMessages[#combatTextMessages] == "<Riposte>", "Riposte was not translated")
assert(returnedMessage == "<Riposte>", "translated message was not returned")
assert(returnedScroll == "scroll", "message arguments were not forwarded")

CombatText:AddMessage("<Overpower>", "scroll")
assert(combatTextMessages[#combatTextMessages] == "<Overpower>", "unmapped message was changed")

messagesAreSecret = true
CombatText:AddMessage(localizedRiposte, "scroll")
messagesAreSecret = false
assert(combatTextMessages[#combatTextMessages] == localizedRiposte, "secret message was inspected")

COMBAT_TEXT_MISS = "changed"
SlashCmdList.SHORTCOMBATTEXT()
assert(COMBAT_TEXT_MISS == "Miss", "/sctfix did not reapply replacements")
assert(messages[#messages] == "Short Combat Text: labels reapplied.", "/sctfix confirmation changed")

SlashCmdList.SHORTCOMBATTEXTDEBUG()
assert(messages[#messages] == "Riposte message hook = installed", "/sctdebug output changed")

originalPrint("ShortCombatText tests passed.")
