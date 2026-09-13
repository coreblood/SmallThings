--[[ SmallThings — Auto-vote deeper
     Whenever a gossip window opens that contains a "go deeper" option —
     "Vote to go deeper." on group runs, plain "Go deeper." on solo runs —
     that option is clicked instantly AND the window is suppressed — the
     book never visibly opens. Matched by the option's own text (case-
     insensitive), so other NPC dialogs are left completely alone.

     While the tick is on you can never vote to stop — untick it in the
     options panel to vote manually. ]]

local ADDON, ns = ...

local suppressUntil = 0

local f = CreateFrame("Frame")
f:RegisterEvent("GOSSIP_SHOW")
f:SetScript("OnEvent", function()
    if not (ns.db and ns.db.autoVoteDeeper) then return end
    local opts = { GetGossipOptions() }
    -- 3.3.5a returns text1, type1, text2, type2, ...
    for i = 1, #opts, 2 do
        local text = opts[i]
        if type(text) == "string"
           and text:lower():find("go deeper", 1, true) then
            SelectGossipOption((i + 1) / 2)
            -- Kill the window so the book never visibly opens. Blizzard's
            -- own GOSSIP_SHOW handler may run after ours and re-show the
            -- frame, so the OnShow hook below re-hides it within the
            -- suppression window.
            suppressUntil = GetTime() + 0.5
            if GossipFrame then HideUIPanel(GossipFrame) end
            return
        end
    end
end)

if GossipFrame and GossipFrame.HookScript then
    GossipFrame:HookScript("OnShow", function(self)
        if GetTime() < suppressUntil then HideUIPanel(self) end
    end)
end
