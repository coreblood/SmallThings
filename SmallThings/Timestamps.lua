--[[ SmallThings — Chat timestamps  (v1.4.1 rework)
     Grey hh:mm before every line in the default chat windows.

     v1.4.0 used the showTimestamps CVar — which turned out to be a
     CATACLYSM feature; 3.3.5a doesn't have it, and the pcall guards
     swallowed the failure silently. The correct Wrath-era mechanism is
     prefixing at AddMessage level on each chat frame, which is what this
     does now.

     The wrapper checks the option per line, so ticking/unticking applies
     instantly to new messages; already-printed lines are never rewritten.
     The combat log (ChatFrame2) is deliberately excluded — stamping every
     combat event is noise. ]]

local ADDON, ns = ...

local function Wrap(frame)
    local orig = frame.AddMessage
    frame.AddMessage = function(self, text, ...)
        if ns.db and ns.db.chatTimestamps and type(text) == "string" then
            text = date("|cff9a9a9a%H:%M|r ") .. text
        end
        return orig(self, text, ...)
    end
end

for i = 1, NUM_CHAT_WINDOWS do
    local frame = _G["ChatFrame" .. i]
    if frame and frame ~= COMBATLOG then
        Wrap(frame)
    end
end

-- one-time cleanup of the leftover v1.4.0 saved-CVar field
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    if ns.db then ns.db.timestampSaved = nil end
end)
