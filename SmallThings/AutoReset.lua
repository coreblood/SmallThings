--[[ SmallThings — Auto-reset dungeons
     When you leave a dungeon (party instance -> outside world), sends the
     server's `.reset` dot-command exactly once. Dot-commands are intercepted
     server-side and never broadcast, so nothing appears in public chat; the
     server's own confirmation/refusal prints as a system message.

     Trigger logic: PLAYER_ENTERING_WORLD transitions tracked via
     IsInInstance(). Fires only on party-instance -> non-party transitions —
     never at login (previous state starts unknown), never when zoning
     BETWEEN instances, never on raid exits. If group members are still
     inside, the server refuses the reset itself; we just send. ]]

local ADDON, ns = ...

local prev -- nil until the first PLAYER_ENTERING_WORLD

-- v1.5.1: send on a 1.5 s delay. Firing the command the instant
-- PLAYER_ENTERING_WORLD hits lands on the loading-screen edge, where the
-- server may not yet accept chat from the session and silently drops it.
local delay = CreateFrame("Frame")
delay:Hide()
local elapsed = 0
delay:SetScript("OnUpdate", function(self, e)
    elapsed = elapsed + e
    if elapsed >= 1.5 then
        self:Hide()
        SendChatMessage(".reset", "SAY")
    end
end)

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function()
    local inInstance, itype = IsInInstance()
    local cur = (inInstance and itype) or "none"
    if prev == "party" and cur ~= "party"
       and ns.db and ns.db.autoReset then
        elapsed = 0
        delay:Show()
    end
    prev = cur
end)
