--[[ SmallThings — Class-colored chat names
     Flips the client's NATIVE per-chat-type "color names by class" flag for
     every chat type at once — the thing you'd otherwise toggle channel by
     channel in the chat settings. No message rewriting, no hooks, so links
     and other chat addons are untouched.

     Ticking saves your existing per-type flags first; unticking restores
     exactly what you had. The client only colors players whose class it has
     seen (group, guild, nearby, targeted) — strangers in Trade may stay
     uncolored until met. That is a client limitation, not a bug. ]]

local ADDON, ns = ...

local TYPES = {
    "SAY", "EMOTE", "YELL",
    "WHISPER", "AFK", "DND",
    "PARTY", "PARTY_LEADER",
    "RAID", "RAID_LEADER", "RAID_WARNING",
    "GUILD", "OFFICER",
    "BATTLEGROUND", "BATTLEGROUND_LEADER",
    "CHANNEL1", "CHANNEL2", "CHANNEL3", "CHANNEL4", "CHANNEL5",
    "CHANNEL6", "CHANNEL7", "CHANNEL8", "CHANNEL9", "CHANNEL10",
}

local function setType(t, on)
    -- pcall: harmless if a type doesn't exist on this client
    pcall(SetChatColorNameByClass, t, on)
end

function ns.ApplyClassColors()
    if not ns.db then return end
    if ns.db.classChatColors then
        if not ns.db.classColorsSaved then
            local saved = {}
            for _, t in ipairs(TYPES) do
                local info = ChatTypeInfo[t]
                saved[t] = (info and info.colorNameByClass) and true or false
            end
            ns.db.classColorsSaved = saved
        end
        for _, t in ipairs(TYPES) do setType(t, true) end
    elseif ns.db.classColorsSaved then
        for _, t in ipairs(TYPES) do
            setType(t, ns.db.classColorsSaved[t])
        end
        ns.db.classColorsSaved = nil
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    if ns.db and ns.db.classChatColors then ns.ApplyClassColors() end
end)
