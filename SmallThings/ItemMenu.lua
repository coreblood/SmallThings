--[[ SmallThings — Alt+Right-click item menu
     Small cursor-anchored menu on bag items: Equip / Stash to Vault / Split.

     Trigger: Alt+Right-click. Plain right-click keeps its default use/equip
     behavior; shift stays chat-link/split, ctrl stays dressing room. With alt
     held, IsModifiedClick() is true, so the default UI routes the click into
     ContainerFrameItemButton_OnModifiedClick and does NOT use the item —
     which is exactly where we hook.

     Every action operates on the exact (bag, slot) of the clicked button.
     Never match items by link: kirei's own vault bug #1318 (link matching
     banked the wrong copy) is the cautionary tale.

     Stash: eligibility is entirely server-side. We send VLTDEP and rely on
     the server pack's UncappedVault to print any VLTDEPFAIL reason and to
     sync its window from the pushed VLTUPD. One message, done.

     3.3.5a: the dropdown frame is created lazily on first use — never
     initialize dropdowns at file scope (load-time crash). ]]

local ADDON, ns = ...

local TRANSPORT = "REAGENTBANK"

local menuFrame -- created on first use

local function ShowMenu(button, bag, slot)
    local link = GetContainerItemLink(bag, slot)
    if not link then return end

    local name, _, quality, _, _, _, _, maxStack = GetItemInfo(link)
    local _, itemCount = GetContainerItemInfo(bag, slot)

    local color = quality and ITEM_QUALITY_COLORS[quality]
    local title = (color and color.hex or "") .. (name or "Item") .. "|r"

    local menu = {
        { text = title, isTitle = true, notCheckable = true },
    }

    if IsEquippableItem(link) then
        menu[#menu + 1] = {
            text = "Equip", notCheckable = true,
            -- The menu click is a hardware event, which buys the one
            -- protected call UseContainerItem needs. Gear does not cast a
            -- spell on use, so the on-use taint block does not apply here.
            func = function() UseContainerItem(bag, slot) end,
        }
    end

    menu[#menu + 1] = {
        text = "Stash to Vault", notCheckable = true,
        func = function()
            SendAddonMessage(TRANSPORT,
                             string.format("VLTDEP:%d:%d", bag, slot),
                             "WHISPER", UnitName("player"))
        end,
    }

    if (itemCount or 0) > 1 and (maxStack or 1) > 1 then
        menu[#menu + 1] = {
            text = "Split", notCheckable = true,
            func = function()
                -- Same path as shift-click: the default stack-split frame,
                -- whose accept calls the button's own SplitStack handler.
                OpenStackSplitFrame(itemCount, button, "BOTTOMLEFT", "TOPLEFT")
            end,
        }
    end

    if not menuFrame then
        menuFrame = CreateFrame("Frame", "SmallThingsItemMenu", UIParent,
                                "UIDropDownMenuTemplate")
    end
    EasyMenu(menu, menuFrame, "cursor", 0, 0, "MENU", 3)
end

hooksecurefunc("ContainerFrameItemButton_OnModifiedClick", function(self, mouse)
    if not (ns.db and ns.db.itemMenu) then return end
    if mouse ~= "RightButton" then return end
    if not IsAltKeyDown() or IsShiftKeyDown() or IsControlKeyDown() then return end
    ShowMenu(self, self:GetParent():GetID(), self:GetID())
end)
