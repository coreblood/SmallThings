--[[ SmallThings — Core
     Saved variables, options panel (Interface -> AddOns), slash command,
     login stamp. All UI is built lazily after ADDON_LOADED (3.3.5a rule). ]]

local ADDON, ns = ...

ns.version = "1.7.0"

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
    autoResetMythic = false, -- sends .mythic reset on exit, ships OFF
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

    -- Two columns of grouped checkboxes. y is tracked per column.
    local COL_X  = { 16, 222 }   -- column left edges
    local TOP_Y  = -64           -- first header line
    local ROW_H  = 24            -- checkbox row height (small font)
    local GAP    = 14            -- extra gap between groups
    local y      = { TOP_Y, TOP_Y }

    local function Header(col, text)
        local h = p:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        h:SetPoint("TOPLEFT", COL_X[col], y[col])
        h:SetText(text)
        local line = p:CreateTexture(nil, "ARTWORK")
        line:SetTexture(1, 1, 1, 0.25)
        line:SetHeight(1)
        line:SetPoint("TOPLEFT", h, "BOTTOMLEFT", 0, -3)
        line:SetPoint("RIGHT", p, "LEFT", COL_X[col] + 176, 0)
        y[col] = y[col] - 24
    end

    local function Check(col, indent, key, label, tip, danger, onChange)
        local cb = CreateFrame("CheckButton", "SmallThingsOpt" .. key, p,
                               "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", COL_X[col] + indent, y[col])
        y[col] = y[col] - ROW_H
        local text = _G[cb:GetName() .. "Text"]
        text:SetFontObject("GameFontHighlightSmall")
        text:SetText(label)
        if danger then text:SetTextColor(1, 0.35, 0.35) end
        cb.tooltipText = tip
        cb:SetChecked(ns.db[key])
        cb:SetScript("OnClick", function(self)
            -- 3.3.5 GetChecked() returns 1/nil, coerce to a clean boolean
            ns.db[key] = self:GetChecked() and true or false
            if onChange then onChange() end
        end)
    end

    -- ------------------------------------------------- left column
    Header(1, "Items & Vendor")
    Check(1, 0, "instantDestroy", "Instant destroy",
          "Skip every delete confirmation, including the type-DELETE box. "
          .. "Items on the cursor are destroyed the moment the game would ask. No undo.")
    Check(1, 0, "itemMenu", "Alt+Right-click item menu",
          "Small menu on bag items: Equip / Stash to Vault / Split.")
    Check(1, 0, "sellGreys", "Auto-sell greys",
          "Sell every grey item automatically when a vendor window opens.")
    Check(1, 16, "sellWhites", "Auto-sell whites (EVERYTHING white)",
          "Sell every white item with a sell price: gear, consumables, trade goods, "
          .. "recipes — everything. Vendor buyback only holds the last 12 items.", true)

    y[1] = y[1] - GAP
    Header(1, "Chat")
    Check(1, 0, "classChatColors", "Class-colored chat names",
          "Color player names in every chat type by their class, using the "
          .. "client's native flag. Unticking restores your previous per-channel "
          .. "settings.", nil, function()
              if ns.ApplyClassColors then ns.ApplyClassColors() end
          end)
    Check(1, 0, "chatTimestamps", "Chat timestamps",
          "Grey hh:mm before every line in the chat windows (combat log "
          .. "excluded). Applies to new messages instantly.")

    y[1] = y[1] - GAP
    Header(1, "Tooltips")
    Check(1, 0, "tooltipIDs", "Show IDs in tooltips",
          "Item, enchant, spell, aura and talent IDs on tooltips.")

    -- ------------------------------------------------ right column
    Header(2, "UI & Graphics")
    Check(2, 0, "maxCameraZoom", "Max camera zoom",
          "Raise the camera distance cap to the client maximum (50). "
          .. "Unticking restores the default (15).", nil, function()
              if ns.ApplyCameraZoom then ns.ApplyCameraZoom() end
          end)
    Check(2, 0, "errorFilter", "UI error spam filter",
          "Mute 'not enough rage/mana/energy' and 'not ready yet' center-screen "
          .. "spam. Real errors (inventory full, out of range, ...) still show.")
    Check(2, 0, "crispGraphics", "Crisp graphics",
          "CVar preset past the video sliders: view distance 1277, dense ground "
          .. "clutter, full clouds/weather, 8x multisampling (MSAA needs a relog). "
          .. "Costs FPS in crowded zones. Unticking restores your previous values.",
          nil, function()
              if ns.ApplyCrisp then ns.ApplyCrisp() end
          end)
    Check(2, 0, "minimapButton", "Minimap button",
          "A small cog on the minimap rim. Click opens this panel; drag to "
          .. "move it around the rim.", nil, function()
              if ns.UpdateMinimapButton then ns.UpdateMinimapButton() end
          end)

    y[2] = y[2] - GAP
    Header(2, "Dungeons")
    Check(2, 0, "autoReset", "Auto-reset (dungeons & raids)",
          "Send the server's .reset command automatically when you leave a "
          .. "dungeon or raid. The server's own reply confirms or refuses it.")
    Check(2, 16, "autoResetMythic", "Auto-reset mythic",
          "Also send the server's .mythic reset command when you leave an "
          .. "instance. The server refuses it if the run wasn't mythic. "
          .. "Works with or without the tick above.")

    local foot = p:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    foot:SetPoint("BOTTOMRIGHT", -16, 16)
    foot:SetText("by Mhortai")

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
