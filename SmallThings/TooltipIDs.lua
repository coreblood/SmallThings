--[[ SmallThings — Tooltip IDs (absorbed from standalone IDTip v1.0.0)
     Adds Item / Enchant / Spell / Talent ID lines to tooltips, plus aura
     spell IDs on buffs and debuffs. One master toggle; hooks stay installed
     (they cannot be removed) and simply no-op while the option is off. ]]

local ADDON, ns = ...

local function on() return ns.db and ns.db.tooltipIDs end

local function AddID(tt, label, id)
    if not id then return end
    tt:AddDoubleLine(label, tostring(id), 0.5, 0.8, 1.0, 1, 1, 1)
    tt:Show() -- re-measure so the new line is not clipped
end

-- ------------------------------------------------------------ items + spells

-- OnTooltipSetItem can fire twice for the same tooltip (recipes are the
-- classic case), so each tooltip carries a per-fill flag cleared on
-- OnTooltipCleared.
local function OnItem(tt)
    if not on() or tt.SmallThingsItem then return end
    local _, link = tt:GetItem()
    if not link then return end
    local id, ench = string.match(link, "item:(%d+):(%-?%d+)")
    if not id then return end
    tt.SmallThingsItem = true
    AddID(tt, "Item ID", id)
    if ench and ench ~= "0" then
        AddID(tt, "Enchant ID", ench)
    end
end

local function OnSpell(tt)
    if not on() or tt.SmallThingsSpell then return end
    local _, _, id = tt:GetSpell() -- 3.3.5: name, rank, id
    if id then
        tt.SmallThingsSpell = true
        AddID(tt, "Spell ID", id)
    end
end

local function OnCleared(tt)
    tt.SmallThingsItem = nil
    tt.SmallThingsSpell = nil
end

for _, tt in ipairs({ GameTooltip, ItemRefTooltip }) do
    tt:HookScript("OnTooltipSetItem", OnItem)
    tt:HookScript("OnTooltipSetSpell", OnSpell)
    tt:HookScript("OnTooltipCleared", OnCleared)
end

-- ------------------------------------------------------------------- auras

-- Aura tooltips do not pass through OnTooltipSetSpell on 3.3.5, so hook the
-- setters. spellId is the 11th return of UnitAura/UnitBuff/UnitDebuff (3.3.0+).
hooksecurefunc(GameTooltip, "SetUnitAura", function(tt, unit, index, filter)
    if on() then AddID(tt, "Spell ID", select(11, UnitAura(unit, index, filter))) end
end)
hooksecurefunc(GameTooltip, "SetUnitBuff", function(tt, unit, index, filter)
    if on() then AddID(tt, "Spell ID", select(11, UnitBuff(unit, index, filter))) end
end)
hooksecurefunc(GameTooltip, "SetUnitDebuff", function(tt, unit, index, filter)
    if on() then AddID(tt, "Spell ID", select(11, UnitDebuff(unit, index, filter))) end
end)

-- ------------------------------------------------------------------ talents

hooksecurefunc(GameTooltip, "SetTalent", function(tt, tab, index)
    if not on() then return end
    local link = GetTalentLink(tab, index)
    if link then
        AddID(tt, "Talent ID", string.match(link, "talent:(%d+)"))
    end
end)
