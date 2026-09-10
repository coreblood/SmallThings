--[[ SmallThings — Instant destroy
     Auto-confirms the delete dialogs so an item dropped for destruction dies
     immediately, including the type-DELETE box for rare+ items.

     Matches the FOUR delete popups BY NAME and nothing else. Never blind-click
     StaticPopups: matching loosely is exactly how ShardConfirm once auto-
     accepted every group invite. ]]

local ADDON, ns = ...

local POPUPS = {
    DELETE_ITEM            = true,
    DELETE_QUEST_ITEM      = true,
    DELETE_GOOD_ITEM       = true, -- rare+ "type DELETE" box
    DELETE_GOOD_QUEST_ITEM = true,
}

hooksecurefunc("StaticPopup_Show", function(which)
    if not (ns.db and ns.db.instantDestroy) then return end
    if not POPUPS[which] then return end
    if not CursorHasItem() then return end

    -- pcall guard: if the client ever refuses the direct call (taint), we
    -- leave the normal confirmation on screen instead of erroring out —
    -- graceful fallback, nothing is deleted twice.
    local ok = pcall(DeleteCursorItem)
    if ok and not CursorHasItem() then
        StaticPopup_Hide(which)
    end
end)
