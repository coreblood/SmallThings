--[[ SmallThings — UI error spam filter
     Mutes the center-screen red spam: out-of-resource and cooldown messages.
     Everything else (inventory full, out of range, wrong target, ...) passes
     through untouched.

     Mechanism: UIErrorsFrame stops receiving UI_ERROR_MESSAGE; our frame
     receives it instead and forwards every message that is not on the spam
     list. Matching is against the client's OWN error strings (the ERR_*
     globals), so it is locale-safe and can never over-match — the same
     strict-matching philosophy as instant destroy. With the option off,
     everything is forwarded, which is pixel-identical to default behavior. ]]

local ADDON, ns = ...

local SPAM = {}
for _, g in ipairs({
    -- out of resource
    "ERR_OUT_OF_RAGE", "ERR_OUT_OF_MANA", "ERR_OUT_OF_ENERGY",
    "ERR_OUT_OF_FOCUS", "ERR_OUT_OF_RUNES", "ERR_OUT_OF_RUNIC_POWER",
    -- not ready yet
    "ERR_ABILITY_COOLDOWN", "ERR_SPELL_COOLDOWN", "ERR_ITEM_COOLDOWN",
}) do
    local s = _G[g]
    if s then SPAM[s] = true end
end

UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE")

local f = CreateFrame("Frame")
f:RegisterEvent("UI_ERROR_MESSAGE")
f:SetScript("OnEvent", function(_, _, msg)
    if ns.db and ns.db.errorFilter and SPAM[msg] then return end
    UIErrorsFrame:AddMessage(msg, 1.0, 0.1, 0.1, 1.0)
end)
