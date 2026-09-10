--[[ SmallThings — Minimap button
     A small cog on the minimap rim. Left-click opens the options panel.
     Drag to move it anywhere around the rim; the angle is saved per account.
     Its visibility is itself a tick ("Minimap button", default ON).

     Zero-dependency classic construction (no LibDBIcon), radian math via
     the standard math.* functions, built lazily after ADDON_LOADED. ]]

local ADDON, ns = ...

local btn
local RADIUS = 80

local function UpdatePosition()
    if not btn then return end
    local angle = math.rad(ns.db.minimapPos or 220)
    btn:SetPoint("CENTER", Minimap, "CENTER",
                 math.cos(angle) * RADIUS, math.sin(angle) * RADIUS)
end

local function OnDragUpdate(self)
    local mx, my = Minimap:GetCenter()
    local cx, cy = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    cx, cy = cx / scale, cy / scale
    ns.db.minimapPos = math.deg(math.atan2(cy - my, cx - mx))
    UpdatePosition()
end

local function Build()
    btn = CreateFrame("Button", "SmallThingsMinimapButton", Minimap)
    btn:SetWidth(31)
    btn:SetHeight(31)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    btn:RegisterForClicks("LeftButtonUp")
    btn:RegisterForDrag("LeftButton")
    btn:SetMovable(true)
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local icon = btn:CreateTexture(nil, "BACKGROUND")
    icon:SetWidth(20)
    icon:SetHeight(20)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Gear_01")
    icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
    icon:SetPoint("TOPLEFT", 6, -6)

    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetWidth(53)
    border:SetHeight(53)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetPoint("TOPLEFT")

    btn:SetScript("OnClick", function()
        if ns.panel then
            InterfaceOptionsFrame_OpenToCategory(ns.panel)
            InterfaceOptionsFrame_OpenToCategory(ns.panel)
        end
    end)
    btn:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", OnDragUpdate)
    end)
    btn:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("SmallThings", 0.5, 0.84, 1.0)
        GameTooltip:AddLine("Click for options. Drag to move.", 1, 1, 1)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    UpdatePosition()
end

function ns.UpdateMinimapButton()
    if not ns.db then return end
    if ns.db.minimapButton then
        if not btn then Build() end
        btn:Show()
        UpdatePosition()
    elseif btn then
        btn:Hide()
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function() ns.UpdateMinimapButton() end)
