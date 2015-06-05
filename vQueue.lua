local chatRate = 3 -- limit to 3 msg/sec
local startTime = 0 -- used to get elapsed in onupdate
local channelName = "vQueue"
local filterEnabled = false -- chat filter

local isHost = false
local isFinding = false
local hostedCategory = ""
local playersQueued = {}
local chatQueue = {}
local hostWhisperQueue = {}
local groups = {}
local requestWhisperQueue = {}

local vQueueFrame = {}
local catListButtons = {}
local vQueueFrameShown = false
local selectedQuery = ""
local selectedRole = ""

local categories = {}
local hostListButtons = {}
local hostListFrame
local infoFrame = {}
local catListHidden = {}

local tankSelected = false
local healerSelected = false
local damageSelected = false

local hostOptions = {}

vQueue = AceLibrary("AceAddon-2.0"):new("AceHook-2.1")

function addToSet(set, key)
    set[key] = true
end

function removeFromSet(set, key)
	set[key] = nil
end

function setContains(set, key)
    return set[key] ~= nil
end

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function round(num)
    under = math.floor(num)
    upper = math.floor(num) + 1
    underV = -(under - num)
    upperV = upper - num
    if (upperV > underV) then
        return under
    else
        return upper
    end
end

function split(pString, pPattern)
   local Table = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pPattern
   local last_end = 1
   local s, e, cap = string.find(pString, fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
		table.insert(Table,cap)
      end
      last_end = e+1
      s, e, cap = string.find(pString, fpat, last_end)
   end
   if last_end <= string.len(pString) then
      cap = string.sub(pString, last_end)
      table.insert(Table, cap)
   end
   return Table
end

function vQueue:OnInitialize()
	for i = NUM_CHAT_WINDOWS, 1, -1 do
		self:Hook(getglobal("ChatFrame"..i), "AddMessage")
	end
end

function vQueue:AddMessage(frame, text, r, g, b, id)
	if strfind(tostring(text), tostring(GetChannelName(channelName)) .. ".") and filterEnabled then
		blockMsg = false
	elseif text ~= nil then
		self.hooks[frame].AddMessage(frame, string.format("%s", text), r, g, b, id)
	end
end

function vQueue_OnLoad()
	this:RegisterEvent("ADDON_LOADED");
	this:RegisterEvent("CHAT_MSG_CHANNEL");
	this:RegisterEvent("CHAT_MSG_WHISPER");
end

function vQueue_OnEvent(event)
	if event == "ADDON_LOADED" and arg1 == "vQueue" then
	
		categories["Dungeons"] = 
		{
			expanded = false,
			"Ragefire Chasm:rfc",
			"The Deadmines:dead",
			"Wailing Caverns:wc",
			"Shadowfang Keep:sfk",
			"The Stockade:stock",
			"Blackfathom Deeps:bfd",
			"Gnomeregan:gnomer",
			"Razorfen Kraul:rfk",
			"The Graveyard:graveyard",
			"The Library:library",
			"The Armory:armory",
			"The Cathedral:cathedral",
			"Razorfen Downs:rfd",
			"Uldaman:ulda",
			"Zul'Farrak:zf",
			"Maraudon:mara",
			"The Sunken Temple:st",
			"Blackrock Depths:brd",
			"Lower Blackrock:lbrs",
			"Dire Maul:dm",
			"Stratholme:strat",
			"Scholomance:scholo"
		
		}
		categories["Raids"] =
		{
			expanded = false,
			"Upper Blackrock:ubrs",
			"Onyxia's Lair:ony",
			"Zul'Gurub:zg",
			"Molten Core:mc",
			"Ruins of Ahn'Qiraj:ruins",
			"Blackwing Lair:bwl",
			"Temple of Ahn'Qiraj:temple",
			"Naxxramas:naxx"
		}
		categories["Battlegrounds"] =
		{
			expanded = false,
			"Warsong Gulch:wsg",
			"Arathi Basin:ab",
			"Alterac Valley:av"
		
		}
		
		for k, v in pairs(categories) do
			for kk, vv in pairs(categories[k]) do
				if type(vv) == "string" then
					args = split(vv, "\:")
					if args[2] ~= nil then
						groups[args[2]] = {}
					end
				end
			end
		end
		
		playersQueued = 
		{

		}
		
		vQueueFrame = CreateFrame("Frame", UIParent)
		vQueueFrame:SetWidth(594)
		vQueueFrame:SetHeight(367)
		vQueueFrame:ClearAllPoints()
		vQueueFrame:SetPoint("CENTER", UIParent,"CENTER") 
		vQueueFrame:SetMovable(true)
		vQueueFrame:EnableMouse(true)
		--vQueueFrame:SetClampedToScreen(true)
		--vQueueFrame:RegisterForDrag("LeftButton")
		--vQueueFrame:SetScript("OnDragStart", vQueueFrame.StartMoving)
		--vQueueFrame:SetScript("OnDragStop", vQueueFrame.StopMovingOrSizing)
		--vQueueFrame:StartMoving()
		vQueueFrame:SetScript("OnMouseDown", function(self, button)
			vQueueFrame:StartMoving()
			vQueueFrame.hostlistNameField:ClearFocus()
			vQueueFrame.hostlistLevelField:ClearFocus()
			vQueueFrame.hostlistRoleText:SetText("")
		end)
		vQueueFrame:SetScript("OnMouseUp", function(self, button)
			vQueueFrame:StopMovingOrSizing()
		end)
		
		vQueueFrame.texture = vQueueFrame:CreateTexture(nil, "BACKGROUND")
		--vQueueFrame.texture:SetTexture("Interface\\AddOns\\CustomNameplates\\barSmall")
		--vQueueFrame.texture:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
		vQueueFrame.texture:SetVertexColor(0.2, 0.2, 0.2, 1)
		vQueueFrame.texture:ClearAllPoints()
		vQueueFrame.texture:SetPoint("CENTER", vQueueFrame, "CENTER")
		vQueueFrame.texture:SetWidth(vQueueFrame:GetWidth())
		vQueueFrame.texture:SetHeight(vQueueFrame:GetHeight())
		vQueueFrame.texture:SetTexture(48/255, 38/255, 28/255, 0.8)
		
		vQueueFrame.borderLeft = vQueueFrame:CreateTexture(nil, "BORDER")
		vQueueFrame.borderLeft:SetTexture("Interface\\AddOns\\vQueue\\ThinBorder-Left")
		vQueueFrame.borderLeft:ClearAllPoints()
		vQueueFrame.borderLeft:SetPoint("LEFT", vQueueFrame, "LEFT", -5, -0.5)
		vQueueFrame.borderLeft:SetWidth(20)
		vQueueFrame.borderLeft:SetHeight(vQueueFrame:GetHeight()-31)
		
		vQueueFrame.borderRight = vQueueFrame:CreateTexture(nil, "BORDER")
		vQueueFrame.borderRight:SetTexture("Interface\\AddOns\\vQueue\\ThinBorder-Right")
		vQueueFrame.borderRight:ClearAllPoints()
		vQueueFrame.borderRight:SetPoint("RIGHT", vQueueFrame, "RIGHT", 5, -0.5)
		vQueueFrame.borderRight:SetWidth(20)
		vQueueFrame.borderRight:SetHeight(vQueueFrame:GetHeight()-31)
		
		vQueueFrame.borderBot = vQueueFrame:CreateTexture(nil, "BORDER")
		vQueueFrame.borderBot:SetTexture("Interface\\AddOns\\vQueue\\ThinBorder-Bottom")
		vQueueFrame.borderBot:ClearAllPoints()
		vQueueFrame.borderBot:SetPoint("BOTTOM", vQueueFrame, "BOTTOM", -0.5, -5)
		vQueueFrame.borderBot:SetWidth(vQueueFrame:GetWidth()-31.5)
		vQueueFrame.borderBot:SetHeight(20)
		
		vQueueFrame.borderTop = vQueueFrame:CreateTexture(nil, "BORDER")
		vQueueFrame.borderTop:SetTexture("Interface\\AddOns\\vQueue\\ThinBorder-Top")
		vQueueFrame.borderTop:ClearAllPoints()
		vQueueFrame.borderTop:SetPoint("TOP", vQueueFrame, "TOP", 0, 4)
		vQueueFrame.borderTop:SetWidth(vQueueFrame:GetWidth()-30)
		vQueueFrame.borderTop:SetHeight(20)
		
		vQueueFrame.borderTopLeft = vQueueFrame:CreateTexture(nil, "BORDER")
		vQueueFrame.borderTopLeft:SetTexture("Interface\\AddOns\\vQueue\\ThinBorder-TopLeft")
		vQueueFrame.borderTopLeft:ClearAllPoints()
		vQueueFrame.borderTopLeft:SetVertexColor(1, 1, 1, 1)
		vQueueFrame.borderTopLeft:SetPoint("TOPLEFT", vQueueFrame, "TOPLEFT", -5, 4)
		vQueueFrame.borderTopLeft:SetWidth(20)
		vQueueFrame.borderTopLeft:SetHeight(20)
		
		vQueueFrame.borderTopRight = vQueueFrame:CreateTexture(nil, "BORDER")
		vQueueFrame.borderTopRight:SetTexture("Interface\\AddOns\\vQueue\\ThinBorder-TopRight")
		vQueueFrame.borderTopRight:ClearAllPoints()
		vQueueFrame.borderTopRight:SetVertexColor(1, 1, 1, 1)
		vQueueFrame.borderTopRight:SetPoint("TOPRIGHT", vQueueFrame, "TOPRIGHT", 5, 4)
		vQueueFrame.borderTopRight:SetWidth(20)
		vQueueFrame.borderTopRight:SetHeight(20)
		
		vQueueFrame.borderBottomLeft = vQueueFrame:CreateTexture(nil, "BORDER")
		vQueueFrame.borderBottomLeft:SetTexture("Interface\\AddOns\\vQueue\\ThinBorder-BottomLeft")
		vQueueFrame.borderBottomLeft:ClearAllPoints()
		vQueueFrame.borderBottomLeft:SetVertexColor(1, 1, 1, 1)
		vQueueFrame.borderBottomLeft:SetPoint("BOTTOMLEFT", vQueueFrame, "BOTTOMLEFT", -5, -5)
		vQueueFrame.borderBottomLeft:SetWidth(20)
		vQueueFrame.borderBottomLeft:SetHeight(20)
		
		vQueueFrame.borderBottomRight = vQueueFrame:CreateTexture(nil, "BORDER")
		vQueueFrame.borderBottomRight:SetTexture("Interface\\AddOns\\vQueue\\ThinBorder-BottomRight")
		vQueueFrame.borderBottomRight:ClearAllPoints()
		vQueueFrame.borderBottomRight:SetVertexColor(1, 1, 1, 1)
		vQueueFrame.borderBottomRight:SetPoint("BOTTOMRIGHT", vQueueFrame, "BOTTOMRIGHT", 3.75, -5)
		vQueueFrame.borderBottomRight:SetWidth(20)
		vQueueFrame.borderBottomRight:SetHeight(20)
		
		--vQueueFrame.scrollframe = CreateFrame("ScrollFrame", nil, vQueueFrame) 
		--vQueueFrame.scrollframe:SetPoint("LEFT", vQueueFrame, "LEFT", 5, -5) 
		--vQueueFrame.scrollframe:SetWidth((vQueueFrame:GetWidth()) * 1/5)
		--vQueueFrame.scrollframe:SetHeight((vQueueFrame:GetHeight()) - (vQueueFrame:GetHeight()*0.05))
		
		--vQueueFrame.scrollframebg = vQueueFrame.scrollframe:CreateTexture() 
		--vQueueFrame.scrollframebg:SetTexture(.5,.5,.5,.5) 
		--vQueueFrame.scrollframebg:SetAllPoints()
		
		vQueueFrame.catList = CreateFrame("ScrollFrame", vQueueFrame)
		vQueueFrame.catList:ClearAllPoints()
		vQueueFrame.catList:SetPoint("LEFT", vQueueFrame, "LEFT", 5, -5)
		vQueueFrame.catList:SetWidth(vQueueFrame:GetWidth() * 1/5)
		vQueueFrame.catList:SetHeight(vQueueFrame:GetHeight() - (vQueueFrame:GetHeight()*0.05))
		vQueueFrame.catList:EnableMouseWheel(true)
		--vQueueFrame.catList:SetFrameLevel(2)
		vQueueFrame.catList:SetScript("OnMouseWheel", function()
			if arg1 == 1 then
				scrollbarCat:SetValue(scrollbarCat:GetValue()-1)
			elseif arg1 == -1 then
				scrollbarCat:SetValue(scrollbarCat:GetValue()+1)
			end
		end)
		
		--vQueueFrame.scrollframe:SetScrollChild(vQueueFrame.catList)
		
		vQueueFrame.catListBg = vQueueFrame.catList:CreateTexture(nil, "BACKGROUND")
		--vQueueFrame.catListBg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
		vQueueFrame.catListBg:ClearAllPoints()
		vQueueFrame.catListBg:SetVertexColor(1, 1, 1, 1)
		vQueueFrame.catListBg:SetPoint("CENTER", vQueueFrame.catList, "CENTER")
		vQueueFrame.catListBg:SetWidth(vQueueFrame.catList:GetWidth())
		vQueueFrame.catListBg:SetHeight(vQueueFrame.catList:GetHeight())
		vQueueFrame.catListBg:SetTexture(11/255, 11/255, 11/255, 0.8)
		
		vQueueFrame.catListborderLeft = vQueueFrame.catList:CreateTexture(nil, "BORDER")
		vQueueFrame.catListborderLeft:SetTexture("Interface\\AddOns\\vQueue\\ThinBorder-Left")
		vQueueFrame.catListborderLeft:ClearAllPoints()
		vQueueFrame.catListborderLeft:SetPoint("LEFT", vQueueFrame.catList, "LEFT", -2, 0)
		vQueueFrame.catListborderLeft:SetWidth(10)
		vQueueFrame.catListborderLeft:SetHeight(vQueueFrame.catList:GetHeight()-13)
		
		vQueueFrame.catListborderRight = vQueueFrame.catList:CreateTexture(nil, "BORDER")
		vQueueFrame.catListborderRight:SetTexture("Interface\\AddOns\\vQueue\\ThinBorder-Right")
		vQueueFrame.catListborderRight:ClearAllPoints()
		vQueueFrame.catListborderRight:SetPoint("RIGHT", vQueueFrame.catList, "RIGHT", 3, 0)
		vQueueFrame.catListborderRight:SetWidth(10)
		vQueueFrame.catListborderRight:SetHeight(vQueueFrame.catList:GetHeight()-13)
		
		vQueueFrame.catListborderTop = vQueueFrame.catList:CreateTexture(nil, "BORDER")
		vQueueFrame.catListborderTop:SetTexture("Interface\\AddOns\\vQueue\\ThinBorder-Top")
		vQueueFrame.catListborderTop:ClearAllPoints()
		vQueueFrame.catListborderTop:SetPoint("TOP", vQueueFrame.catList, "TOP", 0, 2)
		vQueueFrame.catListborderTop:SetWidth(vQueueFrame.catList:GetWidth() - 13)
		vQueueFrame.catListborderTop:SetHeight(10)
		
		vQueueFrame.catListborderBot = vQueueFrame.catList:CreateTexture(nil, "BORDER")
		vQueueFrame.catListborderBot:SetTexture("Interface\\AddOns\\vQueue\\ThinBorder-Bottom")
		vQueueFrame.catListborderBot:ClearAllPoints()
		vQueueFrame.catListborderBot:SetPoint("BOTTOM", vQueueFrame.catList, "BOTTOM", 0, -2)
		vQueueFrame.catListborderBot:SetWidth(vQueueFrame.catList:GetWidth() - 13)
		vQueueFrame.catListborderBot:SetHeight(10)
		
		vQueueFrame.catListborderTopRight = vQueueFrame.catList:CreateTexture(nil, "BORDER")
		vQueueFrame.catListborderTopRight:SetTexture("Interface\\AddOns\\vQueue\\ThinBorder-TopRight")
		vQueueFrame.catListborderTopRight:ClearAllPoints()
		vQueueFrame.catListborderTopRight:SetPoint("TOPRIGHT", vQueueFrame.catList, "TOPRIGHT", 3, 2)
		vQueueFrame.catListborderTopRight:SetWidth(10)
		vQueueFrame.catListborderTopRight:SetHeight(10)
		
		vQueueFrame.catListborderTopLeft = vQueueFrame.catList:CreateTexture(nil, "BORDER")
		vQueueFrame.catListborderTopLeft:SetTexture("Interface\\AddOns\\vQueue\\ThinBorder-TopLeft")
		vQueueFrame.catListborderTopLeft:ClearAllPoints()
		vQueueFrame.catListborderTopLeft:SetPoint("TOPLEFT", vQueueFrame.catList, "TOPLEFT", -2, 2)
		vQueueFrame.catListborderTopLeft:SetWidth(10)
		vQueueFrame.catListborderTopLeft:SetHeight(10)
		
		vQueueFrame.catListborderBotRight = vQueueFrame.catList:CreateTexture(nil, "BORDER")
		vQueueFrame.catListborderBotRight:SetTexture("Interface\\AddOns\\vQueue\\ThinBorder-BottomRight")
		vQueueFrame.catListborderBotRight:ClearAllPoints()
		vQueueFrame.catListborderBotRight:SetPoint("BOTTOMRIGHT", vQueueFrame.catList, "BOTTOMRIGHT", 2.4, -2)
		vQueueFrame.catListborderBotRight:SetWidth(10)
		vQueueFrame.catListborderBotRight:SetHeight(10)
		
		vQueueFrame.catListborderBotLeft = vQueueFrame.catList:CreateTexture(nil, "BORDER")
		vQueueFrame.catListborderBotLeft:SetTexture("Interface\\AddOns\\vQueue\\ThinBorder-BottomLeft")
		vQueueFrame.catListborderBotLeft:ClearAllPoints()
		vQueueFrame.catListborderBotLeft:SetPoint("BOTTOMLEFT", vQueueFrame.catList, "BOTTOMLEFT", -2, -2)
		vQueueFrame.catListborderBotLeft:SetWidth(10)
		vQueueFrame.catListborderBotLeft:SetHeight(10)
		
		vQueueFrame.hostlist = CreateFrame("ScrollFrame", vQueueFrame)
		vQueueFrame.hostlist:ClearAllPoints()
		vQueueFrame.hostlist:SetPoint("RIGHT", vQueueFrame, "RIGHT", -5, -5)
		vQueueFrame.hostlist:SetWidth(vQueueFrame:GetWidth() - vQueueFrame.catList:GetWidth() - 15)
		vQueueFrame.hostlist:SetHeight(vQueueFrame:GetHeight() - (vQueueFrame:GetHeight()*0.05))
		vQueueFrame.hostlist:EnableMouseWheel(true)
		vQueueFrame.hostlist:SetScript("OnMouseWheel", function(self, delta)
			if arg1 == 1 then
				scrollbar:SetValue(scrollbar:GetValue()-1)
			elseif arg1 == -1 then
				scrollbar:SetValue(scrollbar:GetValue()+1)
			end
		end)
		vQueueFrame.hostlist:SetScript("OnShow", function(self, delta)
			for k, v in pairs(hostListButtons) do
				v:Hide()
			end
			hostListButtons = {}
			if isFinding then
				local colorr = 209/255
				local colorg = 164/255
				local colorb = 29/255
				for kk, vv in pairs(groups) do
					if selectedQuery == kk then
						for k, v in pairs(groups[kk]) do				
							local args = split(v, "\:")
							hostListButtons[tablelength(hostListButtons)] = CreateFrame("Button", "vQueueButton", vQueueFrame.hostlist)
							hostListButtons[tablelength(hostListButtons)-1]:SetFont("Fonts\\FRIZQT__.TTF", 10)
							hostListButtons[tablelength(hostListButtons)-1]:SetText(args[1])
							hostListButtons[tablelength(hostListButtons)-1]:SetTextColor(colorr, colorg, colorb)
							hostListButtons[tablelength(hostListButtons)-1]:SetHighlightTextColor(1, 1, 0)
							hostListButtons[tablelength(hostListButtons)-1]:SetPushedTextOffset(0,0)
							hostListButtons[tablelength(hostListButtons)-1]:SetWidth(hostListButtons[tablelength(hostListButtons)-1]:GetTextWidth())
							hostListButtons[tablelength(hostListButtons)-1]:SetHeight(10)
							hostListButtons[tablelength(hostListButtons)-1]:EnableMouse(false)
							hostListButtons[tablelength(hostListButtons)-1]:SetPoint("RIGHT", vQueueFrame.hostlist, "TOPLEFT",  round(hostListButtons[tablelength(hostListButtons)-1]:GetTextWidth()), -(tablelength(hostListButtons)*15)-10 - vQueueFrame.hostlistTopSection:GetHeight())
							hostListButtonBg = hostListButtons[tablelength(hostListButtons)-1]:CreateTexture(nil, "BACKGROUND")
							hostListButtonBg:SetPoint("LEFT", hostListButtons[tablelength(hostListButtons)-1], "LEFT")
							hostListButtonBg:SetWidth(vQueueFrame.hostlist:GetWidth())
							hostListButtonBg:SetHeight(hostListButtons[tablelength(hostListButtons)-1]:GetTextHeight()+5)
							if (math.mod(tablelength(hostListButtons)-1, 2) == 0) then
								hostListButtonBg:SetTexture(0.5, 0.5, 0.5, 0.1)
							else
								hostListButtonBg:SetTexture(0.2, 0.2, 0.2, 0.1)
							end
							
							for i, item in pairs(args) do
								local colorr = 247/255
								local colorg = 235/255
								local colorb = 233/255
								if (item ~= hostListButtons[tablelength(hostListButtons)-1]:GetText()) then
									if type(tonumber(item)) == "number" then
										local playerLevel = UnitLevel("player")
										local levelKey = tonumber(item)
										if (levelKey - playerLevel) >= 5 then
											colorr = 1
											colorg = 0
											colorb = 0
										elseif  (levelKey - playerLevel) <= 4  and (levelKey - playerLevel) >= 3 then
											colorr = 1
											colorg = 0.5
											colorb = 0
										elseif  (playerLevel - levelKey) <= 4  and (playerLevel - levelKey) >= 3 then
											colorr = 0
											colorg = 1
											colorb = 0
										elseif  (playerLevel - levelKey) > 4 then
											colorr = 0.5
											colorg = 0.5
											colorb = 0.5
										else
											colorr = 1
											colorg = 1
											colorb = 0
										end
									end
									if string.sub(item, 1, 4) ~= "Role" then
										infoFrame[tablelength(infoFrame)] = CreateFrame("Button", "vQueueInfoButton", hostListButtons[tablelength(hostListButtons)-1])
										infoFrame[tablelength(infoFrame)-1]:SetFont("Fonts\\FRIZQT__.TTF", 10)
										infoFrame[tablelength(infoFrame)-1]:SetText(item)
										infoFrame[tablelength(infoFrame)-1]:SetTextColor(colorr, colorg, colorb)
										infoFrame[tablelength(infoFrame)-1]:SetHighlightTextColor(1, 1, 0)
										infoFrame[tablelength(infoFrame)-1]:SetPushedTextOffset(0,0)
										infoFrame[tablelength(infoFrame)-1]:SetWidth(infoFrame[tablelength(infoFrame)-1]:GetTextWidth())
										infoFrame[tablelength(infoFrame)-1]:SetHeight(10)
										infoFrame[tablelength(infoFrame)-1]:EnableMouse(false)
										local point, relativeTo, relativePoint, xOffset, yOffset = hostListButtons[tablelength(hostListButtons)-1]:GetPoint(1)
										infoFrame[tablelength(infoFrame)-1]:SetPoint("LEFT", vQueueFrame.hostlist, "TOPLEFT", ((vQueueFrame.hostlist:GetWidth() * 4/5 )/(tablelength(args)-1))*(i-1), yOffset)
									else
										local roleArgs = split(item, "\%s")
										for ii, j in pairs(roleArgs) do
											infoFrame[tablelength(infoFrame)] = CreateFrame("Button", "vQueueInfoButton", hostListButtons[tablelength(hostListButtons)-1])
											infoFrame[tablelength(infoFrame)-1]:SetWidth(16)
											infoFrame[tablelength(infoFrame)-1]:SetHeight(16)
											infoFrame[tablelength(infoFrame)-1]:EnableMouse(false)
											infoFrame[tablelength(infoFrame)-1]:SetFrameLevel(1)
											local point, relativeTo, relativePoint, xOffset, yOffset = hostListButtons[tablelength(hostListButtons)-1]:GetPoint(1)
											infoFrame[tablelength(infoFrame)-1]:SetPoint("LEFT", vQueueFrame.hostlist, "TOPLEFT", ((vQueueFrame.hostlist:GetWidth() * 4/5 )/(tablelength(args)-1))*(i-1) - (ii*16), yOffset)
											local infoFrameIcon = infoFrame[tablelength(infoFrame)-1]:CreateTexture(nil, "ARTWORK")
											infoFrameIcon:SetAllPoints()
											infoFrameIcon:SetTexture("Interface\\AddOns\\vQueue\\" .. j)
											infoFrameIcon:SetWidth(infoFrame[tablelength(infoFrame)-1]:GetWidth())
											infoFrameIcon:SetHeight(infoFrame[tablelength(infoFrame)-1]:GetHeight())
										end
									end
								end
							end
							local point, relativeTo, relativePoint, xOffset, yOffset = hostListButtons[tablelength(hostListButtons)-1]:GetPoint(1)
							vQueueFrame.hostlistInviteButton = CreateFrame("Button", nil, hostListButtons[tablelength(hostListButtons)-1], "UIPanelButtonTemplate")
							vQueueFrame.hostlistInviteButton:SetPoint("RIGHT", vQueueFrame.hostlist, "TOPLEFT", vQueueFrame.hostlist:GetWidth(), yOffset)
							vQueueFrame.hostlistInviteButton:SetFont("Fonts\\FRIZQT__.TTF", 8)
							vQueueFrame.hostlistInviteButton:SetText("wait list")
							vQueueFrame.hostlistInviteButton:SetTextColor(0.85, 0.85, 0)
							vQueueFrame.hostlistInviteButton:SetWidth(vQueueFrame.hostlistInviteButton:GetTextWidth()+5)
							vQueueFrame.hostlistInviteButton:SetHeight(vQueueFrame.hostlistInviteButton:GetTextHeight()+3)
							vQueueFrame.hostlistInviteButton:SetScript("OnMouseDown", function()
								if this:GetText() == "wait list" then
									this:SetText("waiting")
									local childs = this:GetParent():GetChildren()
									vQueue_SlashCommandHandler("request " .. childs:GetText())
								end
							end)
							vQueueFrame.hostlistInviteButton:SetScript("OnUpdate", function()
								local tpoint, trelativeTo, trelativePoint, txOffset, yOffset = this:GetParent():GetPoint(1)
								local point, relativeTo, relativePoint, xOffset = this:GetPoint(1)
								this:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
							end)
							
							scrollbar:SetMinMaxValues(1, tablelength(hostListButtons)-5)
							scrollbar:SetValue(2)
							scrollbar:SetValue(1)
						end
					end
					
				end
			end
			
			if isHost then
				vQueueFrame.hostTitle:Show()
				local colorr = 247/255
				local colorg = 235/255
				local colorb = 233/255
				local classColor = {}
				classColor["Druid"] = {1, 0.49, 0.4}
				classColor["Hunter"] = {0.67, 0.83, 0.45}
				classColor["Mage"] = {0.41, 0.80, 0.94}
				classColor["Paladin"] = {0.96, 0.55, 0.73}
				classColor["Priest"] = {1, 1, 1}
				classColor["Rogue"] = {1, 0.96, 0.41}
				classColor["Shaman"] = {0, 0.44, 0.87}
				classColor["Warlock"] = {0.58, 0.51, 0.79}
				classColor["Warrior"] = {0.78, 0.61, 0.43}
				for k, v in pairs(playersQueued) do
					local args = split(k, "\:")
					hostListButtons[tablelength(hostListButtons)] = CreateFrame("Button", "vQueueButton", vQueueFrame.hostlist)
					hostListButtons[tablelength(hostListButtons)-1]:SetFont("Fonts\\FRIZQT__.TTF", 10)
					hostListButtons[tablelength(hostListButtons)-1]:SetText(args[1])
					hostListButtons[tablelength(hostListButtons)-1]:SetTextColor(colorr, colorg, colorb)
					hostListButtons[tablelength(hostListButtons)-1]:SetHighlightTextColor(1, 1, 0)
					hostListButtons[tablelength(hostListButtons)-1]:SetPushedTextOffset(0,0)
					hostListButtons[tablelength(hostListButtons)-1]:SetWidth(hostListButtons[tablelength(hostListButtons)-1]:GetTextWidth())
					hostListButtons[tablelength(hostListButtons)-1]:SetHeight(10)
					hostListButtons[tablelength(hostListButtons)-1]:EnableMouse(false)
					hostListButtons[tablelength(hostListButtons)-1]:SetPoint("RIGHT", vQueueFrame.hostlist, "TOPLEFT",  round(hostListButtons[tablelength(hostListButtons)-1]:GetTextWidth()), -(tablelength(hostListButtons)*15)-10 - vQueueFrame.hostlistTopSection:GetHeight())
					hostListButtonBg = hostListButtons[tablelength(hostListButtons)-1]:CreateTexture(nil, "BACKGROUND")
					hostListButtonBg:SetPoint("LEFT", hostListButtons[tablelength(hostListButtons)-1], "LEFT")
					hostListButtonBg:SetWidth(vQueueFrame.hostlist:GetWidth())
					hostListButtonBg:SetHeight(hostListButtons[tablelength(hostListButtons)-1]:GetTextHeight()+5)
					if (math.mod(tablelength(hostListButtons)-1, 2) == 0) then
						hostListButtonBg:SetTexture(0.5, 0.5, 0.5, 0.1)
					else
						hostListButtonBg:SetTexture(0.2, 0.2, 0.2, 0.1)
					end
					--hostListButtons[tablelength(hostListButtons)-1]:SetPoint("RIGHT", vQueueFrame.hostlist, "TOPLEFT",  round(hostListButtons[tablelength(hostListButtons)-1]:GetTextWidth()), -(tablelength(hostListButtons)*10) - 20)
					for i, item in pairs(args) do
						local colorr = 247/255
						local colorg = 235/255
						local colorb = 233/255
						if (item ~= hostListButtons[tablelength(hostListButtons)-1]:GetText()) then
							for key, value in pairs(classColor) do
								if key == item then
									colorr = classColor[key][1]
									colorg = classColor[key][2]
									colorb = classColor[key][3]
								end
							end
							if type(tonumber(item)) == "number" then
								local playerLevel = UnitLevel("player")
								local levelKey = tonumber(item)
								if (levelKey - playerLevel) >= 5 then
									colorr = 1
									colorg = 0
									colorb = 0
								elseif  (levelKey - playerLevel) <= 4  and (levelKey - playerLevel) >= 3 then
									colorr = 1
									colorg = 0.5
									colorb = 0
								elseif  (playerLevel - levelKey) <= 4  and (playerLevel - levelKey) >= 3 then
									colorr = 0
									colorg = 1
									colorb = 0
								elseif  (playerLevel - levelKey) > 4 then
									colorr = 0.5
									colorg = 0.5
									colorb = 0.5
								else
									colorr = 1
									colorg = 1
									colorb = 0
								end
							end
							if (item ~= "Damage") and (item ~= "Tank") and (item ~= "Healer") then
								infoFrame[tablelength(infoFrame)] = CreateFrame("Button", "vQueueInfoButton", hostListButtons[tablelength(hostListButtons)-1])
								infoFrame[tablelength(infoFrame)-1]:SetFont("Fonts\\FRIZQT__.TTF", 10)
								infoFrame[tablelength(infoFrame)-1]:SetText(item)
								infoFrame[tablelength(infoFrame)-1]:SetTextColor(colorr, colorg, colorb)
								infoFrame[tablelength(infoFrame)-1]:SetHighlightTextColor(1, 1, 0)
								infoFrame[tablelength(infoFrame)-1]:SetPushedTextOffset(0,0)
								infoFrame[tablelength(infoFrame)-1]:SetWidth(infoFrame[tablelength(infoFrame)-1]:GetTextWidth())
								infoFrame[tablelength(infoFrame)-1]:SetHeight(10)
								infoFrame[tablelength(infoFrame)-1]:EnableMouse(false)
								local point, relativeTo, relativePoint, xOffset, yOffset = hostListButtons[tablelength(hostListButtons)-1]:GetPoint(1)
								infoFrame[tablelength(infoFrame)-1]:SetPoint("RIGHT", vQueueFrame.hostlist, "TOPLEFT", ((vQueueFrame.hostlist:GetWidth() * 4/5 )/(tablelength(args)-1))*(i-1), yOffset)
							else
								infoFrame[tablelength(infoFrame)] = CreateFrame("Button", "vQueueInfoButton", hostListButtons[tablelength(hostListButtons)-1])
								infoFrame[tablelength(infoFrame)-1]:SetWidth(16)
								infoFrame[tablelength(infoFrame)-1]:SetHeight(16)
								infoFrame[tablelength(infoFrame)-1]:EnableMouse(false)
								infoFrame[tablelength(infoFrame)-1]:SetFrameLevel(1)
								local point, relativeTo, relativePoint, xOffset, yOffset = hostListButtons[tablelength(hostListButtons)-1]:GetPoint(1)
								infoFrame[tablelength(infoFrame)-1]:SetPoint("RIGHT", vQueueFrame.hostlist, "TOPLEFT", ((vQueueFrame.hostlist:GetWidth() * 4/5 )/(tablelength(args)-1))*(i-1), yOffset)
								local infoFrameIcon = infoFrame[tablelength(infoFrame)-1]:CreateTexture(nil, "ARTWORK")
								infoFrameIcon:SetAllPoints()
								infoFrameIcon:SetTexture("Interface\\AddOns\\vQueue\\" .. item)
								infoFrameIcon:SetWidth(infoFrame[tablelength(infoFrame)-1]:GetWidth())
								infoFrameIcon:SetHeight(infoFrame[tablelength(infoFrame)-1]:GetHeight())
							end
						end
					end
					local point, relativeTo, relativePoint, xOffset, yOffset = hostListButtons[tablelength(hostListButtons)-1]:GetPoint(1)
					vQueueFrame.hostlistInviteButton = CreateFrame("Button", nil, hostListButtons[tablelength(hostListButtons)-1], "UIPanelButtonTemplate")
					vQueueFrame.hostlistInviteButton:SetPoint("RIGHT", vQueueFrame.hostlist, "TOPLEFT", vQueueFrame.hostlist:GetWidth(), yOffset)
					vQueueFrame.hostlistInviteButton:SetFont("Fonts\\FRIZQT__.TTF", 8)
					vQueueFrame.hostlistInviteButton:SetText("invite")
					vQueueFrame.hostlistInviteButton:SetTextColor(0.85, 0.85, 0)
					vQueueFrame.hostlistInviteButton:SetWidth(vQueueFrame.hostlistInviteButton:GetTextWidth()+5)
					vQueueFrame.hostlistInviteButton:SetHeight(vQueueFrame.hostlistInviteButton:GetTextHeight()+3)
					vQueueFrame.hostlistInviteButton:SetScript("OnMouseDown", function()
						if this:GetText() == "invite" then
							this:SetText("invited")
							InviteByName(this:GetParent():GetText())
						end
					end)
					vQueueFrame.hostlistInviteButton:SetScript("OnUpdate", function()
						local tpoint, trelativeTo, trelativePoint, txOffset, yOffset = this:GetParent():GetPoint(1)
						local point, relativeTo, relativePoint, xOffset = this:GetPoint(1)
						this:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
					end)
					
					scrollbar:SetMinMaxValues(1, tablelength(hostListButtons)-5)
					scrollbar:SetValue(2)
					scrollbar:SetValue(1)
				end
				vQueueFrame.hostTitleRole:Show()
				vQueueFrame.hostTitleClass:Show()
				vQueueFrame.hostTitle:Show()
				vQueueFrame.hostTitleLevel:Show()
			end
		end)
		hostListFrame = vQueueFrame.hostlist
		
		vQueueFrame.hostlistBg = vQueueFrame.hostlist:CreateTexture(nil, "BACKGROUND")
		--vQueueFrame.hostlistBg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
		vQueueFrame.hostlistBg:ClearAllPoints()
		vQueueFrame.hostlistBg:SetPoint("CENTER", vQueueFrame.hostlist, "CENTER")
		vQueueFrame.hostlistBg:SetWidth(vQueueFrame.hostlist:GetWidth())
		vQueueFrame.hostlistBg:SetHeight(vQueueFrame.hostlist:GetHeight())
		vQueueFrame.hostlistBg:SetTexture(11/255, 11/255, 11/255, 0.8)
		
		vQueueFrame.hostlistborderLeft = vQueueFrame.hostlist:CreateTexture(nil, "BORDER")
		vQueueFrame.hostlistborderLeft:SetTexture("Interface\\AddOns\\vQueue\\ThinBorder-Left")
		vQueueFrame.hostlistborderLeft:ClearAllPoints()
		vQueueFrame.hostlistborderLeft:SetPoint("LEFT", vQueueFrame.hostlist, "LEFT", -2, 0)
		vQueueFrame.hostlistborderLeft:SetWidth(10)
		vQueueFrame.hostlistborderLeft:SetHeight(vQueueFrame.hostlist:GetHeight()-13)
		
		vQueueFrame.hostlistborderRight = vQueueFrame.hostlist:CreateTexture(nil, "BORDER")
		vQueueFrame.hostlistborderRight:SetTexture("Interface\\AddOns\\vQueue\\ThinBorder-Right")
		vQueueFrame.hostlistborderRight:ClearAllPoints()
		vQueueFrame.hostlistborderRight:SetPoint("RIGHT", vQueueFrame.hostlist, "RIGHT", 3, 0)
		vQueueFrame.hostlistborderRight:SetWidth(10)
		vQueueFrame.hostlistborderRight:SetHeight(vQueueFrame.hostlist:GetHeight()-13)
		
		vQueueFrame.hostlistborderTop = vQueueFrame.hostlist:CreateTexture(nil, "BORDER")
		vQueueFrame.hostlistborderTop:SetTexture("Interface\\AddOns\\vQueue\\ThinBorder-Top")
		vQueueFrame.hostlistborderTop:ClearAllPoints()
		vQueueFrame.hostlistborderTop:SetPoint("TOP", vQueueFrame.hostlist, "TOP", 0, 2)
		vQueueFrame.hostlistborderTop:SetWidth(vQueueFrame.hostlist:GetWidth() - 13)
		vQueueFrame.hostlistborderTop:SetHeight(10)
		
		vQueueFrame.hostlistborderBot = vQueueFrame.hostlist:CreateTexture(nil, "BORDER")
		vQueueFrame.hostlistborderBot:SetTexture("Interface\\AddOns\\vQueue\\ThinBorder-Bottom")
		vQueueFrame.hostlistborderBot:ClearAllPoints()
		vQueueFrame.hostlistborderBot:SetPoint("BOTTOM", vQueueFrame.hostlist, "BOTTOM", 0, -2)
		vQueueFrame.hostlistborderBot:SetWidth(vQueueFrame.hostlist:GetWidth() - 14)
		vQueueFrame.hostlistborderBot:SetHeight(10)
		
		vQueueFrame.hostlistborderTopRight = vQueueFrame.hostlist:CreateTexture(nil, "BORDER")
		vQueueFrame.hostlistborderTopRight:SetTexture("Interface\\AddOns\\vQueue\\ThinBorder-TopRight")
		vQueueFrame.hostlistborderTopRight:ClearAllPoints()
		vQueueFrame.hostlistborderTopRight:SetPoint("TOPRIGHT", vQueueFrame.hostlist, "TOPRIGHT", 3, 2)
		vQueueFrame.hostlistborderTopRight:SetWidth(10)
		vQueueFrame.hostlistborderTopRight:SetHeight(10)
		
		vQueueFrame.hostlistborderTopLeft = vQueueFrame.hostlist:CreateTexture(nil, "BORDER")
		vQueueFrame.hostlistborderTopLeft:SetTexture("Interface\\AddOns\\vQueue\\ThinBorder-TopLeft")
		vQueueFrame.hostlistborderTopLeft:ClearAllPoints()
		vQueueFrame.hostlistborderTopLeft:SetPoint("TOPLEFT", vQueueFrame.hostlist, "TOPLEFT", -2, 2)
		vQueueFrame.hostlistborderTopLeft:SetWidth(10)
		vQueueFrame.hostlistborderTopLeft:SetHeight(10)
		
		vQueueFrame.hostlistborderBotRight = vQueueFrame.hostlist:CreateTexture(nil, "BORDER")
		vQueueFrame.hostlistborderBotRight:SetTexture("Interface\\AddOns\\vQueue\\ThinBorder-BottomRight")
		vQueueFrame.hostlistborderBotRight:ClearAllPoints()
		vQueueFrame.hostlistborderBotRight:SetPoint("BOTTOMRIGHT", vQueueFrame.hostlist, "BOTTOMRIGHT", 2.4, -2)
		vQueueFrame.hostlistborderBotRight:SetWidth(10)
		vQueueFrame.hostlistborderBotRight:SetHeight(10)
		
		vQueueFrame.hostlistborderBotLeft = vQueueFrame.hostlist:CreateTexture(nil, "BORDER")
		vQueueFrame.hostlistborderBotLeft:SetTexture("Interface\\AddOns\\vQueue\\ThinBorder-BottomLeft")
		vQueueFrame.hostlistborderBotLeft:ClearAllPoints()
		vQueueFrame.hostlistborderBotLeft:SetPoint("BOTTOMLEFT", vQueueFrame.hostlist, "BOTTOMLEFT", -2, -2)
		vQueueFrame.hostlistborderBotLeft:SetWidth(10)
		vQueueFrame.hostlistborderBotLeft:SetHeight(10)
		
		vQueueFrame.hostlistTopSection = CreateFrame("Frame", nil, vQueueFrame.hostlist)
		vQueueFrame.hostlistTopSection:ClearAllPoints()
		vQueueFrame.hostlistTopSection:SetPoint("TOPLEFT", vQueueFrame.hostlist, "TOPLEFT", 0 , 0)
		vQueueFrame.hostlistTopSection:SetWidth(vQueueFrame.hostlist:GetWidth())
		vQueueFrame.hostlistTopSection:SetHeight(vQueueFrame.hostlist:GetHeight() * 1/5)
		vQueueFrame.hostlistTopSection:SetFrameLevel(2)
		
		vQueueFrame.hostlistTopSectionBg = vQueueFrame.hostlistTopSection:CreateTexture(nil, "BACKGROUND")
		vQueueFrame.hostlistTopSectionBg:SetTexture(0, 0, 0, 0)
		--vQueueFrame.hostlistTopSectionBg:SetTexture("Interface\\AddOns\\vQueue\\rfc")
		vQueueFrame.hostlistTopSectionBg:ClearAllPoints()
		vQueueFrame.hostlistTopSectionBg:SetPoint("TOPLEFT", vQueueFrame.hostlist, "TOPLEFT", 0, 0)
		vQueueFrame.hostlistTopSectionBg:SetAllPoints()
		
		vQueueFrame.hostlistTopSectionBorder = vQueueFrame.hostlistTopSection:CreateTexture(nil, "BORDER")
		vQueueFrame.hostlistTopSectionBorder:SetTexture("Interface\\AddOns\\vQueue\\ThinBorder-Bottom")
		vQueueFrame.hostlistTopSectionBorder:ClearAllPoints()
		vQueueFrame.hostlistTopSectionBorder:SetPoint("BOTTOM", vQueueFrame.hostlistTopSection, "BOTTOM", 0, -2)
		vQueueFrame.hostlistTopSectionBorder:SetWidth(vQueueFrame.hostlistTopSection:GetWidth())
		vQueueFrame.hostlistTopSectionBorder:SetHeight(10)
		
		vQueueFrame.hostlistBotShadow = vQueueFrame.hostlistTopSection:CreateTexture(nil, "OVERLAY")
		vQueueFrame.hostlistBotShadow:SetTexture(0, 0, 0, 1)
		vQueueFrame.hostlistBotShadow:SetPoint("BOTTOM", vQueueFrame.hostlist, "BOTTOM", 0, 1)
		vQueueFrame.hostlistBotShadow:SetWidth(vQueueFrame.hostlist:GetWidth())
		vQueueFrame.hostlistBotShadow:SetHeight(40)
		vQueueFrame.hostlistBotShadow:SetGradientAlpha("VERTICAL", 0, 0, 0, 1, 0, 0, 0, 0)
		
		vQueueFrame.catlistBotShadow = CreateFrame("Frame", nil, vQueueFrame.catList)
		vQueueFrame.catlistBotShadow:SetAllPoints()
		vQueueFrame.catlistBotShadow:SetWidth(vQueueFrame.catList:GetWidth())
		vQueueFrame.catlistBotShadow:SetHeight(vQueueFrame.catList:GetHeight())
		vQueueFrame.catlistBotShadow:SetFrameLevel(2)
		
		vQueueFrame.catlistBotShadowbg = vQueueFrame.catlistBotShadow:CreateTexture(nil, "OVERLAY")
		vQueueFrame.catlistBotShadowbg:SetTexture(0, 0, 0, 1)
		vQueueFrame.catlistBotShadowbg:SetPoint("BOTTOM", vQueueFrame.catList, "BOTTOM", 0, 1)
		vQueueFrame.catlistBotShadowbg:SetWidth(vQueueFrame.catList:GetWidth())
		vQueueFrame.catlistBotShadowbg:SetHeight(40)
		vQueueFrame.catlistBotShadowbg:SetGradientAlpha("VERTICAL", 0, 0, 0, 1, 0, 0, 0, 0)
		
		vQueueFrame.hostTitle = CreateFrame("Button", "vQueueButton", vQueueFrame.hostlist)
		vQueueFrame.hostTitle:ClearAllPoints()
		vQueueFrame.hostTitle:SetPoint("TOPLEFT", vQueueFrame.hostlist, "TOPLEFT", 0 , -vQueueFrame.hostlistTopSection:GetHeight()-5)
		vQueueFrame.hostTitle:SetFont("Fonts\\FRIZQT__.TTF", 10)
		vQueueFrame.hostTitle:SetText("Name")
		vQueueFrame.hostTitle:SetTextColor(209/255, 164/255, 29/255)
		vQueueFrame.hostTitle:SetPushedTextOffset(0,0)
		vQueueFrame.hostTitle:SetWidth(vQueueFrame.hostTitle:GetTextWidth())
		vQueueFrame.hostTitle:SetHeight(vQueueFrame.hostTitle:GetTextHeight())
		vQueueFrame.hostTitle:Hide()
		
		vQueueFrame.hostTitleLevel = CreateFrame("Button", "vQueueButton", vQueueFrame.hostlist)
		vQueueFrame.hostTitleLevel:ClearAllPoints()
		vQueueFrame.hostTitleLevel:SetPoint("TOPRIGHT", vQueueFrame.hostlist, "TOPLEFT", 130, -vQueueFrame.hostlistTopSection:GetHeight() - 5)
		vQueueFrame.hostTitleLevel:SetFont("Fonts\\FRIZQT__.TTF", 10)
		vQueueFrame.hostTitleLevel:SetText("Level")
		vQueueFrame.hostTitleLevel:SetTextColor(209/255, 164/255, 29/255)
		vQueueFrame.hostTitleLevel:SetPushedTextOffset(0,0)
		vQueueFrame.hostTitleLevel:SetWidth(vQueueFrame.hostTitleLevel:GetTextWidth())
		vQueueFrame.hostTitleLevel:SetHeight(vQueueFrame.hostTitleLevel:GetTextHeight())
		vQueueFrame.hostTitleLevel:Hide()
		
		vQueueFrame.hostTitleClass = CreateFrame("Button", "vQueueButton", vQueueFrame.hostlist)
		vQueueFrame.hostTitleClass:ClearAllPoints()
		vQueueFrame.hostTitleClass:SetPoint("TOPRIGHT", vQueueFrame.hostlist, "TOPLEFT", 245, -vQueueFrame.hostlistTopSection:GetHeight() - 5)
		vQueueFrame.hostTitleClass:SetFont("Fonts\\FRIZQT__.TTF", 10)
		vQueueFrame.hostTitleClass:SetText("Class")
		vQueueFrame.hostTitleClass:SetTextColor(209/255, 164/255, 29/255)
		vQueueFrame.hostTitleClass:SetPushedTextOffset(0,0)
		vQueueFrame.hostTitleClass:SetWidth(vQueueFrame.hostTitleClass:GetTextWidth())
		vQueueFrame.hostTitleClass:SetHeight(vQueueFrame.hostTitleClass:GetTextHeight())
		vQueueFrame.hostTitleClass:Hide()
		
		vQueueFrame.hostTitleRole = CreateFrame("Button", "vQueueButton", vQueueFrame.hostlist)
		vQueueFrame.hostTitleRole:ClearAllPoints()
		vQueueFrame.hostTitleRole:SetPoint("TOPRIGHT", vQueueFrame.hostlist, "TOPLEFT", 370, -vQueueFrame.hostlistTopSection:GetHeight() - 5)
		vQueueFrame.hostTitleRole:SetFont("Fonts\\FRIZQT__.TTF", 10)
		vQueueFrame.hostTitleRole:SetText("Role")
		vQueueFrame.hostTitleRole:SetTextColor(209/255, 164/255, 29/255)
		vQueueFrame.hostTitleRole:SetPushedTextOffset(0,0)
		vQueueFrame.hostTitleRole:SetWidth(vQueueFrame.hostTitleRole:GetTextWidth())
		vQueueFrame.hostTitleRole:SetHeight(vQueueFrame.hostTitleRole:GetTextHeight())
		vQueueFrame.hostTitleRole:Hide()	
		
		vQueueFrame.hostlistHeal = CreateFrame("Button", nil, vQueueFrame.hostlistTopSection)
		vQueueFrame.hostlistHeal:ClearAllPoints()
		vQueueFrame.hostlistHeal:SetPoint("RIGHT", vQueueFrame.hostlistTopSection, "RIGHT", -32, 0)
		vQueueFrame.hostlistHeal:SetWidth(32)
		vQueueFrame.hostlistHeal:SetHeight(32)
		vQueueFrame.hostlistHeal:SetScript("OnMouseDown", function()
			vQueueFrame.hostlistTankTex:SetVertexColor(1, 1, 1)
			vQueueFrame.hostlistDpsTex:SetVertexColor(1, 1, 1)
			vQueueFrame.hostlistHealTex:SetVertexColor(0.5, 1, 0.5)
			vQueueFrame.hostlistRoleText:SetText("")
			if not isHost then
				vQueueFrame.hostlistHostButton:Show()
				vQueueFrame.hostlistFindButton:Show()
			end
			selectedRole = "Healer"
		end)
		
		vQueueFrame.hostlistHealTex = vQueueFrame.hostlistHeal:CreateTexture(nil, "ARTWORK")
		vQueueFrame.hostlistHealTex:SetTexture("Interface\\AddOns\\vQueue\\Healer")
		vQueueFrame.hostlistHealTex:ClearAllPoints()
		vQueueFrame.hostlistHealTex:SetPoint("TOP", vQueueFrame.hostlistHeal, "TOP", 0, 0)
		vQueueFrame.hostlistHealTex:SetWidth(vQueueFrame.hostlistHeal:GetWidth())
		vQueueFrame.hostlistHealTex:SetHeight(vQueueFrame.hostlistHeal:GetHeight())
		
		vQueueFrame.hostlistDps = CreateFrame("Button", nil, vQueueFrame.hostlistTopSection)
		vQueueFrame.hostlistDps:ClearAllPoints()
		vQueueFrame.hostlistDps:SetPoint("RIGHT", vQueueFrame.hostlistTopSection, "RIGHT",  0, 0)
		vQueueFrame.hostlistDps:SetWidth(32)
		vQueueFrame.hostlistDps:SetHeight(32)
		vQueueFrame.hostlistDps:SetScript("OnMouseDown", function()
			vQueueFrame.hostlistTankTex:SetVertexColor(1, 1, 1)
			vQueueFrame.hostlistDpsTex:SetVertexColor(0.5, 1, 0.5)
			vQueueFrame.hostlistHealTex:SetVertexColor(1, 1, 1)
			vQueueFrame.hostlistRoleText:SetText("")
			if not isHost then
				vQueueFrame.hostlistHostButton:Show()
				vQueueFrame.hostlistFindButton:Show()
			end
			selectedRole = "Damage"
		end)
		
		vQueueFrame.hostlistDpsTex = vQueueFrame.hostlistDps:CreateTexture(nil, "ARTWORK")
		vQueueFrame.hostlistDpsTex:SetTexture("Interface\\AddOns\\vQueue\\Damage")
		vQueueFrame.hostlistDpsTex:ClearAllPoints()
		vQueueFrame.hostlistDpsTex:SetPoint("TOP", vQueueFrame.hostlistDps, "TOP", 0, 0)
		vQueueFrame.hostlistDpsTex:SetWidth(vQueueFrame.hostlistDps:GetWidth())
		vQueueFrame.hostlistDpsTex:SetHeight(vQueueFrame.hostlistDps:GetHeight())
		
		vQueueFrame.hostlistTank = CreateFrame("Button", nil, vQueueFrame.hostlistTopSection)
		vQueueFrame.hostlistTank:ClearAllPoints()
		vQueueFrame.hostlistTank:SetPoint("RIGHT", vQueueFrame.hostlistTopSection, "RIGHT", -64 , 0)
		vQueueFrame.hostlistTank:SetWidth(32)
		vQueueFrame.hostlistTank:SetHeight(32)
		vQueueFrame.hostlistTank:SetScript("OnMouseDown", function()
			vQueueFrame.hostlistTankTex:SetVertexColor(0.5, 1, 0.5)
			vQueueFrame.hostlistDpsTex:SetVertexColor(1, 1, 1)
			vQueueFrame.hostlistHealTex:SetVertexColor(1, 1, 1)
			vQueueFrame.hostlistRoleText:SetText("")
			if not isHost then
				vQueueFrame.hostlistHostButton:Show()
				vQueueFrame.hostlistFindButton:Show()
			end
			selectedRole = "Tank"
		end)
				
		vQueueFrame.hostlistTankTex = vQueueFrame.hostlistTank:CreateTexture(nil, "ARTWORK")
		vQueueFrame.hostlistTankTex:SetTexture("Interface\\AddOns\\vQueue\\Tank")
		vQueueFrame.hostlistTankTex:ClearAllPoints()
		vQueueFrame.hostlistTankTex:SetPoint("TOP", vQueueFrame.hostlistTank, "TOP", 0, 0)
		vQueueFrame.hostlistTankTex:SetWidth(vQueueFrame.hostlistTank:GetWidth())
		vQueueFrame.hostlistTankTex:SetHeight(vQueueFrame.hostlistTank:GetHeight())
		
		vQueueFrame.hostlistRoleText = CreateFrame("Button", nil, vQueueFrame.hostlistTopSection)
		vQueueFrame.hostlistRoleText:ClearAllPoints()
		vQueueFrame.hostlistRoleText:SetPoint("BOTTOMLEFT", vQueueFrame.hostlistTopSection, "BOTTOMLEFT", 5, 5)
		vQueueFrame.hostlistRoleText:EnableMouse(false)
		vQueueFrame.hostlistRoleText:SetFont("Fonts\\FRIZQT__.TTF", 10)
		vQueueFrame.hostlistRoleText:SetText("(Select a role)")
		vQueueFrame.hostlistRoleText:SetTextColor(209/255, 164/255, 29/255)
		vQueueFrame.hostlistRoleText:SetWidth(vQueueFrame.hostlistRoleText:GetTextWidth())
		vQueueFrame.hostlistRoleText:SetHeight(vQueueFrame.hostlistRoleText:GetTextHeight())
		vQueueFrame.hostlistRoleText:SetScript("OnUpdate", function()
			this:SetWidth(vQueueFrame.hostlistRoleText:GetTextWidth())
			this:SetHeight(vQueueFrame.hostlistRoleText:GetTextHeight())
		end)
		
		vQueueFrame.hostlistHostButton = CreateFrame("Button", nil, vQueueFrame.hostlistTopSection, "UIPanelButtonTemplate")
		vQueueFrame.hostlistHostButton:SetPoint("BOTTOMRIGHT", vQueueFrame.hostlistTopSection, "BOTTOMRIGHT", -3, 5)
		vQueueFrame.hostlistHostButton:SetFont("Fonts\\FRIZQT__.TTF", 10)
		vQueueFrame.hostlistHostButton:SetText("Create")
		vQueueFrame.hostlistHostButton:SetTextColor(209/255, 164/255, 29/255)
		vQueueFrame.hostlistHostButton:SetWidth(vQueueFrame.hostlistHostButton:GetTextWidth()+5)
		vQueueFrame.hostlistHostButton:SetHeight(vQueueFrame.hostlistHostButton:GetTextHeight()+3)
		vQueueFrame.hostlistHostButton:SetScript("OnMouseDown", function()
			vQueueFrame.hostlistHostButton:Hide()
			vQueueFrame.hostlistFindButton:Hide()
			--vQueueFrame.hostlistTank:Hide()
			--vQueueFrame.hostlistHeal:Hide()
			--vQueueFrame.hostlistDps:Hide()
			--vQueueFrame.hostlistRoleText:Hide()
			
			vQueueFrame.hostlistLevelField:Show()
			vQueueFrame.hostlistNameField:Show()
			vQueueFrame.hostlistCreateButton:Show()
		end)
		
		
		vQueueFrame.hostlistFindButton = CreateFrame("Button", nil, vQueueFrame.hostlistTopSection, "UIPanelButtonTemplate")
		vQueueFrame.hostlistFindButton:SetPoint("BOTTOMRIGHT", vQueueFrame.hostlistTopSection, "BOTTOMRIGHT", -vQueueFrame.hostlistHostButton:GetWidth() - 10, 5)
		vQueueFrame.hostlistFindButton:SetFont("Fonts\\FRIZQT__.TTF", 10)
		vQueueFrame.hostlistFindButton:SetText("Find")
		--vQueueFrame.hostlistFindButton:SetButtonState("NORMAL", true)
		vQueueFrame.hostlistFindButton:SetTextColor(209/255, 164/255, 29/255)
		vQueueFrame.hostlistFindButton:SetWidth(vQueueFrame.hostlistFindButton:GetTextWidth()+5)
		vQueueFrame.hostlistFindButton:SetHeight(vQueueFrame.hostlistFindButton:GetTextHeight()+3)
		vQueueFrame.hostlistFindButton:SetScript("OnMouseDown", function()
			vQueueFrame.hostlistFindButton:SetButtonState("PUSHED", false)
			isFinding = true
			vQueue_SlashCommandHandler( "lfg " .. selectedQuery )
			vQueueFrame.hostlist:Hide()
			vQueueFrame.hostlist:Show()
		end)
		vQueueFrame.hostlistFindButton:SetScript("OnLeave", function()
			vQueueFrame.hostlistFindButton:SetButtonState("NORMAL", false)
			--vQueueFrame.hostlistFindButton:SetButtonState("NORMAL", true)
		end)
		
		vQueueFrame.hostlistNameField = CreateFrame("EditBox", nil, vQueueFrame.hostlist )
		vQueueFrame.hostlistNameField:SetPoint("CENTER", vQueueFrame.hostlist, "CENTER", 0, 20)
		vQueueFrame.hostlistNameField:SetAutoFocus(false)
		vQueueFrame.hostlistNameField:SetFont("Fonts\\FRIZQT__.TTF", 10)
		vQueueFrame.hostlistNameField:SetText("LFM")
		vQueueFrame.hostlistNameField:SetTextColor(1, 1, 1)
		vQueueFrame.hostlistNameField:SetMaxLetters(100)
		vQueueFrame.hostlistNameField:SetWidth(vQueueFrame.hostlist:GetWidth() * 4/5)
		vQueueFrame.hostlistNameField:SetHeight(20)
		
		vQueueFrame.hostlistNameFieldBg = vQueueFrame.hostlistNameField:CreateTexture(nil, "BACKGROUND")
		vQueueFrame.hostlistNameFieldBg:SetPoint("RIGHT", vQueueFrame.hostlistNameField, "CENTER", -10, 0)
		vQueueFrame.hostlistNameFieldBg:SetTexture("Interface\\CHATFRAME\\UI-CHATINPUTBORDER-LEFT")
		vQueueFrame.hostlistNameFieldBg:SetWidth((vQueueFrame.hostlistNameField:GetWidth()/2))
		vQueueFrame.hostlistNameFieldBg:SetHeight(25)
		
		vQueueFrame.hostlistNameFieldBgRight = vQueueFrame.hostlistNameField:CreateTexture(nil, "BACKGROUND")
		vQueueFrame.hostlistNameFieldBgRight:SetPoint("LEFT", vQueueFrame.hostlistNameField, "CENTER", -10, 0)
		vQueueFrame.hostlistNameFieldBgRight:SetTexture("Interface\\CHATFRAME\\UI-CHATINPUTBORDER-RIGHT")
		vQueueFrame.hostlistNameFieldBgRight:SetWidth((vQueueFrame.hostlistNameField:GetWidth()/2) + 15)
		vQueueFrame.hostlistNameFieldBgRight:SetHeight(25)
		
		vQueueFrame.hostlistNameFieldText = CreateFrame("Button", nil, vQueueFrame.hostlistNameField)
		vQueueFrame.hostlistNameFieldText:ClearAllPoints()
		vQueueFrame.hostlistNameFieldText:SetPoint("CENTER", vQueueFrame.hostlistNameField, "CENTER", -8, 20)
		vQueueFrame.hostlistNameFieldText:SetFont("Fonts\\FRIZQT__.TTF", 12)
		vQueueFrame.hostlistNameFieldText:SetText("Title")
		vQueueFrame.hostlistNameFieldText:SetTextColor(0.85, 0.85, 0)
		vQueueFrame.hostlistNameFieldText:SetPushedTextOffset(0,0)
		vQueueFrame.hostlistNameFieldText:SetWidth(vQueueFrame.hostlistNameFieldText:GetTextWidth())
		vQueueFrame.hostlistNameFieldText:SetHeight(vQueueFrame.hostlistNameFieldText:GetTextHeight())
		
		vQueueFrame.hostlistLevelField = CreateFrame("EditBox", nil, vQueueFrame.hostlistNameField )
		vQueueFrame.hostlistLevelField:SetPoint("TOPLEFT", vQueueFrame.hostlistNameField, "BOTTOMLEFT", 0, -6)
		vQueueFrame.hostlistLevelField:SetAutoFocus(false)
		vQueueFrame.hostlistLevelField:SetFont("Fonts\\FRIZQT__.TTF", 10)
		vQueueFrame.hostlistLevelField:SetText(tostring(UnitLevel("player")))
		vQueueFrame.hostlistLevelField:SetTextColor(1, 1, 1)
		vQueueFrame.hostlistLevelField:SetMaxLetters(2)
		vQueueFrame.hostlistLevelField:SetNumeric(true)
		vQueueFrame.hostlistLevelField:SetWidth(28)
		vQueueFrame.hostlistLevelField:SetHeight(28)
		
		vQueueFrame.hostlistLevelFieldBg = vQueueFrame.hostlistLevelField:CreateTexture(nil, "BACKGROUND")
		vQueueFrame.hostlistLevelFieldBg:SetPoint("RIGHT", vQueueFrame.hostlistLevelField, "CENTER", 7, 0)
		vQueueFrame.hostlistLevelFieldBg:SetTexture("Interface\\BUTTONS\\UI-Quickslot")
		vQueueFrame.hostlistLevelFieldBg:SetWidth(vQueueFrame.hostlistLevelField:GetWidth())
		vQueueFrame.hostlistLevelFieldBg:SetHeight(28)
		
		vQueueFrame.hostlistLevelFieldText = CreateFrame("Button", nil, vQueueFrame.hostlistLevelField)
		vQueueFrame.hostlistLevelFieldText:ClearAllPoints()
		vQueueFrame.hostlistLevelFieldText:SetPoint("LEFT", vQueueFrame.hostlistLevelField, "RIGHT", -10, 0)
		vQueueFrame.hostlistLevelFieldText:SetFont("Fonts\\FRIZQT__.TTF", 8)
		vQueueFrame.hostlistLevelFieldText:SetText("Minimum lvl")
		vQueueFrame.hostlistLevelFieldText:SetTextColor(0.85, 0.85, 0)
		vQueueFrame.hostlistLevelFieldText:SetPushedTextOffset(0,0)
		vQueueFrame.hostlistLevelFieldText:SetWidth(vQueueFrame.hostlistLevelFieldText:GetTextWidth())
		vQueueFrame.hostlistLevelFieldText:SetHeight(vQueueFrame.hostlistLevelFieldText:GetTextHeight())
		
		--Role Icons for group creation
		vQueueFrame.hostlistHostHealer = CreateFrame("Button", "vQueueInfoButton", vQueueFrame.hostlistNameField)
		vQueueFrame.hostlistHostHealer:SetWidth(32)
		vQueueFrame.hostlistHostHealer:SetHeight(32)
		vQueueFrame.hostlistHostHealer:SetFrameLevel(1)
		vQueueFrame.hostlistHostHealer:SetPoint("TOPRIGHT", vQueueFrame.hostlistNameField, "BOTTOMRIGHT", -32, -5)
		vQueueFrame.hostlistHostHealerTex = vQueueFrame.hostlistHostHealer:CreateTexture(nil, "ARTWORK")
		vQueueFrame.hostlistHostHealerTex:SetAllPoints()
		vQueueFrame.hostlistHostHealerTex:SetTexture("Interface\\AddOns\\vQueue\\Healer")
		vQueueFrame.hostlistHostHealerTex:SetWidth(vQueueFrame.hostlistHostHealer:GetWidth())
		vQueueFrame.hostlistHostHealerTex:SetHeight(vQueueFrame.hostlistHostHealer:GetHeight())
		vQueueFrame.hostlistHostHealer:SetScript("OnMouseDown", function()
			healerSelected = not healerSelected
			if healerSelected then
				vQueueFrame.hostlistHostHealerTex:SetVertexColor(0.5, 1, 0.5)
			else
				vQueueFrame.hostlistHostHealerTex:SetVertexColor(1, 1, 1)
			end
		end)
		
		vQueueFrame.hostlistHostDamage = CreateFrame("Button", "vQueueInfoButton", vQueueFrame.hostlistNameField)
		vQueueFrame.hostlistHostDamage:SetWidth(32)
		vQueueFrame.hostlistHostDamage:SetHeight(32)
		vQueueFrame.hostlistHostDamage:SetFrameLevel(1)
		vQueueFrame.hostlistHostDamage:SetPoint("TOPRIGHT", vQueueFrame.hostlistNameField, "BOTTOMRIGHT", 0, -5)
		vQueueFrame.hostlistHostDamageTex = vQueueFrame.hostlistHostDamage:CreateTexture(nil, "ARTWORK")
		vQueueFrame.hostlistHostDamageTex:SetAllPoints()
		vQueueFrame.hostlistHostDamageTex:SetTexture("Interface\\AddOns\\vQueue\\Damage")
		vQueueFrame.hostlistHostDamageTex:SetWidth(vQueueFrame.hostlistHostDamage:GetWidth())
		vQueueFrame.hostlistHostDamageTex:SetHeight(vQueueFrame.hostlistHostDamage:GetHeight())
		vQueueFrame.hostlistHostDamage:SetScript("OnMouseDown", function()
			damageSelected = not damageSelected
			if damageSelected then
				vQueueFrame.hostlistHostDamageTex:SetVertexColor(0.5, 1, 0.5)
			else
				vQueueFrame.hostlistHostDamageTex:SetVertexColor(1, 1, 1)
			end
		end)
		
		vQueueFrame.hostlistHostTank = CreateFrame("Button", "vQueueInfoButton", vQueueFrame.hostlistNameField)
		vQueueFrame.hostlistHostTank:SetWidth(32)
		vQueueFrame.hostlistHostTank:SetHeight(32)
		vQueueFrame.hostlistHostTank:SetFrameLevel(1)
		vQueueFrame.hostlistHostTank:SetPoint("TOPRIGHT", vQueueFrame.hostlistNameField, "BOTTOMRIGHT", -64, -5)
		vQueueFrame.hostlistHostTankTex = vQueueFrame.hostlistHostTank:CreateTexture(nil, "ARTWORK")
		vQueueFrame.hostlistHostTankTex:SetAllPoints()
		vQueueFrame.hostlistHostTankTex:SetTexture("Interface\\AddOns\\vQueue\\Tank")
		vQueueFrame.hostlistHostTankTex:SetWidth(vQueueFrame.hostlistHostTank:GetWidth())
		vQueueFrame.hostlistHostTankTex:SetHeight(vQueueFrame.hostlistHostTank:GetHeight())
		vQueueFrame.hostlistHostTank:SetScript("OnMouseDown", function()
			tankSelected = not tankSelected
			if tankSelected then
				vQueueFrame.hostlistHostTankTex:SetVertexColor(0.5, 1, 0.5)
			else
				vQueueFrame.hostlistHostTankTex:SetVertexColor(1, 1, 1)
			end
		end)
		
		vQueueFrame.hostlistNeededRolesText = CreateFrame("Button", nil, vQueueFrame.hostlistHostTank )
		vQueueFrame.hostlistNeededRolesText:SetPoint("RIGHT", vQueueFrame.hostlistHostTank , "LEFT", 0, 2)
		vQueueFrame.hostlistNeededRolesText:SetFont("Fonts\\FRIZQT__.TTF", 8)
		vQueueFrame.hostlistNeededRolesText:SetText("Needed roles")
		vQueueFrame.hostlistNeededRolesText:SetTextColor(0.85, 0.85, 0)
		vQueueFrame.hostlistNeededRolesText:SetPushedTextOffset(0,0)
		vQueueFrame.hostlistNeededRolesText:SetWidth(vQueueFrame.hostlistNeededRolesText:GetTextWidth())
		vQueueFrame.hostlistNeededRolesText:SetHeight(vQueueFrame.hostlistNeededRolesText:GetTextHeight())
		---------------------------------------------------
		
		vQueueFrame.hostlistCreateButton = CreateFrame("Button", nil, vQueueFrame.hostlist, "UIPanelButtonTemplate")
		vQueueFrame.hostlistCreateButton:SetPoint("CENTER", vQueueFrame.hostlist, "CENTER", -8, -100)
		vQueueFrame.hostlistCreateButton:SetFont("Fonts\\FRIZQT__.TTF", 14)
		vQueueFrame.hostlistCreateButton:SetText("Create group")
		vQueueFrame.hostlistCreateButton:SetTextColor(0.85, 0.85, 0)
		vQueueFrame.hostlistCreateButton:SetWidth(vQueueFrame.hostlistCreateButton:GetTextWidth()+30)
		vQueueFrame.hostlistCreateButton:SetHeight(vQueueFrame.hostlistCreateButton:GetTextHeight()+20)
		vQueueFrame.hostlistCreateButton:SetScript("OnMouseDown", function()
			if vQueueFrame.hostlistNameField:GetText() ~= "" and vQueueFrame.hostlistLevelField:GetText() ~= "" then
				if tonumber(vQueueFrame.hostlistLevelField:GetText()) < 0 then vQueueFrame.hostlistLevelField:SetText("1") end
				if tonumber(vQueueFrame.hostlistLevelField:GetText()) > 60 then vQueueFrame.hostlistLevelField:SetText("60") end
				hostOptions[0] = vQueueFrame.hostlistNameField:GetText()
				hostOptions[1] = vQueueFrame.hostlistLevelField:GetText()
				hostOptions[2] = healerSelected
				hostOptions[3] = damageSelected
				hostOptions[4] = tankSelected
				
				vQueueFrame.hostlistLevelField:Hide()
				vQueueFrame.hostlistNameField:Hide()
				this:Hide()
				vQueue_SlashCommandHandler( "host " .. selectedQuery )
				
				vQueueFrame.hostlist:Hide()
				vQueueFrame.hostlist:Show()
			end
		end)
		
		--scrollbar
		scrollbar = CreateFrame("Slider", nil, vQueueFrame.hostlist, "UIPanelScrollBarTemplate") 
		scrollbar:SetMinMaxValues(1, 1)
		scrollbar:SetValueStep(1)
		scrollbar.scrollStep = 1
		scrollbar:SetValue(0)
		scrollbar:EnableMouse(true)
		scrollbar:EnableMouseWheel(true)
		scrollbar:SetWidth(16)
		scrollbar:SetHeight((vQueueFrame.hostlist:GetHeight()* 4/5) - 35)
		scrollbar:SetPoint("BOTTOMLEFT", vQueueFrame.hostlist, "BOTTOMRIGHT", -16, 16)
		scrollbar:SetScript("OnValueChanged",
		function (self, value)
			local position = 1
			if 1 < this:GetValue() or ( (hostListButtons[0]:GetTextHeight()*0) + (6*0) ) > (this:GetHeight()+(this:GetValue()*(hostListButtons[0]:GetTextHeight()+6))) then
				hostListButtons[0]:Hide()
			else
				hostListButtons[0]:Show()
				position = 2
			end
			
			for k, v in ipairs(hostListButtons) do
				local kPos = k
				if position == 1 then kPos = k - 1  end
				if k < this:GetValue() or ( (v:GetTextHeight()*kPos) + (6*kPos) ) > (this:GetHeight()+(this:GetValue()*(v:GetTextHeight()+6))) then
					v:Hide()
				else
					v:Show()
				end
			end
			for k, v in ipairs(hostListButtons) do
				if v:IsShown() then
					point, relativeTo, relativePoint, xOffset, yOffset = v:GetPoint(1)
					v:SetPoint(point, relativeTo, relativePoint, xOffset, -(position*15)-10 - vQueueFrame.hostlistTopSection:GetHeight())
					position = position+1
				end
			end
			
			for k, v in ipairs(infoFrame) do
				point, relativeTo, relativePoint, xOffset = v:GetPoint(1)
				tpoint, trelativeTo, trelativePoint, txOffset, yOffset = v:GetParent():GetPoint(1)
				v:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
			end

		end)
		local scrollbg = scrollbar:CreateTexture(nil, "OVERLAY")
		scrollbg:SetAllPoints(scrollbar)
		scrollbg:SetTexture(0, 0, 0, 0.3)
		scrollbar:Hide()
		
		--scrollbar
		scrollbarCat = CreateFrame("Slider", nil, vQueueFrame.catList, "UIPanelScrollBarTemplate") 
		scrollbarCat:SetMinMaxValues(1, 10)
		scrollbarCat:SetValueStep(1)
		scrollbarCat.scrollStep = 1
		scrollbarCat:SetValue(0)
		scrollbarCat:EnableMouse(true)
		scrollbarCat:EnableMouseWheel(true)
		scrollbarCat:SetWidth(16)
		scrollbarCat:SetHeight(vQueueFrame.catList:GetHeight()-32)
		scrollbarCat:SetPoint("BOTTOMLEFT", vQueueFrame.catList, "BOTTOMRIGHT", -16, 16)
		scrollbarCat:SetScript("OnValueChanged",
		function (self, value)
			for k, v in pairs(catListButtons) do
				if tonumber(k)+1 < this:GetValue() or ( (v:GetTextHeight()*k) + (2*k)) > (this:GetHeight()+(this:GetValue()*(v:GetTextHeight()) + 6))  then
					if not setContains(catListHidden, tostring(k)) then
						addToSet(catListHidden, tostring(k))
					end
				else
					if setContains(catListHidden, tostring(k)) then
						removeFromSet(catListHidden, tostring(k))
					end
				end
			end
			scrollbarCat:SetMinMaxValues(1, tablelength(catListButtons))
			vQueueFrame.catList:Hide()
			vQueueFrame.catList:Show()
		end)
		local scrollbgCat = scrollbarCat:CreateTexture(nil, "OVERLAY")
		scrollbgCat:SetAllPoints(scrollbarCat)
		scrollbgCat:SetTexture(0, 0, 0, 0.3)
		scrollbarCat:Hide()
		
		
		vQueueFrame.title = CreateFrame("Button", "vQueueButton", vQueueFrame.hostlist)
		vQueueFrame.title:ClearAllPoints()
		vQueueFrame.title:SetPoint("CENTER", vQueueFrame.hostlist, "TOP", 0 , 8)
		vQueueFrame.title:SetFont("Fonts\\FRIZQT__.TTF", 10)
		vQueueFrame.title:SetText("vQueue v0.0 - ayy")
		vQueueFrame.title:SetTextColor(209/255, 164/255, 29/255)
		vQueueFrame.title:SetPushedTextOffset(0,0)
		vQueueFrame.title:SetWidth(20)
		vQueueFrame.title:SetHeight(20)
		
		vQueueFrame.titleCat = CreateFrame("Button", "vQueueButton", vQueueFrame.catList)
		vQueueFrame.titleCat:ClearAllPoints()
		vQueueFrame.titleCat:SetPoint("CENTER", vQueueFrame.catList, "TOP", 0 , 8)
		vQueueFrame.titleCat:SetFont("Fonts\\FRIZQT__.TTF", 10)
		vQueueFrame.titleCat:SetText("Categories")
		vQueueFrame.titleCat:SetTextColor(209/255, 164/255, 29/255)
		vQueueFrame.titleCat:SetPushedTextOffset(0,0)
		vQueueFrame.titleCat:SetWidth(20)
		vQueueFrame.titleCat:SetHeight(20)
		
		
		local MinimapPos = -30
		DEFAULT_CHAT_FRAME:AddMessage("Loaded " .. arg1)
		minimapButton = CreateFrame("Button", "vQueueMap", Minimap)
		minimapButton:SetFrameStrata("HIGH")
		minimapButton:SetWidth(20)
		minimapButton:SetHeight(20)
		minimapButton:ClearAllPoints()
		minimapButton:SetPoint("TOPLEFT", Minimap,"TOPLEFT",52-(75*cos(MinimapPos)),(75*sin(MinimapPos))-52) 
		minimapButton.texture = minimapButton:CreateTexture(nil, "BUTTON")
		minimapButton.texture:SetTexture(1, 1, 1, 1)
		minimapButton.texture:ClearAllPoints()
		minimapButton.texture:SetPoint("CENTER", minimapButton, "CENTER")
		minimapButton.texture:SetWidth(minimapButton:GetWidth())
		minimapButton.texture:SetHeight(minimapButton:GetHeight())
		
		vQueueFrame.topsectiontitle = CreateFrame("Button", "vQueueButton", vQueueFrame.hostlistTopSection)
		vQueueFrame.topsectiontitle:ClearAllPoints()
		vQueueFrame.topsectiontitle:SetPoint("LEFT", vQueueFrame.hostlistTopSection, "LEFT", 5, vQueueFrame.hostlistTopSection:GetHeight() * 1/6)
		vQueueFrame.topsectiontitle:SetFont("Fonts\\MORPHEUS.ttf", 24, "OUTLINE")
		vQueueFrame.topsectiontitle:SetText("<-- Select a catergory")
		vQueueFrame.topsectiontitle:SetTextColor(247/255, 235/255, 233/255)
		vQueueFrame.topsectiontitle:SetPushedTextOffset(0,0)
		vQueueFrame.topsectiontitle:EnableMouse(false)
		vQueueFrame.topsectiontitle:SetWidth(vQueueFrame.topsectiontitle:GetTextWidth())
		vQueueFrame.topsectiontitle:SetHeight(vQueueFrame.topsectiontitle:GetTextHeight())
		vQueueFrame.catList:SetScript("OnShow", function(self)
			for k, v in ipairs(catListButtons) do
				if setContains(catListHidden, "0") then
					catListButtons[0]:Hide()
				else
					catListButtons[0]:Show()
				end
				if setContains(catListHidden, tostring(k)) then
					catListButtons[k]:Hide()
				else
					catListButtons[k]:Show()
				end
			end
			local yPosition = 0
			for key, value in pairs(categories) do
				local frameExists = false
				local textKey = key
				for k, v in pairs(catListButtons)  do
					if string.sub(v:GetText(), 3, -1) == key then
						frameExists = true
					end
				end
				if not frameExists then
					catListButtons[tablelength(catListButtons)] = CreateFrame("Button", "vQueueButton", vQueueFrame.catList)
					catListButtons[tablelength(catListButtons)-1]:SetFont("Fonts\\FRIZQT__.TTF", 10)
					catListButtons[tablelength(catListButtons)-1]:SetText("+ " .. textKey)
					catListButtons[tablelength(catListButtons)-1]:SetTextColor(209/255, 164/255, 29/255)
					catListButtons[tablelength(catListButtons)-1]:SetHighlightTextColor(1,1,0)
					catListButtons[tablelength(catListButtons)-1]:SetPushedTextOffset(0,0)
					catListButtons[tablelength(catListButtons)-1]:SetWidth(catListButtons[tablelength(catListButtons)-1]:GetTextWidth())
					catListButtons[tablelength(catListButtons)-1]:SetHeight(10)
					catListButtons[tablelength(catListButtons)-1]:SetFrameLevel(1)
					catListButtons[tablelength(catListButtons)-1]:SetPoint("RIGHT", vQueueFrame.catList, "TOPLEFT",  round(catListButtons[tablelength(catListButtons)-1]:GetTextWidth()), -(yPosition*10))
					catListButtons[tablelength(catListButtons)-1]:SetScript("OnMouseDown", function(self, button)
						local keyPressed = string.sub(this:GetText(), 3, -1)
						if not categories[keyPressed][0] then
							this:SetText("- " .. keyPressed)
							categories[keyPressed][0] = true
						else
							this:SetText("+ " .. keyPressed)
							categories[keyPressed][0] = false
							for k, v in pairs(catListButtons) do
								local deletingIndex = -1
								if this:GetText() == v:GetText() then
									deletingIndex = tablelength(categories[string.sub(v:GetText(), 3, -1)]) - 2
								end
								for i = deletingIndex, 1, -1 do
									catListButtons[k+1]:Hide()
									table.remove(catListButtons, k+1)
								end
							end
						end
						local prevVal = scrollbarCat:GetValue()
						scrollbarCat:SetValue(prevVal+1)
						scrollbarCat:SetValue(prevVal)
						vQueueFrame.catList:Hide()
						vQueueFrame.catList:Show()
					end)
					yPosition = yPosition + 1
				end
				
				if categories[key][0] then
					for keyy, valuee in pairs(categories[key]) do
						local args = {}
						if type(valuee) == "string" then
							args = split(valuee, "\:")	
						end
						local frameExistss = false
						for k, v in pairs(catListButtons)  do
							if v:GetText() == args[1] then
								frameExistss = true
							end
						end
						if type(args[1]) == "string" and not frameExistss then
							local dropedItemFrame = CreateFrame("Button", "vQueueButton", vQueueFrame.catList)
							dropedItemFrame:SetFont("Fonts\\FRIZQT__.TTF", 8)
							dropedItemFrame:SetText(args[1])
							dropedItemFrame:SetTextColor(204/255, 159/255, 24/255)
							dropedItemFrame:SetHighlightTextColor(1,1,0)
							--dropedItemFrame:SetPushedTextOffset(1,1)
							dropedItemFrame:SetWidth(dropedItemFrame:GetTextWidth())
							dropedItemFrame:SetHeight(8)
							dropedItemFrame:SetFrameLevel(1)
							dropedItemFrame:SetPoint("RIGHT", vQueueFrame.catList, "TOPLEFT",  round(dropedItemFrame:GetTextWidth() + 10), -(tablelength(catListButtons)*10))
							dropedItemFrame:SetScript("OnMouseDown", function()
								if isHost then
									vQueueFrame.hostlistRoleText:SetText("(Disband group before selecting a category)")
									return
								end
								local args = {}
								for k, v in pairs(categories) do
									for i, item in v do
										if type(item) == "string" then
											local tArgs = split(item, "\:")
											if tArgs[1] == this:GetText() then 
												args = tArgs
												break
											end
										end
									end
								end
								if args[2] ~= nil and type(args[2]) == "string" then
									selectedQuery = args[2]
									vQueueFrame.topsectiontitle:SetText(args[1])
									vQueueFrame.topsectiontitle:SetWidth(vQueueFrame.topsectiontitle:GetTextWidth())
									vQueueFrame.topsectiontitle:SetHeight(vQueueFrame.topsectiontitle:GetTextHeight())
								end
								--vQueueFrame.hostlistTopSectionBg:SetTexture(0.3, 0.3, 0.3, 0.3)
								if not vQueueFrame.hostlistTopSectionBg:SetTexture("Interface\\AddOns\\vQueue\\" .. args[2]) then
									vQueueFrame.hostlistTopSectionBg:SetTexture(0, 0, 0, 0)
								end
								vQueueFrame.hostlistHeal:Show()
								vQueueFrame.hostlistDps:Show()
								vQueueFrame.hostlistTank:Show()
								vQueueFrame.hostlistRoleText:Show()
								vQueueFrame.hostlist:Hide()
								vQueueFrame.hostlist:Show()
							end)
							local tablePos = 0
							for k, v in pairs(catListButtons) do
								if string.sub(v:GetText(), 3, -1) == key then
									tablePos = k
								end
							end
							table.insert(catListButtons, tablePos+1, dropedItemFrame)
						end
					end
				end
				point, relativeTo, relativePoint, xOffset, yOffset = catListButtons[0]:GetPoint(1)
				catListButtons[0]:SetPoint("RIGHT", vQueueFrame.catList, "TOPLEFT",  xOffset, -((1)*10))
				if catListButtons[0]:IsShown() then yPosition = 1
				else yPosition = 0
				end
				for k, v in ipairs(catListButtons) do
					if v:IsShown() then
						point, relativeTo, relativePoint, xOffset, yOffset = v:GetPoint(1)
						v:ClearAllPoints()
						v:SetPoint("RIGHT", vQueueFrame.catList, "TOPLEFT",  xOffset, -((yPosition+1)*10))
						yPosition = yPosition + 1
					end
				end
			end
		end)

		
		minimapButton:SetScript("OnMouseDown", function(self, button)
			if vQueueFrameShown then 
				vQueueFrame:Hide() 
				vQueueFrame.catList:Hide()
				vQueueFrame.hostlist:Hide()
				vQueueFrameShown = false
			else
				vQueueFrame:Show() 
				vQueueFrame.catList:Show()
				vQueueFrame.hostlist:Show()
				vQueueFrameShown = true
			end
			minimapButton.texture:SetTexture(0, 0, 0, 1)
		end);
		minimapButton:SetScript("OnMouseUp", function(self, button)
			minimapButton.texture:SetTexture(1, 1, 1, 1)
		end);
		
		
		minimapButton:Show()
		vQueueFrame:Hide()
		vQueueFrame.catList:Hide()
		vQueueFrame.hostlist:Hide()
		vQueueFrame.hostlistHostButton:Hide()
		vQueueFrame.hostlistFindButton:Hide()
		vQueueFrame.hostlistTank:Hide()
		vQueueFrame.hostlistHeal:Hide()
		vQueueFrame.hostlistDps:Hide()
		vQueueFrame.hostlistRoleText:Hide()
		vQueueFrame.hostlistLevelField:Hide()
		vQueueFrame.hostlistNameField:Hide()
		vQueueFrame.hostlistCreateButton:Hide()
	end
	if event == "CHAT_MSG_CHANNEL" then
		DEFAULT_CHAT_FRAME:AddMessage(arg9 .. ":" .. channelName)
		if arg9 == channelName then
			local vQueueArgs = {}
			if arg1 ~= nil then
				vQueueArgs = split(arg1, "\%s")
			end
			DEFAULT_CHAT_FRAME:AddMessage(vQueueArgs[1] .. " : " .. vQueueArgs[2])
			if vQueueArgs[1] == "lfg" and vQueueArgs[2] ~= nil and UnitName("player") ~= arg2 then
				DEFAULT_CHAT_FRAME:AddMessage("added1")
				if hostedCategory == vQueueArgs[2] and not setContains(hostWhisperQueue, arg2) and not setContains(playersQueued, arg2) then
					DEFAULT_CHAT_FRAME:AddMessage("added2")
					addToSet(hostWhisperQueue, arg2)
				end
			end		
		end
	end
	
	if event == "CHAT_MSG_WHISPER" then
		local args = {}
		if arg1 ~= nil then
			args = split(arg1, "\%s")
		end
		if next(args) == nil then return end
		-- Group info whispers from hosts
		if args[1] == "vqgroup" and args[2] ~= nil then
			local name = split(arg1, "\:")
			local healerRole = ""
			local damageRole = ""
			local tankRole = ""
			if args[4] == "true" then
				healerRole = "Healer"
			end
			if args[5] == "true" then
				damageRole = "Damage"
			end
			if args[6] == "true" then
			 tankRole = "Tank"
			end
			table.insert(groups[args[2]], tablelength(groups[args[2]]), name[2] .. ":" .. arg2 .. ":" .. args[3] .. ":" .. "Role " .. healerRole .. " " .. damageRole .. " " .. tankRole)
			hostListFrame:Hide()
			hostListFrame:Show()
		end
		-- Group request info from players
		if args[1] == "vqrequest" and isHost then
			if not setContains(playersQueued, arg2 .. ":" .. args[2] .. ":" .. args[3] .. ":" .. args[4]) then
				addToSet(playersQueued, arg2 .. ":" .. args[2] .. ":" .. args[3] .. ":" .. args[4])
				hostListFrame:Hide()
				hostListFrame:Show()
			end
		end
	end
end


function vQueue_SlashCommandHandler( msg )
	local args = {}
	if msg ~= nil then
		args = split(msg, "\%s")
	end
	if args[1] == "host" and args[2] ~= nil then
		isHost = true
		hostedCategory = args[2]
		DEFAULT_CHAT_FRAME:AddMessage("Now hosting for " .. hostedCategory)
	elseif args[1] == "lfg" and args[2] ~= nil then
		if not setContains(chatQueue, args[2]) then
			addToSet(chatQueue, "lfg " .. args[2])
		end
	elseif args[1] == "list" then
		for category,value in pairs(groups) do 
			for hostname,valuee in pairs(value) do 
			end
		end
	elseif args[1] == "request" and args[2] ~= nil then
		if not setContains(requestWhisperQueue, args[2]) then
			addToSet(requestWhisperQueue, args[2])
		end
	end
end

local lastUpdate = 0

function vQueue_OnUpdate()
	local elapsed = GetTime() - startTime
	startTime = GetTime()
	
	-- CHAT LIMITER
	if(chatRate > 0) then
		lastUpdate = lastUpdate + elapsed
		-- MESSAGES TO SEND GO HERE
		if (lastUpdate > (1/chatRate)) then
			--Messages to chat channel for lfg
			if next(chatQueue) ~= nil then
				for key,value in pairs(chatQueue) do 
					SendChatMessage(key , "CHANNEL", nil , tostring(GetChannelName(channelName)));
					removeFromSet(chatQueue, key)
				end
			--host whispers to players lfg
			elseif next(hostWhisperQueue) ~= nil and isHost then
				for key,value in pairs(hostWhisperQueue) do 
					DEFAULT_CHAT_FRAME:AddMessage("whisp")
					SendChatMessage("vqgroup " .. hostedCategory .. " " .. tostring(hostOptions[1]) .. " " .. tostring(hostOptions[2]) .. " " .. tostring(hostOptions[3]) .. " " .. tostring(hostOptions[4]) .. " :" .. tostring(hostOptions[0]), "WHISPER", nil , key);
					removeFromSet(hostWhisperQueue, key)
				end
			--request whispers to host
			--TODO ADD PLAYER INFO TO REQUESTS
			elseif next(requestWhisperQueue) ~= nil then
				for key,value in pairs(requestWhisperQueue) do 
					SendChatMessage("vqrequest " .. UnitLevel("player") .. " " .. UnitClass("player") .. " " .. selectedRole, "WHISPER", nil , key);
					removeFromSet(requestWhisperQueue, key)
				end
			end
			lastUpdate = 0
		end
	end
	elapsed = 0
end

SlashCmdList["vQueue"] = vQueue_SlashCommandHandler
SLASH_vQueue1 = "/vQueue"local chatRate = 3 -- limit to 3 msg/secS