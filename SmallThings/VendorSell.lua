--[[ SmallThings — Auto-sell greys / whites
     On MERCHANT_SHOW, sells every grey (quality 0) and, if the aggressive
     option is on, every white (quality 1) item that has a sell price.

     The sell-price guard doubles as the safety net: quest items, the
     hearthstone and other unsellables all report price 0 and are skipped
     automatically, as are locked slots. Prints ONE pooled summary line per
     vendor visit, only when something was actually sold — a deliberate,
     documented exception to the no-chat-output rule so the aggressive whites
     mode is never silent about what it just did. ]]

local ADDON, ns = ...

local function SellPass()
    if not ns.db then return end
    local greys, whites = ns.db.sellGreys, ns.db.sellWhites
    if not (greys or whites) then return end

    local total, count = 0, 0
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot)
            if link then
                local _, _, quality, _, _, _, _, _, _, _, price = GetItemInfo(link)
                local _, itemCount, locked = GetContainerItemInfo(bag, slot)
                if not locked and price and price > 0 then
                    if (quality == 0 and greys) or (quality == 1 and whites) then
                        UseContainerItem(bag, slot) -- at a merchant this sells
                        total = total + price * (itemCount or 1)
                        count = count + 1
                    end
                end
            end
        end
    end

    if count > 0 then
        local money = GetCoinTextureString and GetCoinTextureString(total)
                      or string.format("%.2fg", total / 10000)
        DEFAULT_CHAT_FRAME:AddMessage(string.format(
            "|cff7fd5ffSmallThings|r sold %d item%s for %s.",
            count, count == 1 and "" or "s", money))
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("MERCHANT_SHOW")
f:SetScript("OnEvent", SellPass)
