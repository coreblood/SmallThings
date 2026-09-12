--[[ SmallThings — Imprint glows
     Colored rings on the character panel's equipped slots: PURPLE when the
     piece carries an IMPRINTED proc (a proc beyond the item's own native
     ones), RED when it carries no imprint yet. All 19 worn slots covered
     (on Uncapped even shirt and tabard take imprints); empty slots and
     pre-data states show nothing, so a fresh login never shows false reds.

     Fully self-contained: listens to the server's own proc streams (the
     ICINV inventory sweep for what each worn piece carries, the ICEXI
     extraction sweep for each item's native procs) — traffic other addons
     or the Dashboard generate is absorbed too — and requests a fresh sweep
     when the character panel opens. No dependency on any other addon. ]]

local ADDON, ns = ...

local ME = UnitName("player")

-- ---- proc data --------------------------------------------------------------
local buckets = {}        -- committed: ["E:<invSlot>"] = { {spell,trigger}, ... }
local nativeByEntry = {}  -- committed: [itemEntry] = { ["spell:trigger"] = true }
local haveData = false
local bStage, bKey       -- ICINV sweep in progress
local nStage             -- ICEXI sweep in progress
local lastReq = 0

local function request()
    if not (ns.db and ns.db.imprintGlow) then return end
    local now = GetTime()
    if now - lastReq < 10 then return end
    lastReq = now
    SendAddonMessage("REAGENTBANK", "ICINV", "WHISPER", ME)
    SendAddonMessage("REAGENTBANK", "ICEXSRC", "WHISPER", ME)
end

-- ---- glow painting ----------------------------------------------------------
local GLOW_SLOTS = {  -- invSlot -> paperdoll button (all 19 worn slots; on
    -- Uncapped even shirt and tabard are valid imprint targets)
    [1] = "CharacterHeadSlot", [2] = "CharacterNeckSlot", [3] = "CharacterShoulderSlot",
    [4] = "CharacterShirtSlot",
    [5] = "CharacterChestSlot", [6] = "CharacterWaistSlot", [7] = "CharacterLegsSlot",
    [8] = "CharacterFeetSlot", [9] = "CharacterWristSlot", [10] = "CharacterHandsSlot",
    [11] = "CharacterFinger0Slot", [12] = "CharacterFinger1Slot",
    [13] = "CharacterTrinket0Slot", [14] = "CharacterTrinket1Slot",
    [15] = "CharacterBackSlot", [16] = "CharacterMainHandSlot",
    [17] = "CharacterSecondaryHandSlot", [18] = "CharacterRangedSlot",
    [19] = "CharacterTabardSlot",
}
local glowTex = {}

local function glowFor(slot)
    local t = glowTex[slot]
    if t then return t end
    local btn = _G[GLOW_SLOTS[slot]]
    if not btn then return nil end
    t = btn:CreateTexture(nil, "OVERLAY")
    t:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    t:SetBlendMode("ADD")
    t:SetPoint("CENTER")
    t:SetSize(66, 66) -- paperdoll buttons are 37x37; the border art needs ~1.8x
    glowTex[slot] = t
    return t
end

local function slotHasImprint(slot)
    local b = buckets["E:" .. slot]
    if not b or #b == 0 then return false end
    local link = GetInventoryItemLink("player", slot)
    local entry = link and tonumber(link:match("item:(%d+)"))
    local native = (entry and nativeByEntry[entry]) or {}
    for _, p in ipairs(b) do
        if not native[p.spell .. ":" .. p.trigger] then return true end
    end
    return false
end

local function Paint()
    if not ns.db then return end
    for slot in pairs(GLOW_SLOTS) do
        local t = glowFor(slot)
        if t then
            if ns.db.imprintGlow and haveData
               and GetInventoryItemLink("player", slot) then
                if slotHasImprint(slot) then
                    t:SetVertexColor(0.65, 0.25, 1.0, 0.9)  -- purple: imprinted
                else
                    t:SetVertexColor(1.0, 0.15, 0.15, 0.8)  -- red: no imprint yet
                end
                t:Show()
            else
                t:Hide()
            end
        end
    end
end
ns.PaintImprintGlows = Paint

-- ---- wire parsing -----------------------------------------------------------
local function onWire(msg)
    -- ICINV dialect: ICITEM headers open a bucket, ICIPROC rows fill it,
    -- ICINVEND commits the sweep wholesale.
    local eSlot = msg:match("^ICITEM:E:(%d+)")
    if eSlot then
        bStage = bStage or {}
        bKey = "E:" .. eSlot
        bStage[bKey] = bStage[bKey] or {}
        return
    end
    if msg:match("^ICITEM:") then bKey = nil return end  -- B: buckets not needed
    local sp, tr = msg:match("^ICIPROC:(%d+):(%d+)")
    if sp then
        if bStage and bKey then
            local b = bStage[bKey]
            b[#b + 1] = { spell = tonumber(sp), trigger = tonumber(tr) }
        end
        return
    end
    if msg:match("^ICINVEND") then
        if bStage then
            buckets = bStage
            bStage, bKey = nil, nil
            haveData = true
            Paint()
        end
        return
    end
    -- ICEXI dialect: native procs per item entry (worn rows only matter here).
    local entry, eq, xsp, xtr = msg:match("^ICEXI:%-?%d+:%-?%d+:(%d+):(%d+):(%d+):(%d+)")
    if entry then
        if tonumber(eq) == 1 and tonumber(xsp) > 0 then
            nStage = nStage or {}
            local e = tonumber(entry)
            nStage[e] = nStage[e] or {}
            nStage[e][xsp .. ":" .. xtr] = true
        else
            nStage = nStage or {}
        end
        return
    end
    if msg:match("^ICEXIEND") then
        if nStage then
            nativeByEntry = nStage
            nStage = nil
            haveData = true
            Paint()
        end
        return
    end
end

-- ---- events -----------------------------------------------------------------
local loginTimer = CreateFrame("Frame")
loginTimer:Hide()
local elapsed = 0
loginTimer:SetScript("OnUpdate", function(self, e)
    elapsed = elapsed + e
    if elapsed >= 5 then self:Hide(); request() end
end)

local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_ADDON")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("UNIT_INVENTORY_CHANGED")
f:SetScript("OnEvent", function(_, event, arg1, arg2, arg3, arg4)
    if event == "CHAT_MSG_ADDON" then
        if arg1 == "UNC" and arg4 == ME then onWire(arg2) end
    elseif event == "UNIT_INVENTORY_CHANGED" then
        if arg1 == "player" then Paint() end
    elseif event == "PLAYER_ENTERING_WORLD" then
        elapsed = 0
        loginTimer:Show()  -- request 5 s after landing, past the loading edge
        Paint()
    end
end)

if CharacterFrame and CharacterFrame.HookScript then
    CharacterFrame:HookScript("OnShow", function()
        request()
        Paint()
    end)
end
