--[[ SmallThings — Auto-vote deeper
     Whenever a gossip window opens that contains a "Vote to go deeper"
     option, that option is clicked instantly — the vote fires before the
     window finishes drawing. Matched by the option's own text (case-
     insensitive, punctuation-tolerant), so no other NPC dialog can ever
     be caught; windows without the option are left completely alone.

     While the tick is on you can never vote to stop — untick it in the
     options panel to vote manually. ]]

local ADDON, ns = ...

local f = CreateFrame("Frame")
f:RegisterEvent("GOSSIP_SHOW")
f:SetScript("OnEvent", function()
    if not (ns.db and ns.db.autoVoteDeeper) then return end
    local opts = { GetGossipOptions() }
    -- 3.3.5a returns text1, type1, text2, type2, ...
    for i = 1, #opts, 2 do
        local text = opts[i]
        if type(text) == "string"
           and text:lower():find("vote to go deeper", 1, true) then
            SelectGossipOption((i + 1) / 2)
            return
        end
    end
end)
