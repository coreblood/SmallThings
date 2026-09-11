--[[ SmallThings — Auto-reset (dungeons & raids) + mythic
     When you leave an instance (party or raid -> outside world), sends the
     server's `.reset` dot-command exactly once — and, if the mythic tick is
     on, `.mythic reset` as well. The two ticks are independent: either one
     alone still fires its own command on exit. Dot-commands are intercepted
     server-side and never broadcast; the server's own confirmation/refusal
     prints as a system message, and it refuses whichever command doesn't
     apply to the run just left.

     Trigger logic: PLAYER_ENTERING_WORLD transitions tracked via
     IsInInstance(). Fires only on instance -> world transitions —
     never at login (previous state starts unknown), never when zoning
     BETWEEN instances. If group members are still inside, the server
     refuses the reset itself; we just send. ]]

local ADDON, ns = ...

local prev -- nil until the first PLAYER_ENTERING_WORLD

-- Sends run on a delay: firing at the instant PLAYER_ENTERING_WORLD hits
-- lands on the loading-screen edge, where the server may not yet accept
-- chat from the session and silently drops it (v1.5.1 fix). The two
-- commands are staggered so they never share a frame.
local sendReset, sendMythic
local delay = CreateFrame("Frame")
delay:Hide()
local elapsed = 0
delay:SetScript("OnUpdate", function(self, e)
    elapsed = elapsed + e
    if sendReset and elapsed >= 1.5 then
        sendReset = nil
        SendChatMessage(".reset", "SAY")
    end
    if sendMythic and elapsed >= 1.8 then
        sendMythic = nil
        SendChatMessage(".mythic reset", "SAY")
    end
    if not sendReset and not sendMythic then
        self:Hide()
    end
end)

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function()
    local inInstance, itype = IsInInstance()
    local cur = (inInstance and itype) or "none"
    if (prev == "party" or prev == "raid") and cur == "none" and ns.db then
        sendReset  = ns.db.autoReset or nil
        sendMythic = ns.db.autoResetMythic or nil
        if sendReset or sendMythic then
            elapsed = 0
            delay:Show()
        end
    end
    prev = cur
end)
