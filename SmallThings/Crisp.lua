--[[ SmallThings — Crisp graphics
     One tick applies a CVar preset that pushes the 3.3.5a client past its
     video sliders: view distance, ground clutter, cloud/weather detail and
     8x multisampling.

     Ticking SAVES whatever values you had first (into SmallThingsDB), so
     unticking restores YOUR previous settings, not generic defaults — with
     stock client values as the fallback if the saved set is ever missing.

     gxmultisample only takes effect after a graphics restart; we deliberately
     do NOT force /console gxrestart on a checkbox click (screen-blanking
     surprise). It kicks in at the next login instead — documented in the
     manual. Everything else applies instantly. ]]

local ADDON, ns = ...

local CRISP = {
    farclip             = "1277",
    groundeffectdensity = "256",
    groundeffectdist    = "140",
    detaildoodadalpha   = "100",
    skycloudlod         = "3",
    weatherdensity      = "3",
    gxmultisample       = "8",
}

-- stock 3.3.5a values, used only if the saved set is missing
local STOCK = {
    farclip             = "777",
    groundeffectdensity = "64",
    groundeffectdist    = "70",
    detaildoodadalpha   = "100",
    skycloudlod         = "2",
    weatherdensity      = "2",
    gxmultisample       = "1",
}

-- pcall guards: an unknown CVar on this client build must never abort the
-- whole preset (v1.3.0 shipped horizonfarclip, which 3.3.5a doesn't have —
-- SetCVar hard-errored and everything after it in the loop was skipped).
local function safeGet(k)
    local ok, v = pcall(GetCVar, k)
    if ok then return v end
end

local function safeSet(k, v)
    pcall(SetCVar, k, v)
end

function ns.ApplyCrisp()
    if not ns.db then return end
    if ns.db.crispGraphics then
        if not ns.db.crispSaved then
            local saved = {}
            for k in pairs(CRISP) do saved[k] = safeGet(k) end
            ns.db.crispSaved = saved
        end
        for k, v in pairs(CRISP) do safeSet(k, v) end
    elseif ns.db.crispSaved then
        -- only touch CVars on untick if we were the ones who changed them
        for k in pairs(CRISP) do
            safeSet(k, ns.db.crispSaved[k] or STOCK[k])
        end
        ns.db.crispSaved = nil
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    if ns.db and ns.db.crispGraphics then ns.ApplyCrisp() end
end)
