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

-- ---------------------------------------------------------------------------
-- Quest info on quest items: for any bag item that matches a CURRENT quest-
-- log objective ("Boar Tusk: 4/10"), the tooltip gains the quest's name,
-- progress, and the zone the quest log files it under. Log-based, so custom
-- server quests work automatically; items for quests not (or no longer) in
-- the log have no data source and are left alone.
-- ---------------------------------------------------------------------------
local questItems = {}   -- lower(item name) -> { quest, zone, prog }
local logQuests = {}    -- { quest, zone, hay = lower(title + objective texts) }
local qiDirty = true
local qiScanning = false

local function RebuildQuestItems()
    qiScanning = true
    wipe(questItems)
    wipe(logQuests)
    -- collapsed headers hide their quests from the log API: expand, scan,
    -- then re-collapse exactly the headers that were collapsed (by name)
    local collapsed = {}
    for i = 1, GetNumQuestLogEntries() do
        local title, _, _, _, isHeader, isCollapsed = GetQuestLogTitle(i)
        if isHeader and isCollapsed then collapsed[title] = true end
    end
    if next(collapsed) then ExpandQuestHeader(0) end
    local zone = UNKNOWN or "?"
    for i = 1, GetNumQuestLogEntries() do
        local title, _, _, _, isHeader = GetQuestLogTitle(i)
        if isHeader then
            zone = title
        elseif title then
            local hay = title:lower()
            for o = 1, GetNumQuestLeaderBoards(i) do
                local text, otype = GetQuestLogLeaderBoard(o, i)
                if otype == "item" and text then
                    local name, prog = text:match("^(.-):%s*(%d+%s*/%s*%d+)%s*$")
                    if name then
                        questItems[name:lower()] =
                            { quest = title, zone = zone, prog = prog }
                    end
                end
                if text then hay = hay .. "\n" .. text:lower() end
            end
            logQuests[#logQuests + 1] = { quest = title, zone = zone, hay = hay }
        end
    end
    if next(collapsed) then
        -- indices shifted after the expand; walk headers and re-collapse by name
        for i = GetNumQuestLogEntries(), 1, -1 do
            local title, _, _, _, isHeader = GetQuestLogTitle(i)
            if isHeader and collapsed[title] then CollapseQuestHeader(i) end
        end
    end
    qiDirty = false
    qiScanning = false
end

local function OnQuestItem(tt)
    if not (ns.db and ns.db.questTooltip) or tt.SmallThingsQuest then return end
    local name, link = tt:GetItem()
    if not name then return end
    if qiDirty then RebuildQuestItems() end
    local q = questItems[name:lower()]
    if not q then
        -- 2nd pass: delivery/find quests track no "item" objective, but the
        -- bag item is flagged Quest Item and its name appears verbatim in the
        -- quest's title or freeform objective text. Quest Items only, so
        -- ordinary items can't false-match. No progress line (there is none).
        local itemType = link and select(6, GetItemInfo(link))
        if itemType == "Quest" then
            local needle = name:lower()
            for _, lq in ipairs(logQuests) do
                if lq.hay:find(needle, 1, true) then
                    q = { quest = lq.quest, zone = lq.zone }
                    break
                end
            end
        end
    end
    if not q then return end
    tt.SmallThingsQuest = true
    tt:AddDoubleLine("Quest: " .. q.quest, q.prog or "", 1, 0.82, 0, 1, 1, 1)
    tt:AddLine("Area: " .. q.zone, 0.6, 0.6, 1)
    tt:Show()
end

for _, tt in ipairs({ GameTooltip, ItemRefTooltip }) do
    tt:HookScript("OnTooltipSetItem", OnQuestItem)
    tt:HookScript("OnTooltipCleared", function(t) t.SmallThingsQuest = nil end)
end

local qiEv = CreateFrame("Frame")
qiEv:RegisterEvent("QUEST_LOG_UPDATE")
qiEv:SetScript("OnEvent", function()
    if not qiScanning then qiDirty = true end
end)
