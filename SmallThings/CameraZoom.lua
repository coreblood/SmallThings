--[[ SmallThings — Max camera zoom
     Ticked: camera distance cap raised to the client maximum (50).
     Unticked: restored to the game default (15).
     The CVar persists between sessions, but it is re-applied at login so the
     checkbox always tells the truth even if something else touched it. ]]

local ADDON, ns = ...

local MAX_ZOOM, DEFAULT_ZOOM = "50", "15"

function ns.ApplyCameraZoom()
    if not ns.db then return end
    SetCVar("cameraDistanceMax", ns.db.maxCameraZoom and MAX_ZOOM or DEFAULT_ZOOM)
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function() ns.ApplyCameraZoom() end)
