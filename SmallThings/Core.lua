--[[ SmallThings — Core
     Saved variables, options panel (Interface -> AddOns), slash command,
     login stamp. All UI is built lazily after ADDON_LOADED (3.3.5a rule). ]]

local ADDON, ns = ...

ns.version = "1.5.1"

local defaults = {
    instantDestroy = false, -- dangerous, ships OFF
    tooltipIDs     = true,  -- cosmetic, replaces standalone IDTip
    itemMenu       = true,  -- Alt+Right-click menu on bag items
    sellGreys      = true,  -- pure junk, safe
    sellWhites     = false, -- aggressive: EVERYTHING white, ships OFF
    maxCameraZoom  = true,  -- comfort
    errorFilter    = true,  -- mute resource/cooldown spam
    crispGraphics  = false, -- real FPS cost, ships OFF
    classChatColors = true, -- pure cosmetics
    minimapButton  = true,  -- the cog on the minimap rim
    chatTimestamps = true,  -- grey hh:mm on every chat line
    autoReset      = false, -- sends a server command, ships OFF
    minimapPos     = 220,   -- saved drag angle (degrees), not a checkbox
}

-- ---------------------------------------------------------------- options UI

local function BuildPanel()
    local p = CreateFrame("Frame", "SmallThingsOptionsPanel", UIParent)
    p.name = "SmallThings"

    local title = p:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("SmallThings v" .. ns.version)

    local sub = p:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    sub:SetText("Tick what you want. Changes apply immediately.")

    local y = -64
    local function Check(key, label, tip, onChange)
        local cb = CreateFrame("CheckButton", "SmallThingsOpt" .. key, p,
                               "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", 16, y)
        y = y - 30
        _G[cb:GetName() .. "Text"]:SetText(label)
        cb.tooltipText = tip
        cb:SetChecked(ns.db[key])
        cb:SetScript("OnClick", function(self)
            -- 3.3.5 GetChecked() returns 1/nil, coerce to a clean boolean
            ns.db[key] = self:GetChecked() and true or false
            if onChange then onChange() end
        end)
    end

    Check("instantDestroy", "Instant destroy",
          "Skip every delete confirmation, including the type-DELETE box. "
          .. "Items on the cursor are destroyed the moment the game would ask. No undo.")
    Check("tooltipIDs", "Show IDs in tooltips",
          "Item, enchant, spell, aura and talent IDs on tooltips.")
    Check("itemMenu", "Alt+Right-click item menu",
          "Small menu on bag items: Equip / Stash to Vault / Split.")
    Check("sellGreys", "Auto-sell greys",
          "Sell every grey item automatically when a vendor window opens.")
    Check("sellWhites", "Auto-sell whites (EVERYTHING white)",
          "Sell every white item with a sell price: gear, consumables, trade goods, "
          .. "recipes — everything. Vendor buyback only holds the last 12 items.")
    Check("maxCameraZoom", "Max camera zoom",
          "Raise the camera distance cap to the client maximum (50). "
          .. "Unticking restores the default (15).", function()
              if ns.ApplyCameraZoom then ns.ApplyCameraZoom() end
          end)
    Check("errorFilter", "UI error spam filter",
          "Mute 'not enough rage/mana/energy' and 'not ready yet' center-screen "
          .. "spam. Real errors (inventory full, out of range, ...) still show.")
    Check("crispGraphics", "Crisp graphics",
          "CVar preset past the video sliders: view distance 1277, dense ground "
          .. "clutter, full clouds/weather, 8x multisampling (MSAA needs a relog). "
          .. "Costs FPS in crowded zones. Unticking restores your previous values.",
          function()
              if ns.ApplyCrisp then ns.ApplyCrisp() end
          end)
    Check("classChatColors", "Class-colored chat names",
          "Color player names in every chat type by their class, using the "
          .. "client's native flag. Unticking restores your previous per-channel "
          .. "settings.", function()
              if ns.ApplyClassColors then ns.ApplyClassColors() end
          end)
    Check("minimapButton", "Minimap button",
          "A small cog on the minimap rim. Click opens this panel; drag to "
          .. "move it around the rim.", function()
              if ns.UpdateMinimapButton then ns.UpdateMinimapButton() end
          end)
    Check("chatTimestamps", "Chat timestamps",
          "Grey hh:mm before every line in the chat windows (combat log "
          .. "excluded). Applies to new messages instantly.")
    Check("autoReset", "Auto-reset dungeons",
          "Send the server's .reset command automatically when you leave a "
          .. "dungeon. The server's own reply confirms or refuses it.")

    InterfaceOptions_AddCategory(p)
    ns.panel = p
end

-- ------------------------------------------------------------------- events

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON then
        SmallThingsDB = SmallThingsDB or {}
        for k, v in pairs(defaults) do
            if SmallThingsDB[k] == nil then SmallThingsDB[k] = v end
        end
        ns.db = SmallThingsDB
        BuildPanel()
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        -- The one permitted chat line: the login stamp.
        DEFAULT_CHAT_FRAME:AddMessage("|cff7fd5ffSmallThings|r v" .. ns.version
                                      .. " — /smallthings for options.")
    end
end)

-- -------------------------------------------------------------------- slash

SLASH_SMALLTHINGS1 = "/smallthings"
SLASH_SMALLTHINGS2 = "/sthings"
SlashCmdList["SMALLTHINGS"] = function()
    if ns.panel then
        -- Called twice on purpose: 3.3.5 sometimes opens the wrong category
        -- on the first call; the second lands correctly and is harmless.
        InterfaceOptionsFrame_OpenToCategory(ns.panel)
        InterfaceOptionsFrame_OpenToCategory(ns.panel)
    end
end
