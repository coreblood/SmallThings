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

-- ---------------------------------------------------------------------------
-- Hide FRIEND login/logout system messages. Matched against the client's own
-- ERR_FRIEND_ONLINE_SS / ERR_FRIEND_OFFLINE_S templates (same exact-template
-- approach as the error filter above), then the name is checked against your
-- friends list — guild members who aren't friends still show, and no other
-- system message can ever be caught.
-- ---------------------------------------------------------------------------
local function toPattern(fs)
    fs = fs:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0") -- escape all magics
    fs = fs:gsub("%%%%s", "(.+)")                      -- %s -> capture
    return "^" .. fs .. "$"
end
local onlinePat  = toPattern(ERR_FRIEND_ONLINE_SS or
    "|Hplayer:%s|h[%s]|h has come online.")
local offlinePat = toPattern(ERR_FRIEND_OFFLINE_S or "%s has gone offline.")

local friends = {}
local function RebuildFriends()
    wipe(friends)
    for i = 1, GetNumFriends() do
        local name = GetFriendInfo(i)
        if name then friends[name:lower()] = true end
    end
end

local fl = CreateFrame("Frame")
fl:RegisterEvent("FRIENDLIST_UPDATE")
fl:RegisterEvent("PLAYER_LOGIN")
fl:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then ShowFriends() end -- ask once; the reply
    RebuildFriends()                                  -- fires FRIENDLIST_UPDATE
end)

ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(_, _, msg)
    if not (ns.db and ns.db.hideFriendLogin) then return false end
    local a, b = msg:match(onlinePat)
    local name = b or a or msg:match(offlinePat)
    if name and friends[name:lower()] then return true end
    return false
end)
