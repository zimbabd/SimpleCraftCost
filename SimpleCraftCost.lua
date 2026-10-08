-- Blizzard_TradeSkillUI is a TOC dependency, so TradeSkillFrame exists here.
local COST_OFFSET_X = -210 -- Negative moves left; positive moves right.
local COST_OFFSET_Y = 70 -- Positive moves up; negative moves down.
local COST_FONT_SIZE = 14 -- Increase or decrease the cost label font size.

SimpleCraftCostDB = SimpleCraftCostDB or {}

local costPanel = CreateFrame("Frame", nil, UIParent)
costPanel:SetFrameStrata("DIALOG")
costPanel:SetSize(340, 32)
costPanel:SetMovable(true)
costPanel:EnableMouse(true)
costPanel:RegisterForDrag("LeftButton")
costPanel:SetClampedToScreen(true)

if SimpleCraftCostDB.x and SimpleCraftCostDB.y then
    costPanel:SetPoint("CENTER", UIParent, "BOTTOMLEFT", SimpleCraftCostDB.x, SimpleCraftCostDB.y)
else
    costPanel:SetPoint("BOTTOMRIGHT", TradeSkillFrame, "BOTTOMRIGHT", COST_OFFSET_X, COST_OFFSET_Y)
end
costPanel:Hide()

costPanel:SetScript("OnDragStart", function(self)
    if IsControlKeyDown() then
        self:StartMoving()
    end
end)

costPanel:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local x, y = self:GetCenter()
    if x and y then
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
        SimpleCraftCostDB.x = x
        SimpleCraftCostDB.y = y
    end
end)

local costText = costPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
local fontPath, _, fontFlags = costText:GetFont()
local savedFontSize = tonumber(SimpleCraftCostDB.fontSize)
local currentFontSize = savedFontSize and savedFontSize >= 8 and savedFontSize <= 32
    and savedFontSize or COST_FONT_SIZE
costText:SetFont(fontPath, currentFontSize, fontFlags)
costText:SetPoint("RIGHT", costPanel, "RIGHT", -4, 0)
costText:SetWidth(332)
costText:SetJustifyH("RIGHT")
costText:SetText("")

SLASH_SIMPLECRAFTCOSTFONT1 = "/sccfont"
SlashCmdList["SIMPLECRAFTCOSTFONT"] = function(message)
    local requestedSize = tonumber(message)
    if not requestedSize then
        print("SimpleCraftCost font size: " .. currentFontSize .. ". Usage: /sccfont 8-32")
        return
    end

    requestedSize = math.floor(requestedSize + 0.5)
    if requestedSize < 8 or requestedSize > 32 then
        print("SimpleCraftCost font size must be between 8 and 32.")
        return
    end

    currentFontSize = requestedSize
    SimpleCraftCostDB.fontSize = currentFontSize
    costText:SetFont(fontPath, currentFontSize, fontFlags)
    print("SimpleCraftCost font size set to " .. currentFontSize .. ".")
end

local debugEnabled = false
local lastDebugMessage

local function Debug(message)
    if debugEnabled and message ~= lastDebugMessage then
        print("|cff66ccffSimpleCraftCost:|r " .. message)
        lastDebugMessage = message
    end
end

-- Format copper as gold, silver, and copper.
local function FormatMoney(copper)
    if not copper or copper <= 0 then return "N/A" end
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local cop = copper % 100
    
    local str = ""
    if gold > 0 then str = str .. gold .. "g " end
    if silver > 0 or gold > 0 then str = str .. silver .. "s " end
    str = str .. cop .. "c"
    return str
end

-- Calculate the material cost of the selected recipe.
local function UpdateCraftCost()
    if not TradeSkillFrame or not TradeSkillFrame:IsShown() then
        costPanel:Hide()
        costText:SetText("")
        Debug("trade skill window is hidden")
        return
    end
    costPanel:Show()

    local selectionIndex = GetTradeSkillSelectionIndex()
    if not selectionIndex or selectionIndex == 0 then
        costText:SetText("|cffffd200SimpleCraftCost:|r Select a recipe")
        Debug("trade skill window is open, but no recipe is selected")
        return
    end

    local numReagents = GetTradeSkillNumReagents(selectionIndex)
    if not numReagents or numReagents == 0 then
        costText:SetText("|cffffd200Cost:|r Recipe has no reagents")
        Debug("recipe=" .. selectionIndex .. ", no reagents")
        return
    end

    local totalCost = 0
    local missingPrice = false
    local debugReagents = {}

    for i = 1, numReagents do
        local reagentName, _, reagentCount = GetTradeSkillReagentInfo(selectionIndex, i)
        local reagentLink = GetTradeSkillReagentItemLink(selectionIndex, i)

        -- The legacy Auctionator API is optional on 3.3.5 clients.
        local price = 0
        local priceStatus = "API unavailable"
        if reagentCount and Atr_GetAuctionBuyout then
            priceStatus = "item unavailable"
            local item = reagentLink
            if not item and reagentName and reagentName ~= "" then
                item = reagentName
            end

            if item then
                local ok, auctionPrice = pcall(Atr_GetAuctionBuyout, item)
                if ok then
                    price = tonumber(auctionPrice) or 0
                    priceStatus = price > 0 and "price found" or "no price"
                else
                    priceStatus = "API error: " .. tostring(auctionPrice)
                end
            end

            if price <= 0 and reagentName and reagentName ~= "" and reagentName ~= item then
                local ok, auctionPrice = pcall(Atr_GetAuctionBuyout, reagentName)
                if ok then
                    price = tonumber(auctionPrice) or 0
                    priceStatus = price > 0 and "price found by name" or priceStatus
                else
                    priceStatus = "API error: " .. tostring(auctionPrice)
                end
            end
        end

        debugReagents[#debugReagents + 1] = tostring(reagentName or "?")
            .. " x" .. tostring(reagentCount or "?")
            .. " [link=" .. (reagentLink and "yes" or "no")
            .. ", price=" .. tostring(price)
            .. ", " .. priceStatus .. "]"

        if price > 0 and reagentCount then
            totalCost = totalCost + (price * reagentCount)
        else
            missingPrice = true
        end
    end

    if totalCost > 0 then
        local text = "|cffffd200Crafting cost:|r " .. FormatMoney(totalCost)
        if missingPrice then
            text = text .. " |cff808080(missing prices for some reagents)|r"
        end
        costText:SetText(text)
    else
        costText:SetText("|cffffd200Crafting cost:|r |cff808080No Auctionator prices (scan the auction house)|r")
    end

    Debug("recipe=" .. selectionIndex
        .. ", reagents=" .. numReagents
        .. ", total=" .. FormatMoney(totalCost)
        .. ", Auctionator=" .. (Atr_GetAuctionBuyout and "available" or "not found")
        .. ": " .. table.concat(debugReagents, "; "))
end

SLASH_SIMPLECRAFTCOSTDEBUG1 = "/sccdebug"
SlashCmdList["SIMPLECRAFTCOSTDEBUG"] = function()
    debugEnabled = not debugEnabled
    lastDebugMessage = nil
    print("SimpleCraftCost debug " .. (debugEnabled and "enabled" or "disabled"))
    if debugEnabled then
        UpdateCraftCost()
    end
end

SLASH_SIMPLECRAFTCOSTRESET1 = "/sccreset"
SlashCmdList["SIMPLECRAFTCOSTRESET"] = function()
    SimpleCraftCostDB.x = nil
    SimpleCraftCostDB.y = nil
    costPanel:ClearAllPoints()
    costPanel:SetPoint("BOTTOMRIGHT", TradeSkillFrame, "BOTTOMRIGHT", COST_OFFSET_X, COST_OFFSET_Y)
    print("SimpleCraftCost position reset. The default position will be used.")
end

SLASH_SIMPLECRAFTCOST1 = "/scc"
SlashCmdList["SIMPLECRAFTCOST"] = function(message)
    local command = string.lower(message or "")
    if command == "" or command == "help" then
        print("SimpleCraftCost commands:")
        print("/sccfont [8-32] - Set or show the cost label font size.")
        print("/sccdebug - Toggle debug output.")
        print("/sccreset - Reset the cost label position.")
        print("Hold Ctrl and left-drag the cost label to move it.")
    else
        print("Unknown SimpleCraftCost command. Type /scc help for the command list.")
    end
end

-- Refresh the cost when the trade skill UI updates.
hooksecurefunc("TradeSkillFrame_SetSelection", UpdateCraftCost)
hooksecurefunc("TradeSkillFrame_Update", UpdateCraftCost)

local events = CreateFrame("Frame")
events:RegisterEvent("TRADE_SKILL_SHOW")
events:RegisterEvent("TRADE_SKILL_UPDATE")
events:RegisterEvent("TRADE_SKILL_CLOSE")
events:SetScript("OnEvent", UpdateCraftCost)