local chatRate = 2 -- limit to 3 msg/sec
local startTime = 0 -- used to get elapsed in onupdate
local channelName = "vQueue"
local filterEnabled = true -- chat filter

local isHost = false
local hostedCategory = ""
local realHostedCategory = ""
local playersQueued = {}
local chatQueue = {}
local groups = {}

local vQueueFrame = {}
local catListButtons = {}
local vQueueFrameShown = false
local selectedQuery = ""
local isWaitListShown = false

local categories = {}
local hostListButtons = {}
local hostListFrame
local categoryListFrame
local infoFrame = {}
local catListHidden = {}
local catListHiddenBot = {}
local waitingList = {}
local realScroll = false
local recentList = {}
local blackList = {}
local findTimer = 0
local miniDrag = false
local leaderMessages = {}
local playerMessages = {}
local whoRequestList = {}
local newGroups = {}

local tankSelected = false
local healerSelected = false
local damageSelected = false

local hostOptions = {}

vQueue = AceLibrary("AceAddon-2.0"):new("AceHook-2.1")

function Wholefind(Search_string, Word)
 _, F_result = string.gsub(Search_string, '%f[%a]'..Word..'%f[%A]',"")
 return F_result
end

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
	local channelId = GetChannelName(channelName)
	local blockMsg = false
	if vQueueOptions["filter"] then
		if not vQueueOptions["onlylfg"] then
			if vQueueOptions["general"] and (strfind(tostring(text), "%[" .. tostring(GetChannelName("General - " .. GetRealZoneText()))) and strfind(tostring(text), "%]") ) and GetChannelName("General - " .. GetRealZoneText()) ~= 0 then blockMsg = true end
			if vQueueOptions["trade"] and (strfind(tostring(text), "%[" .. tostring(GetChannelName("Trade - City"))) and strfind(tostring(text), "%]") ) and GetChannelName("Trade - City") ~= 0 then blockMsg = true end
			if vQueueOptions["lfg"] and (strfind(tostring(text), "%[" .. tostring(GetChannelName("LookingForGroup"))) and strfind(tostring(text), "%]") ) and GetChannelName("LookingForGroup") ~= 0 then blockMsg = true end
			if vQueueOptions["world"] and (strfind(tostring(text), "%[" .. tostring(GetChannelName("world"))) and strfind(tostring(text), "%]") ) and GetChannelName("world") ~= 0 then blockMsg = true end
		elseif vQueueOptions["onlylfg"] then
			local foundArg = false
			local noPunc = filterPunctuation(tostring(text))
			for k, v in pairs(getglobal("LFMARGS")) do
				if Wholefind(noPunc, v) > 0 then foundArg = true end
			end
			for k, v in pairs(getglobal("LFGARGS")) do
				if Wholefind(noPunc, v) > 0 then foundArg = true end
			end
			if foundArg then
				if vQueueOptions["general"] and (strfind(tostring(text), "%[" .. tostring(GetChannelName("General - " .. GetRealZoneText()))) and strfind(tostring(text), "%]") ) and GetChannelName("General - " .. GetRealZoneText()) ~= 0 then blockMsg = true end
				if vQueueOptions["trade"] and (strfind(tostring(text), "%[" .. tostring(GetChannelName("Trade - City"))) and strfind(tostring(text), "%]") ) and GetChannelName("Trade - City") ~= 0 then blockMsg = true end
				if vQueueOptions["lfg"] and (strfind(tostring(text), "%[" .. tostring(GetChannelName("LookingForGroup"))) and strfind(tostring(text), "%]") ) and GetChannelName("LookingForGroup") ~= 0 then blockMsg = true end
				if vQueueOptions["world"] and (strfind(tostring(text), "%[" .. tostring(GetChannelName("world"))) and strfind(tostring(text), "%]") ) and GetChannelName("world") ~= 0 then blockMsg = true end
			end
		end
	end
	if tonumber(channelId) < 1 then
		channelId = "vqueuenochannel"
	end
	if ((strfind(tostring(text), "%[" .. tostring(channelId)) and strfind(tostring(text),"]")) or Wholefind(tostring(text), "vqgroup") > 0 or Wholefind(tostring(text), "vqrequest") > 0 or Wholefind(tostring(text), "vqaccept") > 0 or Wholefind(tostring(text), "vqdecline") > 0 or Wholefind(tostring(text), "vqremove") > 0) and filterEnabled then
		blockMsg = true
	end
	if not blockMsg then
		self.hooks[frame].AddMessage(frame, string.format("%s", text), r, g, b, id)
	end
end

function vQueue_OnLoad()
	this:RegisterEvent("ADDON_LOADED");
	this:RegisterEvent("CHAT_MSG_CHANNEL");
	this:RegisterEvent("CHAT_MSG_WHISPER");
	this:RegisterEvent("WHO_LIST_UPDATE");
end

function filterPunctuation( s )
	s = string.lower(s)
	local newString = ""
	for i = 1, string.len(s) do
		if string.find(string.sub(s, i, i), "%p") ~= nil then
			newString = newString .. " "
		elseif string.find(string.sub(s, i, i), "%d") ~= nil then
			--nothing needed here
		else
			newString = newString .. string.sub(s, i, i)
		end
	end
	return newString
end

function vQueue_OnEvent(event)
	if event == "ADDON_LOADED" and arg1 == "vQueue" then
		findTimer = GetTime() - 10
		if MinimapPos == nil then
			MinimapPos = -30
		end
		if vQueueOptions == nil then
			vQueueOptions = {}
		end
		if vQueueOptions["filter"] == nil then
			vQueueOptions["filter"] = false
		end
		if vQueueOptions["general"] == nil then
			vQueueOptions["general"] = true
		end
		if vQueueOptions["trade"] == nil then
			vQueueOptions["trade"] = true
		end
		if vQueueOptions["lfg"] == nil then
			vQueueOptions["lfg"] = true
		end
		if vQueueOptions["world"] == nil then
			vQueueOptions["world"] = true
		end
		if vQueueOptions["onlylfg"] == nil then
			vQueueOptions["onlylfg"] = true
		end
		if selectedRole ==  nil then selectedRole = "" end
		if isFinding == nil then isFinding = true end
		categories["Miscellaneous"] =
		{
			expanded = false,
			"Misc:misc"
		}
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
		categories["Quest Groups"] =
		{
			expanded = false,
			"Quests 1-10:quest110",
			"Quests 10-20:quest1020",
			"Quests 20-30:quest2030",
			"Quests 30-40:quest3040",
			"Quests 40-50:quest4050",
			"Quests 50-60:quest5060"
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
		local vQueueFrameBackdrop = {
		  -- path to the background texture
		  bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",  
		  -- path to the border texture
		  edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		  -- true to repeat the background texture to fill the frame, false to scale it
		  tile = true,
		  -- size (width or height) of the square repeating background tiles (in pixels)
		  tileSize = 32,
		  -- thickness of edge segments and square size of edge corners (in pixels)
		  edgeSize = 24,
		  -- distance from the edges of the frame to those of the background texture (in pixels)
		  insets = {
			left = 9,
			right = 9,
			top = 9,
			bottom = 9
		  }
		}
		vQueueFrame = CreateFrame("Frame", UIParent)
		vQueueFrame:SetWidth(594)
		vQueueFrame:SetHeight(367)
		vQueueFrame:ClearAllPoints()
		vQueueFrame:SetPoint("CENTER", UIParent,"CENTER") 
		vQueueFrame:SetMovable(true)
		vQueueFrame:EnableMouse(true)
		--vQueueFrame:SetBackdrop(vQueueFrameBackdrop)
		--vQueueFrame:SetBackdropColor(1, 1, 1, 1)
		vQueueFrame:SetScript("OnMouseDown", function(self, button)
			vQueueFrame:StartMoving()
			vQueueFrame.hostlistNameField:ClearFocus()
			vQueueFrame.hostlistLevelField:ClearFocus()
			if isHost or isFinding then
				vQueueFrame.hostlistRoleText:SetText("")
			end
		end)
		vQueueFrame:SetScript("OnMouseUp", function(self, button)
			vQueueFrame:StopMovingOrSizing()
		end)
		vQueueFrame:SetScript("OnHide", function()
			vQueueFrame.catList:Hide()
			vQueueFrame.hostlist:Hide()
		end)
		vQueueFrame.closeButton = CreateFrame("Button", nil, vQueueFrame, "UIPanelButtonTemplate")
		vQueueFrame.closeButton:SetPoint("TOPRIGHT", vQueueFrame, "TOPRIGHT", -3, 0)
		vQueueFrame.closeButton:SetFont("Fonts\\FRIZQT__.TTF", 10)
		vQueueFrame.closeButton:SetText("X")
		vQueueFrame.closeButton:SetTextColor(209/255, 164/255, 29/255)
		vQueueFrame.closeButton:SetButtonState("NORMAL", true)
		vQueueFrame.closeButton:SetWidth(vQueueFrame.closeButton:GetTextWidth()+3)
		vQueueFrame.closeButton:SetHeight(vQueueFrame.closeButton:GetTextHeight()+3)
		vQueueFrame.closeButton:SetScript("OnMouseDown", function()
			vQueueFrame:Hide()
			vQueueFrame.catList:Hide()
			vQueueFrame.hostlist:Hide()
			vQueueFrameShown = false
		end)
		vQueueFrame.optionsButton = CreateFrame("Button", nil, vQueueFrame)
		vQueueFrame.optionsButton:SetPoint("TOPLEFT", vQueueFrame, "TOPLEFT", 4, 0)
		vQueueFrame.optionsButton:SetButtonState("NORMAL", true)
		vQueueFrame.optionsButton:SetWidth(13)
		vQueueFrame.optionsButton:SetHeight(13)
		vQueueFrame.optionsButton:SetScript("OnMouseDown", function()
			if vQueueFrame.optionsFrame:IsShown() then
				vQueueFrame.optionsFrame:Hide()
			else
				vQueueFrame.optionsFrame:Show()
			end
		end)
		vQueueFrame.optionsButton:SetScript("OnEnter", function()
			vQueueFrame.optionsButtonIcon:SetDesaturated(false)
		end)
		vQueueFrame.optionsButton:SetScript("OnLeave", function()
			vQueueFrame.optionsButtonIcon:SetDesaturated(true)
		end)
		vQueueFrame.optionsButtonIcon = vQueueFrame.optionsButton:CreateTexture(nil, "ARTWORK")
		vQueueFrame.optionsButtonIcon:SetTexture("Interface\\ICONS\\INV_Misc_Gear_01")
		vQueueFrame.optionsButtonIcon:SetDesaturated(true)
		vQueueFrame.optionsButtonIcon:SetVertexColor(0.8, 0.8, 0, 1)
		vQueueFrame.optionsButtonIcon:SetAllPoints()
		
		
		vQueueFrame.texture = vQueueFrame:CreateTexture(nil, "BACKGROUND")
		vQueueFrame.texture:SetVertexColor(0.2, 0.2, 0.2, 1)
		vQueueFrame.texture:ClearAllPoints()
		vQueueFrame.texture:SetPoint("CENTER", vQueueFrame, "CENTER")
		vQueueFrame.texture:SetWidth(vQueueFrame:GetWidth())
		vQueueFrame.texture:SetHeight(vQueueFrame:GetHeight())
		vQueueFrame.texture:SetTexture(48/255, 38/255, 28/255, 0.8)
		
		vQueueFrame.borderLeft = vQueueFrame:CreateTexture(nil, "BORDER")
		vQueueFrame.borderLeft:SetTexture("Interface\\AddOns\\vQueue\\media\\ThinBorder-Left")
		vQueueFrame.borderLeft:ClearAllPoints()
		vQueueFrame.borderLeft:SetPoint("LEFT", vQueueFrame, "LEFT", -5, -0.5)
		vQueueFrame.borderLeft:SetWidth(20)
		vQueueFrame.borderLeft:SetHeight(vQueueFrame:GetHeight()-31)
		
		vQueueFrame.borderRight = vQueueFrame:CreateTexture(nil, "BORDER")
		vQueueFrame.borderRight:SetTexture("Interface\\AddOns\\vQueue\\media\\ThinBorder-Right")
		vQueueFrame.borderRight:ClearAllPoints()
		vQueueFrame.borderRight:SetPoint("RIGHT", vQueueFrame, "RIGHT", 5, -0.5)
		vQueueFrame.borderRight:SetWidth(20)
		vQueueFrame.borderRight:SetHeight(vQueueFrame:GetHeight()-31)
		
		vQueueFrame.borderBot = vQueueFrame:CreateTexture(nil, "BORDER")
		vQueueFrame.borderBot:SetTexture("Interface\\AddOns\\vQueue\\media\\ThinBorder-Bottom")
		vQueueFrame.borderBot:ClearAllPoints()
		vQueueFrame.borderBot:SetPoint("BOTTOM", vQueueFrame, "BOTTOM", -0.5, -5)
		vQueueFrame.borderBot:SetWidth(vQueueFrame:GetWidth()-31.5)
		vQueueFrame.borderBot:SetHeight(20)
		
		vQueueFrame.borderTop = vQueueFrame:CreateTexture(nil, "BORDER")
		vQueueFrame.borderTop:SetTexture("Interface\\AddOns\\vQueue\\media\\ThinBorder-Top")
		vQueueFrame.borderTop:ClearAllPoints()
		vQueueFrame.borderTop:SetPoint("TOP", vQueueFrame, "TOP", 0, 4)
		vQueueFrame.borderTop:SetWidth(vQueueFrame:GetWidth()-30)
		vQueueFrame.borderTop:SetHeight(20)
		
		vQueueFrame.borderTopLeft = vQueueFrame:CreateTexture(nil, "BORDER")
		vQueueFrame.borderTopLeft:SetTexture("Interface\\AddOns\\vQueue\\media\\ThinBorder-TopLeft")
		vQueueFrame.borderTopLeft:ClearAllPoints()
		vQueueFrame.borderTopLeft:SetVertexColor(1, 1, 1, 1)
		vQueueFrame.borderTopLeft:SetPoint("TOPLEFT", vQueueFrame, "TOPLEFT", -5, 4)
		vQueueFrame.borderTopLeft:SetWidth(20)
		vQueueFrame.borderTopLeft:SetHeight(20)
		
		vQueueFrame.borderTopRight = vQueueFrame:CreateTexture(nil, "BORDER")
		vQueueFrame.borderTopRight:SetTexture("Interface\\AddOns\\vQueue\\media\\ThinBorder-TopRight")
		vQueueFrame.borderTopRight:ClearAllPoints()
		vQueueFrame.borderTopRight:SetVertexColor(1, 1, 1, 1)
		vQueueFrame.borderTopRight:SetPoint("TOPRIGHT", vQueueFrame, "TOPRIGHT", 5, 4)
		vQueueFrame.borderTopRight:SetWidth(20)
		vQueueFrame.borderTopRight:SetHeight(20)
		
		vQueueFrame.borderBottomLeft = vQueueFrame:CreateTexture(nil, "BORDER")
		vQueueFrame.borderBottomLeft:SetTexture("Interface\\AddOns\\vQueue\\media\\ThinBorder-BottomLeft")
		vQueueFrame.borderBottomLeft:ClearAllPoints()
		vQueueFrame.borderBottomLeft:SetVertexColor(1, 1, 1, 1)
		vQueueFrame.borderBottomLeft:SetPoint("BOTTOMLEFT", vQueueFrame, "BOTTOMLEFT", -5, -5)
		vQueueFrame.borderBottomLeft:SetWidth(20)
		vQueueFrame.borderBottomLeft:SetHeight(20)
		
		vQueueFrame.borderBottomRight = vQueueFrame:CreateTexture(nil, "BORDER")
		vQueueFrame.borderBottomRight:SetTexture("Interface\\AddOns\\vQueue\\media\\ThinBorder-BottomRight")
		vQueueFrame.borderBottomRight:ClearAllPoints()
		vQueueFrame.borderBottomRight:SetVertexColor(1, 1, 1, 1)
		vQueueFrame.borderBottomRight:SetPoint("BOTTOMRIGHT", vQueueFrame, "BOTTOMRIGHT", 3.75, -5)
		vQueueFrame.borderBottomRight:SetWidth(20)
		vQueueFrame.borderBottomRight:SetHeight(20)
		
		vQueueFrame.catList = CreateFrame("ScrollFrame", vQueueFrame)
		vQueueFrame.catList:ClearAllPoints()
		vQueueFrame.catList:SetPoint("LEFT", vQueueFrame, "LEFT", 5, -5)
		vQueueFrame.catList:SetWidth(vQueueFrame:GetWidth() * 1/5)
		vQueueFrame.catList:SetHeight(vQueueFrame:GetHeight() - (vQueueFrame:GetHeight()*0.05))
		vQueueFrame.catList:EnableMouseWheel(true)
		vQueueFrame.catList:SetScript("OnMouseWheel", function()
			if arg1 == 1 then
				scrollbarCat:SetValue(scrollbarCat:GetValue()-1)
			elseif arg1 == -1 then
				scrollbarCat:SetValue(scrollbarCat:GetValue()+1)
			end
			realScroll = true
		end)
		
		vQueueFrame.catListBg = vQueueFrame.catList:CreateTexture(nil, "BACKGROUND")
		vQueueFrame.catListBg:ClearAllPoints()
		vQueueFrame.catListBg:SetVertexColor(1, 1, 1, 1)
		vQueueFrame.catListBg:SetPoint("CENTER", vQueueFrame.catList, "CENTER")
		vQueueFrame.catListBg:SetWidth(vQueueFrame.catList:GetWidth())
		vQueueFrame.catListBg:SetHeight(vQueueFrame.catList:GetHeight())
		vQueueFrame.catListBg:SetTexture(11/255, 11/255, 11/255, 0.8)
		
		vQueueFrame.catListborderLeft = vQueueFrame.catList:CreateTexture(nil, "BORDER")
		vQueueFrame.catListborderLeft:SetTexture("Interface\\AddOns\\vQueue\\media\\ThinBorder-Left")
		vQueueFrame.catListborderLeft:ClearAllPoints()
		vQueueFrame.catListborderLeft:SetPoint("LEFT", vQueueFrame.catList, "LEFT", -2, 0)
		vQueueFrame.catListborderLeft:SetWidth(10)
		vQueueFrame.catListborderLeft:SetHeight(vQueueFrame.catList:GetHeight()-13)
		
		vQueueFrame.catListborderRight = vQueueFrame.catList:CreateTexture(nil, "BORDER")
		vQueueFrame.catListborderRight:SetTexture("Interface\\AddOns\\vQueue\\media\\ThinBorder-Right")
		vQueueFrame.catListborderRight:ClearAllPoints()
		vQueueFrame.catListborderRight:SetPoint("RIGHT", vQueueFrame.catList, "RIGHT", 3, 0)
		vQueueFrame.catListborderRight:SetWidth(10)
		vQueueFrame.catListborderRight:SetHeight(vQueueFrame.catList:GetHeight()-13)
		
		vQueueFrame.catListborderTop = vQueueFrame.catList:CreateTexture(nil, "BORDER")
		vQueueFrame.catListborderTop:SetTexture("Interface\\AddOns\\vQueue\\media\\ThinBorder-Top")
		vQueueFrame.catListborderTop:ClearAllPoints()
		vQueueFrame.catListborderTop:SetPoint("TOP", vQueueFrame.catList, "TOP", 0, 2)
		vQueueFrame.catListborderTop:SetWidth(vQueueFrame.catList:GetWidth() - 13)
		vQueueFrame.catListborderTop:SetHeight(10)
		
		vQueueFrame.catListborderBot = vQueueFrame.catList:CreateTexture(nil, "BORDER")
		vQueueFrame.catListborderBot:SetTexture("Interface\\AddOns\\vQueue\\media\\ThinBorder-Bottom")
		vQueueFrame.catListborderBot:ClearAllPoints()
		vQueueFrame.catListborderBot:SetPoint("BOTTOM", vQueueFrame.catList, "BOTTOM", 0, -2)
		vQueueFrame.catListborderBot:SetWidth(vQueueFrame.catList:GetWidth() - 13)
		vQueueFrame.catListborderBot:SetHeight(10)
		
		vQueueFrame.catListborderTopRight = vQueueFrame.catList:CreateTexture(nil, "BORDER")
		vQueueFrame.catListborderTopRight:SetTexture("Interface\\AddOns\\vQueue\\media\\ThinBorder-TopRight")
		vQueueFrame.catListborderTopRight:ClearAllPoints()
		vQueueFrame.catListborderTopRight:SetPoint("TOPRIGHT", vQueueFrame.catList, "TOPRIGHT", 3, 2)
		vQueueFrame.catListborderTopRight:SetWidth(10)
		vQueueFrame.catListborderTopRight:SetHeight(10)
		
		vQueueFrame.catListborderTopLeft = vQueueFrame.catList:CreateTexture(nil, "BORDER")
		vQueueFrame.catListborderTopLeft:SetTexture("Interface\\AddOns\\vQueue\\media\\ThinBorder-TopLeft")
		vQueueFrame.catListborderTopLeft:ClearAllPoints()
		vQueueFrame.catListborderTopLeft:SetPoint("TOPLEFT", vQueueFrame.catList, "TOPLEFT", -2, 2)
		vQueueFrame.catListborderTopLeft:SetWidth(10)
		vQueueFrame.catListborderTopLeft:SetHeight(10)
		
		vQueueFrame.catListborderBotRight = vQueueFrame.catList:CreateTexture(nil, "BORDER")
		vQueueFrame.catListborderBotRight:SetTexture("Interface\\AddOns\\vQueue\\media\\ThinBorder-BottomRight")
		vQueueFrame.catListborderBotRight:ClearAllPoints()
		vQueueFrame.catListborderBotRight:SetPoint("BOTTOMRIGHT", vQueueFrame.catList, "BOTTOMRIGHT", 2.4, -2)
		vQueueFrame.catListborderBotRight:SetWidth(10)
		vQueueFrame.catListborderBotRight:SetHeight(10)
		
		vQueueFrame.catListborderBotLeft = vQueueFrame.catList:CreateTexture(nil, "BORDER")
		vQueueFrame.catListborderBotLeft:SetTexture("Interface\\AddOns\\vQueue\\media\\ThinBorder-BottomLeft")
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
		CreateFrame( "GameTooltip", "groupToolTip", nil, "GameTooltipTemplate" ); -- Tooltip name cannot be nil
		CreateFrame( "GameTooltip", "playerQueueuToolTip", nil, "GameTooltipTemplate" ); -- Tooltip name cannot be nil
		vQueueFrame.hostlist:SetScript("OnShow", function(self, delta)
			vQueueFrame.hostTitleFindName:Hide()
			vQueueFrame.hostTitleFindLeader:Hide()
			vQueueFrame.hostTitleFindLevel:Hide()
			vQueueFrame.hostTitleFindSize:Hide()
			vQueueFrame.hostTitleFindRoles:Hide()
			vQueueFrame.hostTitleRole:Hide()
			vQueueFrame.hostTitleClass:Hide()
			vQueueFrame.hostTitle:Hide()
			vQueueFrame.hostTitleLevel:Hide()
			vQueueFrame.topsectionHostName:Hide()
			for k, v in pairs(hostListButtons) do
				v:Hide()
			end
			hostListButtons = {}
			if isFinding and not isWaitListShown then
				vQueueFrame.hostTitleFindName:Show()
				vQueueFrame.hostTitleFindLeader:Show()
				vQueueFrame.hostTitleFindLevel:Show()
				vQueueFrame.hostTitleFindSize:Show()
				vQueueFrame.hostTitleFindRoles:Show()
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
							hostListButtons[tablelength(hostListButtons)-1]:EnableMouse(true)
							if hostListButtons[tablelength(hostListButtons)-1]:GetTextWidth() > (vQueueFrame.hostlist:GetWidth()/2) then
								for i = 1, string.len(hostListButtons[tablelength(hostListButtons)-1]:GetTextWidth()) do
									hostListButtons[tablelength(hostListButtons)-1]:SetText(string.sub(hostListButtons[tablelength(hostListButtons)-1]:GetText(), 1, -2))
									if hostListButtons[tablelength(hostListButtons)-1]:GetTextWidth() < (vQueueFrame.hostlist:GetWidth()/2) then break end
								end
								hostListButtons[tablelength(hostListButtons)-1]:SetText(string.sub(hostListButtons[tablelength(hostListButtons)-1]:GetText(), 1, -5) .. "...")
								hostListButtons[tablelength(hostListButtons)-1]:SetWidth(hostListButtons[tablelength(hostListButtons)-1]:GetTextWidth())
							end
							hostListButtons[tablelength(hostListButtons)-1]:SetScript("OnEnter", function()
								local childs = this:GetChildren()
								if leaderMessages[childs:GetText()] ~= nil then
									local leaderargs = split(leaderMessages[childs:GetText()], "\:")
									groupToolTip:SetOwner( this, "ANCHOR_CURSOR" );
									groupToolTip:AddLine(leaderargs[1], 1, 1, 1, 1)
									groupToolTip:Show()
								end
							end)
							hostListButtons[tablelength(hostListButtons)-1]:SetScript("OnUpdate", function()
								local childs, lvel, size = this:GetChildren()
								if leaderMessages[childs:GetText()] ~= nil and size:GetText() == "?" then
									local timeSplit = split(leaderMessages[childs:GetText()], "\:")
									if type(tonumber(timeSplit[3])) == "number" then
										local minute = 0
										local seconds = math.floor(GetTime() - tonumber(timeSplit[3]))
										if seconds >= 60 then
											minute = math.floor(seconds/60)
											seconds = seconds - (minute*60)
										end
										if seconds < 10 then
											seconds = "0" .. tostring(seconds)
										end
										this:SetText("(Mouseover to see chat message) " .. tostring(minute) .. ":" .. tostring(seconds) )
										local point, relativeTo, relativePoint, xOffset, yOffset = this:GetPoint(1)
										this:SetWidth(this:GetTextWidth())
										this:SetPoint(point, relativeTo, relativePoint, round(this:GetTextWidth()), yOffset)
									end
								end
							end)
							hostListButtons[tablelength(hostListButtons)-1]:SetScript("OnLeave", function()
								groupToolTip:Hide()
							end)
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
								if (i ~= 1) then
									if type(tonumber(item)) == "number" and i == 3 then
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
										infoFrame[tablelength(infoFrame)-1]:SetFont("Fonts\\FRIZQT__.TTF", 8)
										infoFrame[tablelength(infoFrame)-1]:SetText(item)
										infoFrame[tablelength(infoFrame)-1]:SetTextColor(colorr, colorg, colorb)
										infoFrame[tablelength(infoFrame)-1]:SetHighlightTextColor(1, 1, 0)
										infoFrame[tablelength(infoFrame)-1]:SetPushedTextOffset(0,0)
										infoFrame[tablelength(infoFrame)-1]:SetWidth(infoFrame[tablelength(infoFrame)-1]:GetTextWidth())
										infoFrame[tablelength(infoFrame)-1]:SetHeight(10)
										infoFrame[tablelength(infoFrame)-1]:EnableMouse(false)
										local point, relativeTo, relativePoint, xOffset, yOffset = hostListButtons[tablelength(hostListButtons)-1]:GetPoint(1)
										infoFrame[tablelength(infoFrame)-1]:SetPoint("LEFT", vQueueFrame.hostlist, "TOPLEFT", ((vQueueFrame.hostlist:GetWidth() * 3/5 )/(tablelength(args)-1))*(i-1) + (vQueueFrame.hostlist:GetWidth() * 1/3) - ((math.pow(i-2, 2))*10), yOffset)
									else
										local roleArgs = split(item, "\%s")
										for ii, j in pairs(roleArgs) do
											infoFrame[tablelength(infoFrame)] = CreateFrame("Button", "vQueueInfoButton", hostListButtons[tablelength(hostListButtons)-1])
											infoFrame[tablelength(infoFrame)-1]:SetWidth(16)
											infoFrame[tablelength(infoFrame)-1]:SetHeight(16)
											infoFrame[tablelength(infoFrame)-1]:EnableMouse(false)
											infoFrame[tablelength(infoFrame)-1]:SetFrameLevel(1)
											local point, relativeTo, relativePoint, xOffset, yOffset = hostListButtons[tablelength(hostListButtons)-1]:GetPoint(1)
											infoFrame[tablelength(infoFrame)-1]:SetPoint("LEFT", vQueueFrame.hostlist, "TOPLEFT", ((vQueueFrame.hostlist:GetWidth() * 3/5 )/(tablelength(args)-1))*(i-1) - (ii*16) + (vQueueFrame.hostlist:GetWidth() * 1/3), yOffset)
											local infoFrameIcon = infoFrame[tablelength(infoFrame)-1]:CreateTexture(nil, "ARTWORK")
											infoFrameIcon:SetAllPoints()
											infoFrameIcon:SetTexture("Interface\\AddOns\\vQueue\\media\\" .. j)
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
							if setContains(waitingList, args[2]) then
								vQueueFrame.hostlistInviteButton:SetText("waiting")
							else
								vQueueFrame.hostlistInviteButton:SetText("wait list")
							end
							local childs, lvel, size = vQueueFrame.hostlistInviteButton:GetParent():GetChildren()
							if leaderMessages[childs:GetText()] ~= nil and size:GetText() == "?" then
								vQueueFrame.hostlistInviteButton:SetText("reply")
							end
							vQueueFrame.hostlistInviteButton:SetTextColor(209/255, 164/255, 29/255)
							vQueueFrame.hostlistInviteButton:SetWidth(vQueueFrame.hostlistInviteButton:GetTextWidth()+5)
							vQueueFrame.hostlistInviteButton:SetHeight(vQueueFrame.hostlistInviteButton:GetTextHeight()+3)
							vQueueFrame.hostlistInviteButton:SetScript("OnMouseDown", function()
								if GetNumPartyMembers() > 0 then 
									vQueueFrame.hostlistRoleText:SetText("(Leave group before queueing for other groups)")
									return 
								end
								local childs, minLvl = this:GetParent():GetChildren()
								if this:GetText() == "wait list" then
									if tonumber(minLvl:GetText()) > UnitLevel("player") then
										vQueueFrame.hostlistRoleText:SetText("(You do not meet the level requirements for this group)")
										return
									end
									this:SetText("waiting")
									vQueue_SlashCommandHandler("request " .. childs:GetText())
									if not setContains(waitingList, childs:GetText()) then
										addToSet(waitingList, childs:GetText())
									end
								end
								if this:GetText() == "reply" then
									vQueueFrame.replyFrameTo:SetText(childs:GetText())
									vQueueFrame.replyFrameMsg:SetText("(vQ) Lvl " .. tostring(UnitLevel("player")) .. " " .. selectedRole .. " " .. tostring(UnitClass("player")))
									vQueueFrame.replyFrame:Show()
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
			
			if isHost and isWaitListShown then
				--vQueueFrame.hostlistFindButton:Hide()
				vQueueFrame.hostlistFindButton:SetPoint("BOTTOMRIGHT", vQueueFrame.hostlistTopSection, "BOTTOMRIGHT", -80, 4)
				vQueueFrame.hostTitle:Show()
				vQueueFrame.hostTitleRole:Show()
				vQueueFrame.hostTitleClass:Show()
				vQueueFrame.hostTitleLevel:Show()
				vQueueFrame.topsectionHostName:Show()
				local colorr = 247/255
				local colorg = 235/255
				local colorb = 233/255
				local classColor = {}
				classColor["Druid"] = {1, 0.49, 0.04}
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
					hostListButtons[tablelength(hostListButtons)-1]:EnableMouse(true)
					hostListButtons[tablelength(hostListButtons)-1]:SetPoint("RIGHT", vQueueFrame.hostlist, "TOPLEFT",  round(hostListButtons[tablelength(hostListButtons)-1]:GetTextWidth()), -(tablelength(hostListButtons)*15)-10 - vQueueFrame.hostlistTopSection:GetHeight())
					hostListButtonBg = hostListButtons[tablelength(hostListButtons)-1]:CreateTexture(nil, "BACKGROUND")
					hostListButtonBg:SetPoint("LEFT", hostListButtons[tablelength(hostListButtons)-1], "LEFT")
					hostListButtonBg:SetWidth(vQueueFrame.hostlist:GetWidth())
					hostListButtonBg:SetHeight(hostListButtons[tablelength(hostListButtons)-1]:GetTextHeight()+5)
					hostListButtons[tablelength(hostListButtons)-1]:SetScript("OnEnter", function()
						--local childs = this:GetChildren()
						if playerMessages[this:GetText()] ~= nil then
							local playerargs = split(playerMessages[this:GetText()], "\:")
							if Wholefind(playerargs[1], "vqrequest") > 0 then return end
							playerQueueuToolTip:SetOwner( this, "ANCHOR_CURSOR" );
							playerQueueuToolTip:AddLine(playerargs[1], 1, 1, 1, 1)
							playerQueueuToolTip:Show()
						end
					end)
					hostListButtons[tablelength(hostListButtons)-1]:SetScript("OnLeave", function()
						playerQueueuToolTip:Hide()
					end)
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
								infoFrame[tablelength(infoFrame)-1]:SetPoint("LEFT", vQueueFrame.hostlist, "TOPLEFT", ((vQueueFrame.hostlist:GetWidth() * 4/5 )/(tablelength(args)-1))*(i-1), yOffset)
								if i == 3 then
									infoFrame[tablelength(infoFrame)-1]:SetScript("OnUpdate", function()
										if playerMessages[this:GetParent():GetText()] ~= nil then
											local realClass = split(this:GetText(), "\ ")
											local timeSplit = split(playerMessages[this:GetParent():GetText()], "\:")
											if type(tonumber(timeSplit[2])) == "number" then
												local minute = 0
												local seconds = math.floor(GetTime() - tonumber(timeSplit[2]))
												if seconds >= 60 then
													minute = math.floor(seconds/60)
													seconds = seconds - (minute*60)
												end
												if seconds < 10 then
													seconds = "0" .. tostring(seconds)
												end
												this:SetText(realClass[1] .. " " .. tostring(minute) .. ":" .. tostring(seconds) )
												local point, relativeTo, relativePoint, xOffset, yOffset = this:GetPoint(1)
												this:SetWidth(this:GetTextWidth())
												this:SetPoint(point, relativeTo, relativePoint, 218, yOffset)
											end
										end
									end)
								end
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
								infoFrameIcon:SetTexture("Interface\\AddOns\\vQueue\\media\\" .. item)
								infoFrameIcon:SetWidth(infoFrame[tablelength(infoFrame)-1]:GetWidth())
								infoFrameIcon:SetHeight(infoFrame[tablelength(infoFrame)-1]:GetHeight())
							end
						end
					end
					local point, relativeTo, relativePoint, xOffset, yOffset = hostListButtons[tablelength(hostListButtons)-1]:GetPoint(1)
					vQueueFrame.hostlistInviteButton = CreateFrame("Button", nil, hostListButtons[tablelength(hostListButtons)-1], "UIPanelButtonTemplate")
					vQueueFrame.hostlistInviteButton:SetPoint("RIGHT", vQueueFrame.hostlist, "TOPLEFT", vQueueFrame.hostlist:GetWidth()-20, yOffset)
					vQueueFrame.hostlistInviteButton:SetFont("Fonts\\FRIZQT__.TTF", 8)
					vQueueFrame.hostlistInviteButton:SetText("invite")
					vQueueFrame.hostlistInviteButton:SetTextColor(209/255, 164/255, 29/255)
					vQueueFrame.hostlistInviteButton:SetWidth(vQueueFrame.hostlistInviteButton:GetTextWidth()+5)
					vQueueFrame.hostlistInviteButton:SetHeight(vQueueFrame.hostlistInviteButton:GetTextHeight()+3)
					vQueueFrame.hostlistInviteButton:SetScript("OnMouseDown", function()
						if this:GetText() == "invite" then
							InviteByName(this:GetParent():GetText())
							for k, v in pairs(playersQueued) do
								local args = split(k, "\:")
								if args[1] == this:GetParent():GetText() then
									removeFromSet(playersQueued, k)
								end
							end
							local invargs = split(playerMessages[this:GetParent():GetText()], "\:")
							if Wholefind(invargs[1], "vqrequest") > 0 then
								if not setContains(chatQueue, "vqaccept" .. "-WHISPER-" .. this:GetParent():GetText()) then
									addToSet(chatQueue, "vqaccept" .. "-WHISPER-" .. this:GetParent():GetText())
								end
							end
							vQueueFrame.hostlist:Hide()
							vQueueFrame.hostlist:Show()
						end
					end)
					vQueueFrame.hostlistInviteButton:SetScript("OnUpdate", function()
						local tpoint, trelativeTo, trelativePoint, txOffset, yOffset = this:GetParent():GetPoint(1)
						local point, relativeTo, relativePoint, xOffset = this:GetPoint(1)
						this:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
					end)
					
					local point, relativeTo, relativePoint, xOffset, yOffset = hostListButtons[tablelength(hostListButtons)-1]:GetPoint(1)
					vQueueFrame.hostlistDeclineButton = CreateFrame("Button", nil, hostListButtons[tablelength(hostListButtons)-1], "UIPanelButtonTemplate")
					vQueueFrame.hostlistDeclineButton:SetPoint("RIGHT", vQueueFrame.hostlist, "TOPLEFT", vQueueFrame.hostlist:GetWidth(), yOffset)
					vQueueFrame.hostlistDeclineButton:SetFont("Fonts\\FRIZQT__.TTF", 8)
					vQueueFrame.hostlistDeclineButton:SetText("X")
					vQueueFrame.hostlistDeclineButton:SetTextColor(209/255, 164/255, 29/255)
					vQueueFrame.hostlistDeclineButton:SetWidth(vQueueFrame.hostlistDeclineButton:GetTextWidth()+5)
					vQueueFrame.hostlistDeclineButton:SetHeight(vQueueFrame.hostlistDeclineButton:GetTextHeight()+3)
					vQueueFrame.hostlistDeclineButton:SetScript("OnMouseDown", function()
						if this:GetText() == "X" then
							for k, v in pairs(playersQueued) do
								local args = split(k, "\:")
								if args[1] == this:GetParent():GetText() then
									removeFromSet(playersQueued, k)
								end
							end
							local invargs = split(playerMessages[this:GetParent():GetText()], "\:")
							if Wholefind(invargs[1], "vqrequest") > 0 then
								if not setContains(chatQueue, "vqdecline" .. "-WHISPER-" .. this:GetParent():GetText()) then
									addToSet(chatQueue, "vqdecline" .. "-WHISPER-" .. this:GetParent():GetText())
								end
							end
							vQueueFrame.hostlist:Hide()
							vQueueFrame.hostlist:Show()
						end
					end)
					vQueueFrame.hostlistDeclineButton:SetScript("OnUpdate", function()
						local tpoint, trelativeTo, trelativePoint, txOffset, yOffset = this:GetParent():GetPoint(1)
						local point, relativeTo, relativePoint, xOffset = this:GetPoint(1)
						this:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
					end)
					
					scrollbar:SetMinMaxValues(1, tablelength(hostListButtons)-5)
					local prevVal = scrollbar:GetValue()
					scrollbar:SetValue(prevVal+1)
					scrollbar:SetValue(prevVal)
				end
			end
		end)
		hostListFrame = vQueueFrame.hostlist
		
		vQueueFrame.hostlistBg = vQueueFrame.hostlist:CreateTexture(nil, "BACKGROUND")
		vQueueFrame.hostlistBg:ClearAllPoints()
		vQueueFrame.hostlistBg:SetPoint("CENTER", vQueueFrame.hostlist, "CENTER")
		vQueueFrame.hostlistBg:SetWidth(vQueueFrame.hostlist:GetWidth())
		vQueueFrame.hostlistBg:SetHeight(vQueueFrame.hostlist:GetHeight())
		vQueueFrame.hostlistBg:SetTexture(11/255, 11/255, 11/255, 0.8)
		
		vQueueFrame.hostlistborderLeft = vQueueFrame.hostlist:CreateTexture(nil, "BORDER")
		vQueueFrame.hostlistborderLeft:SetTexture("Interface\\AddOns\\vQueue\\media\\ThinBorder-Left")
		vQueueFrame.hostlistborderLeft:ClearAllPoints()
		vQueueFrame.hostlistborderLeft:SetPoint("LEFT", vQueueFrame.hostlist, "LEFT", -2, 0)
		vQueueFrame.hostlistborderLeft:SetWidth(10)
		vQueueFrame.hostlistborderLeft:SetHeight(vQueueFrame.hostlist:GetHeight()-13)
		
		vQueueFrame.hostlistborderRight = vQueueFrame.hostlist:CreateTexture(nil, "BORDER")
		vQueueFrame.hostlistborderRight:SetTexture("Interface\\AddOns\\vQueue\\media\\ThinBorder-Right")
		vQueueFrame.hostlistborderRight:ClearAllPoints()
		vQueueFrame.hostlistborderRight:SetPoint("RIGHT", vQueueFrame.hostlist, "RIGHT", 3, 0)
		vQueueFrame.hostlistborderRight:SetWidth(10)
		vQueueFrame.hostlistborderRight:SetHeight(vQueueFrame.hostlist:GetHeight()-13)
		
		vQueueFrame.hostlistborderTop = vQueueFrame.hostlist:CreateTexture(nil, "BORDER")
		vQueueFrame.hostlistborderTop:SetTexture("Interface\\AddOns\\vQueue\\media\\ThinBorder-Top")
		vQueueFrame.hostlistborderTop:ClearAllPoints()
		vQueueFrame.hostlistborderTop:SetPoint("TOP", vQueueFrame.hostlist, "TOP", 0, 2)
		vQueueFrame.hostlistborderTop:SetWidth(vQueueFrame.hostlist:GetWidth() - 13)
		vQueueFrame.hostlistborderTop:SetHeight(10)
		
		vQueueFrame.hostlistborderBot = vQueueFrame.hostlist:CreateTexture(nil, "BORDER")
		vQueueFrame.hostlistborderBot:SetTexture("Interface\\AddOns\\vQueue\\media\\ThinBorder-Bottom")
		vQueueFrame.hostlistborderBot:ClearAllPoints()
		vQueueFrame.hostlistborderBot:SetPoint("BOTTOM", vQueueFrame.hostlist, "BOTTOM", 0, -2)
		vQueueFrame.hostlistborderBot:SetWidth(vQueueFrame.hostlist:GetWidth() - 14)
		vQueueFrame.hostlistborderBot:SetHeight(10)
		
		vQueueFrame.hostlistborderTopRight = vQueueFrame.hostlist:CreateTexture(nil, "BORDER")
		vQueueFrame.hostlistborderTopRight:SetTexture("Interface\\AddOns\\vQueue\\media\\ThinBorder-TopRight")
		vQueueFrame.hostlistborderTopRight:ClearAllPoints()
		vQueueFrame.hostlistborderTopRight:SetPoint("TOPRIGHT", vQueueFrame.hostlist, "TOPRIGHT", 3, 2)
		vQueueFrame.hostlistborderTopRight:SetWidth(10)
		vQueueFrame.hostlistborderTopRight:SetHeight(10)
		
		vQueueFrame.hostlistborderTopLeft = vQueueFrame.hostlist:CreateTexture(nil, "BORDER")
		vQueueFrame.hostlistborderTopLeft:SetTexture("Interface\\AddOns\\vQueue\\media\\ThinBorder-TopLeft")
		vQueueFrame.hostlistborderTopLeft:ClearAllPoints()
		vQueueFrame.hostlistborderTopLeft:SetPoint("TOPLEFT", vQueueFrame.hostlist, "TOPLEFT", -2, 2)
		vQueueFrame.hostlistborderTopLeft:SetWidth(10)
		vQueueFrame.hostlistborderTopLeft:SetHeight(10)
		
		vQueueFrame.hostlistborderBotRight = vQueueFrame.hostlist:CreateTexture(nil, "BORDER")
		vQueueFrame.hostlistborderBotRight:SetTexture("Interface\\AddOns\\vQueue\\media\\ThinBorder-BottomRight")
		vQueueFrame.hostlistborderBotRight:ClearAllPoints()
		vQueueFrame.hostlistborderBotRight:SetPoint("BOTTOMRIGHT", vQueueFrame.hostlist, "BOTTOMRIGHT", 2.4, -2)
		vQueueFrame.hostlistborderBotRight:SetWidth(10)
		vQueueFrame.hostlistborderBotRight:SetHeight(10)
		
		vQueueFrame.hostlistborderBotLeft = vQueueFrame.hostlist:CreateTexture(nil, "BORDER")
		vQueueFrame.hostlistborderBotLeft:SetTexture("Interface\\AddOns\\vQueue\\media\\ThinBorder-BottomLeft")
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
		vQueueFrame.hostlistTopSectionBg:ClearAllPoints()
		vQueueFrame.hostlistTopSectionBg:SetPoint("TOPLEFT", vQueueFrame.hostlist, "TOPLEFT", 0, 0)
		vQueueFrame.hostlistTopSectionBg:SetAllPoints()
		
		vQueueFrame.hostlistTopSectionBorder = vQueueFrame.hostlistTopSection:CreateTexture(nil, "BORDER")
		vQueueFrame.hostlistTopSectionBorder:SetTexture("Interface\\AddOns\\vQueue\\media\\ThinBorder-Bottom")
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
		vQueueFrame.hostTitleLevel:SetPoint("TOPRIGHT", vQueueFrame.hostlist, "TOPLEFT", 150, -vQueueFrame.hostlistTopSection:GetHeight() - 5)
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
		
		vQueueFrame.hostTitleFindName = CreateFrame("Button", "vQueueButton", vQueueFrame.hostlist)
		vQueueFrame.hostTitleFindName:ClearAllPoints()
		vQueueFrame.hostTitleFindName:SetPoint("TOPLEFT", vQueueFrame.hostlist, "TOPLEFT", 0, -vQueueFrame.hostlistTopSection:GetHeight() - 5)
		vQueueFrame.hostTitleFindName:SetFont("Fonts\\FRIZQT__.TTF", 10)
		vQueueFrame.hostTitleFindName:SetText("Title")
		vQueueFrame.hostTitleFindName:SetTextColor(209/255, 164/255, 29/255)
		vQueueFrame.hostTitleFindName:SetPushedTextOffset(0,0)
		vQueueFrame.hostTitleFindName:SetWidth(vQueueFrame.hostTitleFindName:GetTextWidth())
		vQueueFrame.hostTitleFindName:SetHeight(vQueueFrame.hostTitleFindName:GetTextHeight())
		
		vQueueFrame.hostTitleFindLeader = CreateFrame("Button", "vQueueButton", vQueueFrame.hostlist)
		vQueueFrame.hostTitleFindLeader:ClearAllPoints()
		vQueueFrame.hostTitleFindLeader:SetPoint("TOPLEFT", vQueueFrame.hostlist, "TOPLEFT", 221, -vQueueFrame.hostlistTopSection:GetHeight() - 5)
		vQueueFrame.hostTitleFindLeader:SetFont("Fonts\\FRIZQT__.TTF", 10)
		vQueueFrame.hostTitleFindLeader:SetText("Leader")
		vQueueFrame.hostTitleFindLeader:SetTextColor(209/255, 164/255, 29/255)
		vQueueFrame.hostTitleFindLeader:SetPushedTextOffset(0,0)
		vQueueFrame.hostTitleFindLeader:SetWidth(vQueueFrame.hostTitleFindLeader:GetTextWidth())
		vQueueFrame.hostTitleFindLeader:SetHeight(vQueueFrame.hostTitleFindLeader:GetTextHeight())
		
		vQueueFrame.hostTitleFindLevel = CreateFrame("Button", "vQueueButton", vQueueFrame.hostlist)
		vQueueFrame.hostTitleFindLevel:ClearAllPoints()
		vQueueFrame.hostTitleFindLevel:SetPoint("TOPLEFT", vQueueFrame.hostlist, "TOPLEFT", 270, -vQueueFrame.hostlistTopSection:GetHeight() - 5)
		vQueueFrame.hostTitleFindLevel:SetFont("Fonts\\FRIZQT__.TTF", 10)
		vQueueFrame.hostTitleFindLevel:SetText("Level")
		vQueueFrame.hostTitleFindLevel:SetTextColor(209/255, 164/255, 29/255)
		vQueueFrame.hostTitleFindLevel:SetPushedTextOffset(0,0)
		vQueueFrame.hostTitleFindLevel:SetWidth(vQueueFrame.hostTitleFindLevel:GetTextWidth())
		vQueueFrame.hostTitleFindLevel:SetHeight(vQueueFrame.hostTitleFindLevel:GetTextHeight())
		
		vQueueFrame.hostTitleFindSize = CreateFrame("Button", "vQueueButton", vQueueFrame.hostlist)
		vQueueFrame.hostTitleFindSize:ClearAllPoints()
		vQueueFrame.hostTitleFindSize:SetPoint("TOPLEFT", vQueueFrame.hostlist, "TOPLEFT", 307, -vQueueFrame.hostlistTopSection:GetHeight() - 5)
		vQueueFrame.hostTitleFindSize:SetFont("Fonts\\FRIZQT__.TTF", 10)
		vQueueFrame.hostTitleFindSize:SetText("Size")
		vQueueFrame.hostTitleFindSize:SetTextColor(209/255, 164/255, 29/255)
		vQueueFrame.hostTitleFindSize:SetPushedTextOffset(0,0)
		vQueueFrame.hostTitleFindSize:SetWidth(vQueueFrame.hostTitleFindLeader:GetTextWidth())
		vQueueFrame.hostTitleFindSize:SetHeight(vQueueFrame.hostTitleFindLeader:GetTextHeight())
		
		vQueueFrame.hostTitleFindRoles = CreateFrame("Button", "vQueueButton", vQueueFrame.hostlist)
		vQueueFrame.hostTitleFindRoles:ClearAllPoints()
		vQueueFrame.hostTitleFindRoles:SetPoint("TOPLEFT", vQueueFrame.hostlist, "TOPLEFT", 371, -vQueueFrame.hostlistTopSection:GetHeight() - 5)
		vQueueFrame.hostTitleFindRoles:SetFont("Fonts\\FRIZQT__.TTF", 10)
		vQueueFrame.hostTitleFindRoles:SetText("Role(s)")
		vQueueFrame.hostTitleFindRoles:SetTextColor(209/255, 164/255, 29/255)
		vQueueFrame.hostTitleFindRoles:SetPushedTextOffset(0,0)
		vQueueFrame.hostTitleFindRoles:SetWidth(vQueueFrame.hostTitleFindRoles:GetTextWidth())
		vQueueFrame.hostTitleFindRoles:SetHeight(vQueueFrame.hostTitleFindRoles:GetTextHeight())
		vQueueFrame.hostTitleFindName:Hide()
		vQueueFrame.hostTitleFindLeader:Hide()
		vQueueFrame.hostTitleFindLevel:Hide()
		vQueueFrame.hostTitleFindSize:Hide()
		vQueueFrame.hostTitleFindRoles:Hide()
		
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
		vQueueFrame.hostlistHeal:UnlockHighlight()
		vQueueFrame.hostlistHeal:SetScript("OnMouseDown", function()
			vQueueFrame.hostlistTankTex:SetVertexColor(1, 1, 1)
			vQueueFrame.hostlistDpsTex:SetVertexColor(1, 1, 1)
			vQueueFrame.hostlistHealTex:SetVertexColor(0.5, 1, 0.5)
			vQueueFrame.hostlistRoleText:SetText("")
			vQueueFrame.hostlistHostButton:Show()
			vQueueFrame.hostlistFindButton:Show()
			selectedRole = "Healer"
		end)
		vQueueFrame.hostlistHeal:SetScript("OnEnter", function()
			vQueueFrame.hostlistHealTex:SetVertexColor(1, 1, 0)
		end)
		vQueueFrame.hostlistHeal:SetScript("OnLeave", function()
			if selectedRole == "Healer" then
				vQueueFrame.hostlistHealTex:SetVertexColor(0.5, 1, 0.5)
			else
				vQueueFrame.hostlistHealTex:SetVertexColor(1, 1, 1)
			end
		end)
		
		vQueueFrame.hostlistHealTex = vQueueFrame.hostlistHeal:CreateTexture(nil, "ARTWORK")
		vQueueFrame.hostlistHealTex:SetTexture("Interface\\AddOns\\vQueue\\media\\Healer")
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
			vQueueFrame.hostlistFindButton:Show()
			selectedRole = "Damage"
		end)
		vQueueFrame.hostlistDps:SetScript("OnEnter", function()
			vQueueFrame.hostlistDpsTex:SetVertexColor(1, 1, 0)
		end)
		vQueueFrame.hostlistDps:SetScript("OnLeave", function()
			if selectedRole == "Damage" then
				vQueueFrame.hostlistDpsTex:SetVertexColor(0.5, 1, 0.5)
			else
				vQueueFrame.hostlistDpsTex:SetVertexColor(1, 1, 1)
			end
		end)
		
		vQueueFrame.hostlistDpsTex = vQueueFrame.hostlistDps:CreateTexture(nil, "ARTWORK")
		vQueueFrame.hostlistDpsTex:SetTexture("Interface\\AddOns\\vQueue\\media\\Damage")
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
			vQueueFrame.hostlistFindButton:Show()
			selectedRole = "Tank"
		end)
		vQueueFrame.hostlistTank:SetScript("OnEnter", function()
			vQueueFrame.hostlistTankTex:SetVertexColor(1, 1, 0)
		end)
		vQueueFrame.hostlistTank:SetScript("OnLeave", function()
			if selectedRole == "Tank" then
				vQueueFrame.hostlistTankTex:SetVertexColor(0.5, 1, 0.5)
			else
				vQueueFrame.hostlistTankTex:SetVertexColor(1, 1, 1)
			end
		end)
				
		vQueueFrame.hostlistTankTex = vQueueFrame.hostlistTank:CreateTexture(nil, "ARTWORK")
		vQueueFrame.hostlistTankTex:SetTexture("Interface\\AddOns\\vQueue\\media\\Tank")
		vQueueFrame.hostlistTankTex:ClearAllPoints()
		vQueueFrame.hostlistTankTex:SetPoint("TOP", vQueueFrame.hostlistTank, "TOP", 0, 0)
		vQueueFrame.hostlistTankTex:SetWidth(vQueueFrame.hostlistTank:GetWidth())
		vQueueFrame.hostlistTankTex:SetHeight(vQueueFrame.hostlistTank:GetHeight())
		
		vQueueFrame.hostlistRoleText = CreateFrame("Button", nil, vQueueFrame.hostlistTopSection)
		vQueueFrame.hostlistRoleText:ClearAllPoints()
		vQueueFrame.hostlistRoleText:SetPoint("BOTTOMLEFT", vQueueFrame.hostlistTopSection, "BOTTOMLEFT", 5, 5)
		vQueueFrame.hostlistRoleText:EnableMouse(false)
		vQueueFrame.hostlistRoleText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
		vQueueFrame.hostlistRoleText:SetText("(Select a role to start finding)")
		vQueueFrame.hostlistRoleText:SetTextColor(209/255, 164/255, 29/255)
		vQueueFrame.hostlistRoleText:SetWidth(vQueueFrame.hostlistRoleText:GetTextWidth())
		vQueueFrame.hostlistRoleText:SetHeight(vQueueFrame.hostlistRoleText:GetTextHeight())
		vQueueFrame.hostlistRoleText:SetScript("OnUpdate", function()
			this:SetWidth(vQueueFrame.hostlistRoleText:GetTextWidth())
			this:SetHeight(vQueueFrame.hostlistRoleText:GetTextHeight())
		end)
		
		if selectedRole == "Healer" then
			vQueueFrame.hostlistTankTex:SetVertexColor(1, 1, 1)
			vQueueFrame.hostlistDpsTex:SetVertexColor(1, 1, 1)
			vQueueFrame.hostlistHealTex:SetVertexColor(0.5, 1, 0.5)
			vQueueFrame.hostlistRoleText:SetText("")
		elseif selectedRole == "Damage" then
			vQueueFrame.hostlistTankTex:SetVertexColor(1, 1, 1)
			vQueueFrame.hostlistDpsTex:SetVertexColor(0.5, 1, 0.5)
			vQueueFrame.hostlistHealTex:SetVertexColor(1, 1, 1)
			vQueueFrame.hostlistRoleText:SetText("")
		elseif selectedRole == "Tank" then
			vQueueFrame.hostlistTankTex:SetVertexColor(0.5, 1, 0.5)
			vQueueFrame.hostlistDpsTex:SetVertexColor(1, 1, 1)
			vQueueFrame.hostlistHealTex:SetVertexColor(1, 1, 1)
			vQueueFrame.hostlistRoleText:SetText("")
		end
		
		vQueueFrame.hostlistHostButton = CreateFrame("Button", nil, vQueueFrame.hostlistTopSection, "UIPanelButtonTemplate")
		vQueueFrame.hostlistHostButton:SetPoint("BOTTOMRIGHT", vQueueFrame.hostlistTopSection, "BOTTOMRIGHT", -3, 5)
		vQueueFrame.hostlistHostButton:SetFont("Fonts\\FRIZQT__.TTF", 10)
		vQueueFrame.hostlistHostButton:SetText("Create")
		vQueueFrame.hostlistHostButton:SetButtonState("NORMAL", true)
		vQueueFrame.hostlistHostButton:SetTextColor(209/255, 164/255, 29/255)
		vQueueFrame.hostlistHostButton:SetWidth(vQueueFrame.hostlistHostButton:GetTextWidth()+5)
		vQueueFrame.hostlistHostButton:SetHeight(vQueueFrame.hostlistHostButton:GetTextHeight()+3)
		vQueueFrame.hostlistHostButton:SetScript("OnMouseDown", function()
			if UnitLevel("player") < 5 then 
				vQueueFrame.hostlistRoleText:SetText("(You must be at least level 5 to use this)")
				return
			end
			vQueueFrame.hostlistHostButton:Hide()
			isWaitListShown = true
			--isFinding = false
			--vQueueFrame.hostlistFindButton:SetChecked(false)
			vQueueFrame.hostlistLevelField:SetText(getglobal("MINLVLS")[selectedQuery])
			vQueueFrame.hostlistLevelField:Show()
			vQueueFrame.hostlistNameField:Show()
			vQueueFrame.hostlistCreateButton:Show()
			vQueueFrame.hostlistCancelButton:Show()
			vQueueFrame.hostlistCreateButton:SetText("Create group")
			-- for k, v in pairs(waitingList) do
				-- if not setContains(chatQueue, "vqremove" .. "-WHISPER-" .. k) then
					-- addToSet(chatQueue, "vqremove" .. "-WHISPER-" .. k)
					-- removeFromSet(waitingList, k)
				-- end
			-- end
			vQueueFrame.hostlist:Hide()
			vQueueFrame.hostlist:Show()
		end)
		
		vQueueFrame.hostlistEditButton = CreateFrame("Button", nil, vQueueFrame.hostlistTopSection, "UIPanelButtonTemplate")
		vQueueFrame.hostlistEditButton:SetPoint("BOTTOMRIGHT", vQueueFrame.hostlistTopSection, "BOTTOMRIGHT", -3, 5)
		vQueueFrame.hostlistEditButton:SetFont("Fonts\\FRIZQT__.TTF", 10)
		vQueueFrame.hostlistEditButton:SetText("Edit group")
		vQueueFrame.hostlistEditButton:SetButtonState("NORMAL", true)
		vQueueFrame.hostlistEditButton:SetTextColor(209/255, 164/255, 29/255)
		vQueueFrame.hostlistEditButton:SetWidth(vQueueFrame.hostlistEditButton:GetTextWidth()+5)
		vQueueFrame.hostlistEditButton:SetHeight(vQueueFrame.hostlistEditButton:GetTextHeight()+3)
		vQueueFrame.hostlistEditButton:SetScript("OnMouseDown", function()
			vQueueFrame.hostlistEditButton:Hide()
			--vQueueFrame.hostlistFindButton:Hide()
			isWaitListShown = true
			hostListFrame:Hide()
			hostListFrame:Show()
			vQueueFrame.hostlistLevelField:Show()
			vQueueFrame.hostlistNameField:Show()
			vQueueFrame.hostlistCreateButton:Show()
			vQueueFrame.hostlistCreateButton:SetText("Save")
		end)
		vQueueFrame.hostlistEditButton:Hide()
		
		vQueueFrame.hostlistUnlistButton = CreateFrame("Button", nil, vQueueFrame.hostlistTopSection, "UIPanelButtonTemplate")
		vQueueFrame.hostlistUnlistButton:SetPoint("TOPRIGHT", vQueueFrame.hostlistTopSection, "TOPRIGHT", -3, -5)
		vQueueFrame.hostlistUnlistButton:SetFont("Fonts\\FRIZQT__.TTF", 10)
		vQueueFrame.hostlistUnlistButton:SetText("Unlist group")
		vQueueFrame.hostlistUnlistButton:SetTextColor(209/255, 164/255, 29/255)
		vQueueFrame.hostlistUnlistButton:SetWidth(vQueueFrame.hostlistUnlistButton:GetTextWidth()+5)
		vQueueFrame.hostlistUnlistButton:SetHeight(vQueueFrame.hostlistUnlistButton:GetTextHeight()+3)
		vQueueFrame.hostlistUnlistButton:SetScript("OnMouseDown", function()
			vQueueFrame.hostlistEditButton:Hide()
			vQueueFrame.hostlistWaitListButton:Hide()
			--vQueueFrame.hostlistFindButton:Hide()
			this:Hide()
			vQueueFrame.hostlistLevelField:Hide()
			vQueueFrame.hostlistNameField:Hide()
			vQueueFrame.hostlistCreateButton:Hide()
			isHost = false
			isWaitListShown = false
			--isFinding = false
			-- for k, v in pairs(playersQueued) do
				-- local playerQueuedArgs = split(k, "\:")
				-- if not setContains(chatQueue, "vqdecline" .. "-WHISPER-" .. playerQueuedArgs[1]) then
					-- addToSet(chatQueue, "vqdecline" .. "-WHISPER-" .. playerQueuedArgs[1])
				-- end
			-- end
			vQueueFrame.hostlistFindButton:SetPoint("BOTTOMRIGHT", vQueueFrame.hostlistTopSection, "BOTTOMRIGHT", -65, 4)
			playersQueued = {}
			vQueueFrame.hostlist:Hide()
			vQueueFrame.hostlist:Show()
			vQueueFrame.hostTitleRole:Hide()
			vQueueFrame.hostTitleClass:Hide()
			vQueueFrame.hostTitle:Hide()
			vQueueFrame.hostTitleLevel:Hide()
			vQueueFrame.hostlistRoleText:SetText("")
			vQueueFrame.hostlistHostButton:Show()
			if selectedRole ~= "" then
				vQueueFrame.hostlistFindButton:Show()
			end
		end)
		vQueueFrame.hostlistUnlistButton:Hide()
		
		vQueueFrame.hostlistWaitListButton = CreateFrame("Button", nil, vQueueFrame.hostlistTopSection, "UIPanelButtonTemplate")
		vQueueFrame.hostlistWaitListButton:SetPoint("TOPRIGHT", vQueueFrame.hostlistTopSection, "TOPRIGHT", -75, -5)
		vQueueFrame.hostlistWaitListButton:SetFont("Fonts\\FRIZQT__.TTF", 10)
		vQueueFrame.hostlistWaitListButton:SetText("Wait list")
		vQueueFrame.hostlistWaitListButton:SetTextColor(209/255, 164/255, 29/255)
		vQueueFrame.hostlistWaitListButton:SetWidth(vQueueFrame.hostlistWaitListButton:GetTextWidth()+10)
		vQueueFrame.hostlistWaitListButton:SetHeight(vQueueFrame.hostlistWaitListButton:GetTextHeight()+3)
		vQueueFrame.hostlistWaitListButton:SetScript("OnMouseDown", function()
			selectedQuery = hostedCategory
			vQueueFrame.topsectiontitle:SetText(realHostedCategory)
			vQueueFrame.topsectiontitle:SetWidth(vQueueFrame.topsectiontitle:GetTextWidth())
			vQueueFrame.topsectiontitle:SetHeight(vQueueFrame.topsectiontitle:GetTextHeight())
			if not vQueueFrame.hostlistTopSectionBg:SetTexture("Interface\\AddOns\\vQueue\\media\\" .. hostedCategory) then
				vQueueFrame.hostlistTopSectionBg:SetTexture(0, 0, 0, 0)
			end
			isWaitListShown = true
			hostListFrame:Hide()
			hostListFrame:Show()
		end)
		vQueueFrame.hostlistWaitListButton:SetScript("OnLeave", function()
			this:SetButtonState("NORMAL", false)
		end)
		vQueueFrame.hostlistWaitListButton:SetScript("OnUpdate", function()
			this:SetText("Wait list(" .. tablelength(playersQueued) .. ")")
			this:SetWidth(this:GetTextWidth()+10)
		end)
		vQueueFrame.hostlistWaitListButton:Hide()
		
		vQueueFrame.hostlistFindButton = CreateFrame("CheckButton", "findButtonCheck", vQueueFrame.hostlistTopSection, "UICheckButtonTemplate");
		vQueueFrame.hostlistFindButton:SetPoint("BOTTOMRIGHT", vQueueFrame.hostlistTopSection, "BOTTOMRIGHT", -65, 4)
		--vQueueFrame.hostlistFindButton:SetFont("Fonts\\FRIZQT__.TTF", 10)
		--vQueueFrame.hostlistFindButton:SetText("Find")
		--vQueueFrame.hostlistFindButton:SetTextColor(209/255, 164/255, 29/255)
		getglobal(vQueueFrame.hostlistFindButton:GetName() .."Text"):SetText("Find")
		vQueueFrame.hostlistFindButton:SetWidth(16)
		vQueueFrame.hostlistFindButton:SetHeight(16)
		vQueueFrame.hostlistFindButton:SetChecked(isFinding)
		
		vQueueFrame.hostlistFindButton:SetScript("OnClick", function()
			if this:GetChecked() then
				-- if UnitLevel("player") < 5 then 
					-- vQueueFrame.hostlistRoleText:SetText("(You must be at least level 5 to use this)")
					-- return
				-- end
				--vQueueFrame.hostlistFindButton:SetButtonState("DISABLED", true)
				--vQueueFrame.hostlistFindButton:EnableMouse(false)
				--findTimer = GetTime()
				vQueueFrame.hostlistHostButton:Show()
				vQueueFrame.hostlistLevelField:Hide()
				vQueueFrame.hostlistNameField:Hide()
				vQueueFrame.hostlistCreateButton:Hide()
				--vQueueFrame.hostlistFindButton:SetButtonState("PUSHED", false)
				--isHost = false
				isFinding = true
				vQueue_SlashCommandHandler( "lfg " .. selectedQuery )
				-- for k, v in pairs(groups[selectedQuery]) do
					-- local groupArgs = split(v, "\:")
					-- local deleteEntry = true
					-- for kk, vv in pairs(leaderMessages) do
						-- if kk == groupArgs[2] then deleteEntry = false end
					-- end
					-- if deleteEntry then
						-- table.remove(groups[selectedQuery], k)
						-- k = k - 1
					-- end
				-- end
				
				--vQueueFrame.hostlistEditButton:Hide()
				--playersQueued = {}
				--vQueueFrame.hostTitleRole:Hide()
				--vQueueFrame.hostTitleClass:Hide()
				--vQueueFrame.hostTitle:Hide()
				--vQueueFrame.hostTitleLevel:Hide()
				vQueueFrame.hostlist:Hide()
				vQueueFrame.hostlist:Show()
			elseif not this:GetChecked() then
				isFinding = false
				hostListFrame:Hide()
				hostListFrame:Show()
			end
		end)
		
		vQueueFrame.hostlistNameField = CreateFrame("EditBox", nil, vQueueFrame.hostlist )
		vQueueFrame.hostlistNameField:SetPoint("CENTER", vQueueFrame.hostlist, "CENTER", 0, 20)
		vQueueFrame.hostlistNameField:SetAutoFocus(false)
		vQueueFrame.hostlistNameField:SetFont("Fonts\\FRIZQT__.TTF", 10)
		vQueueFrame.hostlistNameField:SetText("LFM")
		if hostOptions[0] ~= nil then vQueueFrame.hostlistNameField:SetText(hostOptions[0]) end
		vQueueFrame.hostlistNameField:SetTextColor(247/255, 235/255, 233/255)
		vQueueFrame.hostlistNameField:SetMaxLetters(38)
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
		vQueueFrame.hostlistNameFieldText:SetTextColor(209/255, 164/255, 29/255)
		vQueueFrame.hostlistNameFieldText:SetPushedTextOffset(0,0)
		vQueueFrame.hostlistNameFieldText:SetWidth(vQueueFrame.hostlistNameFieldText:GetTextWidth())
		vQueueFrame.hostlistNameFieldText:SetHeight(vQueueFrame.hostlistNameFieldText:GetTextHeight())
		
		vQueueFrame.hostlistLevelField = CreateFrame("EditBox", nil, vQueueFrame.hostlistNameField )
		vQueueFrame.hostlistLevelField:SetPoint("TOPLEFT", vQueueFrame.hostlistNameField, "BOTTOMLEFT", 0, -6)
		vQueueFrame.hostlistLevelField:SetAutoFocus(false)
		vQueueFrame.hostlistLevelField:SetFont("Fonts\\FRIZQT__.TTF", 10)
		vQueueFrame.hostlistLevelField:SetText(tostring(UnitLevel("player")))
		vQueueFrame.hostlistLevelField:SetTextColor(247/255, 235/255, 233/255)
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
		vQueueFrame.hostlistLevelFieldText:SetTextColor(209/255, 164/255, 29/255)
		vQueueFrame.hostlistLevelFieldText:SetPushedTextOffset(0,0)
		vQueueFrame.hostlistLevelFieldText:SetWidth(vQueueFrame.hostlistLevelFieldText:GetTextWidth())
		vQueueFrame.hostlistLevelFieldText:SetHeight(vQueueFrame.hostlistLevelFieldText:GetTextHeight())
		
		local replyFrameBackdrop = {
		  -- path to the background texture
		  bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",  
		  -- path to the border texture
		  edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		  -- true to repeat the background texture to fill the frame, false to scale it
		  tile = true,
		  -- size (width or height) of the square repeating background tiles (in pixels)
		  tileSize = 32,
		  -- thickness of edge segments and square size of edge corners (in pixels)
		  edgeSize = 16,
		  -- distance from the edges of the frame to those of the background texture (in pixels)
		  insets = {
			left = 5,
			right = 5,
			top = 5,
			bottom = 5
		  }
		}
		vQueueFrame.replyFrame = CreateFrame("Frame", nil, vQueueFrame)
		vQueueFrame.replyFrame:SetWidth(300)
		vQueueFrame.replyFrame:SetHeight(150)
		vQueueFrame.replyFrame:SetPoint("CENTER", vQueueFrame)
		vQueueFrame.replyFrame:SetBackdrop(replyFrameBackdrop)
		vQueueFrame.replyFrame:SetBackdropColor(1.0, 1.0, 1.0, 0.4)
		
		vQueueFrame.replyFrameToString = vQueueFrame.replyFrame:CreateFontString(nil)
		vQueueFrame.replyFrameToString:SetFont("Fonts\\FRIZQT__.TTF", 10)
		vQueueFrame.replyFrameToString:SetText("To:")
		vQueueFrame.replyFrameToString:SetTextColor(209/255, 164/255, 29/255)
		vQueueFrame.replyFrameToString:SetWidth(vQueueFrame.replyFrameToString:GetStringWidth())
		vQueueFrame.replyFrameToString:SetHeight(8)
		vQueueFrame.replyFrameToString:SetPoint("TOPLEFT", vQueueFrame.replyFrame, "TOPLEFT", 5, -13)
		
		vQueueFrame.replyFrameTo = CreateFrame("EditBox", nil, vQueueFrame.replyFrame )
		vQueueFrame.replyFrameTo:SetPoint("TOPLEFT", vQueueFrame.replyFrame, "TOPLEFT", 20, -8)
		vQueueFrame.replyFrameTo:SetAutoFocus(false)
		vQueueFrame.replyFrameTo:SetFont("Fonts\\FRIZQT__.TTF", 10)
		vQueueFrame.replyFrameTo:SetText("LFM")
		vQueueFrame.replyFrameTo:SetTextColor(247/255, 235/255, 233/255)
		vQueueFrame.replyFrameTo:SetMaxLetters(12)
		vQueueFrame.replyFrameTo:SetWidth(vQueueFrame.replyFrame:GetWidth() * 4/5)
		vQueueFrame.replyFrameTo:SetHeight(20)
		vQueueFrame.replyFrameTo:SetBackdrop(replyFrameBackdrop)
		vQueueFrame.replyFrameTo:SetTextInsets(5, 0, 0, 0)
		
		vQueueFrame.replyFrameMsg = CreateFrame("EditBox", nil, vQueueFrame.replyFrame )
		vQueueFrame.replyFrameMsg:SetPoint("TOPLEFT", vQueueFrame.replyFrame, "TOPLEFT", 5, -30)
		vQueueFrame.replyFrameMsg:SetPoint("BOTTOMRIGHT", vQueueFrame.replyFrame, "BOTTOMRIGHT", -5, 20)
		vQueueFrame.replyFrameMsg:SetAutoFocus(false)
		vQueueFrame.replyFrameMsg:SetFont("Fonts\\FRIZQT__.TTF", 10)
		vQueueFrame.replyFrameMsg:SetTextColor(247/255, 235/255, 233/255)
		vQueueFrame.replyFrameMsg:SetMaxLetters(200)
		vQueueFrame.replyFrameMsg:SetBackdrop(replyFrameBackdrop)
		vQueueFrame.replyFrameMsg:SetMultiLine(true)
		vQueueFrame.replyFrameMsg:SetTextInsets(5, 5, 5, 0)
		
		vQueueFrame.replyFrameSend = CreateFrame("Button", nil, vQueueFrame.replyFrame, "UIPanelButtonTemplate")
		vQueueFrame.replyFrameSend:SetPoint("BOTTOMRIGHT", vQueueFrame.replyFrame, "BOTTOMRIGHT", -8, 8)
		vQueueFrame.replyFrameSend:SetFont("Fonts\\FRIZQT__.TTF", 10)
		vQueueFrame.replyFrameSend:SetTextColor(209/255, 164/255, 29/255)
		vQueueFrame.replyFrameSend:SetText("Send")
		vQueueFrame.replyFrameSend:SetButtonState("NORMAL", true)
		vQueueFrame.replyFrameSend:SetWidth(vQueueFrame.replyFrameSend:GetTextWidth()+5)
		vQueueFrame.replyFrameSend:SetHeight(vQueueFrame.replyFrameSend:GetTextHeight()+3)
		vQueueFrame.replyFrameSend:SetScript("OnMouseDown", function()
			addToSet(chatQueue, vQueueFrame.replyFrameMsg:GetText() .. "-WHISPER-" .. vQueueFrame.replyFrameTo:GetText())
			this:GetParent():Hide()
		end)
		
		vQueueFrame.replyFrameClose = CreateFrame("Button", nil, vQueueFrame.replyFrame, "UIPanelButtonTemplate")
		vQueueFrame.replyFrameClose:SetPoint("TOPRIGHT", vQueueFrame.replyFrame, "TOPRIGHT", -8, -8)
		vQueueFrame.replyFrameClose:SetFont("Fonts\\FRIZQT__.TTF", 10)
		vQueueFrame.replyFrameClose:SetTextColor(209/255, 164/255, 29/255)
		vQueueFrame.replyFrameClose:SetText("X")
		vQueueFrame.replyFrameClose:SetButtonState("NORMAL", true)
		vQueueFrame.replyFrameClose:SetWidth(vQueueFrame.replyFrameClose:GetTextWidth()+5)
		vQueueFrame.replyFrameClose:SetHeight(vQueueFrame.replyFrameClose:GetTextHeight()+3)
		vQueueFrame.replyFrameClose:SetScript("OnMouseDown", function()
			this:GetParent():Hide()
		end)
		vQueueFrame.replyFrame:Hide()
		
		vQueueFrame.optionsFrame = CreateFrame("Frame", nil, vQueueFrame)
		vQueueFrame.optionsFrame:SetWidth(200)
		vQueueFrame.optionsFrame:SetHeight(130)
		vQueueFrame.optionsFrame:SetPoint("BOTTOM", vQueueFrame, "TOP")
		vQueueFrame.optionsFrame:SetBackdrop(replyFrameBackdrop)
		vQueueFrame.optionsFrame:SetBackdropColor(1.0, 1.0, 1.0, 1.0)
		vQueueFrame.optionsFrame:EnableMouse(true)
		vQueueFrame.optionsFrame:SetMovable(true)
		vQueueFrame.optionsFrame:SetClampedToScreen(true)
		vQueueFrame.optionsFrame:SetScript("OnMouseDown", function()
			this:StartMoving()
		end)
		vQueueFrame.optionsFrame:SetScript("OnMouseUp", function()
			this:StopMovingOrSizing()
		end)
		vQueueFrame.optionsFrame:Hide()
		
		vQueueFrame.optionsFrameTopString = vQueueFrame.optionsFrame:CreateFontString(nil)
		vQueueFrame.optionsFrameTopString:SetFont("Fonts\\FRIZQT__.TTF", 10)
		vQueueFrame.optionsFrameTopString:SetText("vQueue v" .. GetAddOnMetadata("vQueue", "Version") .." Options")
		vQueueFrame.optionsFrameTopString:SetTextColor(209/255, 164/255, 29/255)
		vQueueFrame.optionsFrameTopString:SetWidth(vQueueFrame.optionsFrameTopString:GetStringWidth())
		vQueueFrame.optionsFrameTopString:SetHeight(8)
		vQueueFrame.optionsFrameTopString:SetPoint("TOP", vQueueFrame.optionsFrame, "TOP", 0, -7)
		
		vQueueFrame.filterCheck = CreateFrame("CheckButton", "optionsFilterCheck", vQueueFrame.optionsFrame, "UICheckButtonTemplate");
		vQueueFrame.filterCheck:SetWidth(18)
		vQueueFrame.filterCheck:SetHeight(18)
		getglobal(vQueueFrame.filterCheck:GetName() .."Text"):SetText("Hide channel messages")
		vQueueFrame.filterCheck:SetPoint("TOPLEFT", vQueueFrame.optionsFrame, "TOPLEFT", 5, -15)
		vQueueFrame.filterCheck:SetChecked(vQueueOptions["filter"])
		vQueueFrame.filterCheck:SetScript("OnClick", function()
			if this:GetChecked() then
				vQueueFrame.filterCheckGeneral:Enable()
				vQueueFrame.filterCheckTrade:Enable()
				vQueueFrame.filterCheckLFG:Enable()
				vQueueFrame.filterCheckWorld:Enable()
				vQueueFrame.filterCheckOnlyFilter:Enable()
				vQueueOptions["filter"] = true
			elseif not this:GetChecked() then
				vQueueFrame.filterCheckGeneral:Disable()
				vQueueFrame.filterCheckTrade:Disable()
				vQueueFrame.filterCheckLFG:Disable()
				vQueueFrame.filterCheckWorld:Disable()
				vQueueFrame.filterCheckOnlyFilter:Disable()
				vQueueOptions["filter"] = false
			end
		end)
		
		vQueueFrame.filterCheckGeneral = CreateFrame("CheckButton", "optionsFilterCheckGeneral", vQueueFrame.optionsFrame, "UICheckButtonTemplate");
		vQueueFrame.filterCheckGeneral:SetWidth(16)
		vQueueFrame.filterCheckGeneral:SetHeight(16)
		getglobal(vQueueFrame.filterCheckGeneral:GetName() .."Text"):SetText("General")
		getglobal(vQueueFrame.filterCheckGeneral:GetName() .."Text"):SetFont("Fonts\\FRIZQT__.TTF", 8)
		vQueueFrame.filterCheckGeneral:SetPoint("TOPLEFT", vQueueFrame.optionsFrame, "TOPLEFT", 15, -30)
		if not vQueueOptions["filter"] then vQueueFrame.filterCheckGeneral:Disable() end
		vQueueFrame.filterCheckGeneral:SetChecked(vQueueOptions["general"])
		vQueueFrame.filterCheckGeneral:SetScript("OnClick", function()
			if this:GetChecked() then
				vQueueOptions["general"] = true
			elseif not this:GetChecked() then
				vQueueOptions["general"] = false
			end
		end)
		
		vQueueFrame.filterCheckTrade = CreateFrame("CheckButton", "optionsFilterCheckTrade", vQueueFrame.optionsFrame, "UICheckButtonTemplate");
		vQueueFrame.filterCheckTrade:SetWidth(16)
		vQueueFrame.filterCheckTrade:SetHeight(16)
		getglobal(vQueueFrame.filterCheckTrade:GetName() .."Text"):SetText("Trade")
		getglobal(vQueueFrame.filterCheckTrade:GetName() .."Text"):SetFont("Fonts\\FRIZQT__.TTF", 8)
		vQueueFrame.filterCheckTrade:SetPoint("TOPLEFT", vQueueFrame.optionsFrame, "TOPLEFT", 15, -42)
		if not vQueueOptions["filter"] then vQueueFrame.filterCheckTrade:Disable() end
		vQueueFrame.filterCheckTrade:SetChecked(vQueueOptions["trade"])
		vQueueFrame.filterCheckTrade:SetScript("OnClick", function()
			if this:GetChecked() then
				vQueueOptions["trade"] = true
			elseif not this:GetChecked() then
				vQueueOptions["trade"] = false
			end
		end)
		
		vQueueFrame.filterCheckLFG = CreateFrame("CheckButton", "optionsFilterCheckLFG", vQueueFrame.optionsFrame, "UICheckButtonTemplate");
		vQueueFrame.filterCheckLFG:SetWidth(16)
		vQueueFrame.filterCheckLFG:SetHeight(16)
		getglobal(vQueueFrame.filterCheckLFG:GetName() .."Text"):SetText("Looking For Group")
		getglobal(vQueueFrame.filterCheckLFG:GetName() .."Text"):SetFont("Fonts\\FRIZQT__.TTF", 8)
		vQueueFrame.filterCheckLFG:SetPoint("TOPLEFT", vQueueFrame.optionsFrame, "TOPLEFT", 15, -54)
		if not vQueueOptions["filter"] then vQueueFrame.filterCheckLFG:Disable() end
		vQueueFrame.filterCheckLFG:SetChecked(vQueueOptions["lfg"])
		vQueueFrame.filterCheckLFG:SetScript("OnClick", function()
			if this:GetChecked() then
				vQueueOptions["lfg"] = true
			elseif not this:GetChecked() then
				vQueueOptions["lfg"] = false
			end
		end)
		
		vQueueFrame.filterCheckWorld = CreateFrame("CheckButton", "optionsFilterCheckWorld", vQueueFrame.optionsFrame, "UICheckButtonTemplate");
		vQueueFrame.filterCheckWorld:SetWidth(16)
		vQueueFrame.filterCheckWorld:SetHeight(16)
		getglobal(vQueueFrame.filterCheckWorld:GetName() .."Text"):SetText("World")
		getglobal(vQueueFrame.filterCheckWorld:GetName() .."Text"):SetFont("Fonts\\FRIZQT__.TTF", 8)
		vQueueFrame.filterCheckWorld:SetPoint("TOPLEFT", vQueueFrame.optionsFrame, "TOPLEFT", 15, -66)
		if not vQueueOptions["filter"] then vQueueFrame.filterCheckWorld:Disable() end
		vQueueFrame.filterCheckWorld:SetChecked(vQueueOptions["world"])
		vQueueFrame.filterCheckWorld:SetScript("OnClick", function()
			if this:GetChecked() then
				vQueueOptions["world"] = true
			elseif not this:GetChecked() then
				vQueueOptions["world"] = false
			end
		end)
		
		vQueueFrame.filterCheckOnlyFilter = CreateFrame("CheckButton", "optionsFilterCheckOnlyLfg", vQueueFrame.optionsFrame, "UICheckButtonTemplate");
		vQueueFrame.filterCheckOnlyFilter:SetWidth(16)
		vQueueFrame.filterCheckOnlyFilter:SetHeight(16)
		getglobal(vQueueFrame.filterCheckOnlyFilter:GetName() .."Text"):SetText("Only hide LFG/LFM messages")
		vQueueFrame.filterCheckOnlyFilter:SetPoint("TOPLEFT", vQueueFrame.optionsFrame, "TOPLEFT", 15, -80)
		if not vQueueOptions["filter"] then vQueueFrame.filterCheckOnlyFilter:Disable() end
		vQueueFrame.filterCheckOnlyFilter:SetChecked(vQueueOptions["onlylfg"])
		vQueueFrame.filterCheckOnlyFilter:SetScript("OnClick", function()
			if this:GetChecked() then
				vQueueOptions["onlylfg"] = true
			elseif not this:GetChecked() then
				vQueueOptions["onlylfg"] = false
			end
		end)
		
		vQueueFrame.optionsFrameClose = CreateFrame("Button", nil, vQueueFrame.optionsFrame, "UIPanelButtonTemplate")
		vQueueFrame.optionsFrameClose:SetPoint("BOTTOM", vQueueFrame.optionsFrame, "BOTTOM", 0, 5)
		vQueueFrame.optionsFrameClose:SetFont("Fonts\\FRIZQT__.TTF", 10)
		vQueueFrame.optionsFrameClose:SetTextColor(209/255, 164/255, 29/255)
		vQueueFrame.optionsFrameClose:SetText("Save")
		vQueueFrame.optionsFrameClose:SetButtonState("NORMAL", true)
		vQueueFrame.optionsFrameClose:SetWidth(vQueueFrame.optionsFrameClose:GetTextWidth()+10)
		vQueueFrame.optionsFrameClose:SetHeight(vQueueFrame.optionsFrameClose:GetTextHeight()+3)
		vQueueFrame.optionsFrameClose:SetScript("OnMouseUp", function()
			this:GetParent():Hide()
		end)
		
		--Role Icons for group creation
		vQueueFrame.hostlistHostHealer = CreateFrame("Button", "vQueueInfoButton", vQueueFrame.hostlistNameField)
		vQueueFrame.hostlistHostHealer:SetWidth(32)
		vQueueFrame.hostlistHostHealer:SetHeight(32)
		vQueueFrame.hostlistHostHealer:SetFrameLevel(1)
		vQueueFrame.hostlistHostHealer:SetPoint("TOPRIGHT", vQueueFrame.hostlistNameField, "BOTTOMRIGHT", -32, -5)
		vQueueFrame.hostlistHostHealerTex = vQueueFrame.hostlistHostHealer:CreateTexture(nil, "ARTWORK")
		vQueueFrame.hostlistHostHealerTex:SetAllPoints()
		vQueueFrame.hostlistHostHealerTex:SetTexture("Interface\\AddOns\\vQueue\\media\\Healer")
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
		vQueueFrame.hostlistHostHealer:SetScript("OnEnter", function()
			vQueueFrame.hostlistHostHealerTex:SetVertexColor(1, 1, 0)
		end)
		vQueueFrame.hostlistHostHealer:SetScript("OnLeave", function()
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
		vQueueFrame.hostlistHostDamageTex:SetTexture("Interface\\AddOns\\vQueue\\media\\Damage")
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
		vQueueFrame.hostlistHostDamage:SetScript("OnEnter", function()
			vQueueFrame.hostlistHostDamageTex:SetVertexColor(1, 1, 0)
		end)
		vQueueFrame.hostlistHostDamage:SetScript("OnLeave", function()
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
		vQueueFrame.hostlistHostTankTex:SetTexture("Interface\\AddOns\\vQueue\\media\\Tank")
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
		vQueueFrame.hostlistHostTank:SetScript("OnEnter", function()
			vQueueFrame.hostlistHostTankTex:SetVertexColor(1, 1, 0)
		end)
		vQueueFrame.hostlistHostTank:SetScript("OnLeave", function()
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
		vQueueFrame.hostlistNeededRolesText:SetTextColor(209/255, 164/255, 29/255)
		vQueueFrame.hostlistNeededRolesText:SetPushedTextOffset(0,0)
		vQueueFrame.hostlistNeededRolesText:SetWidth(vQueueFrame.hostlistNeededRolesText:GetTextWidth())
		vQueueFrame.hostlistNeededRolesText:SetHeight(vQueueFrame.hostlistNeededRolesText:GetTextHeight())
		---------------------------------------------------
		
		vQueueFrame.hostlistCancelButton = CreateFrame("Button", nil, vQueueFrame.hostlist, "UIPanelButtonTemplate")
		vQueueFrame.hostlistCancelButton:SetPoint("CENTER", vQueueFrame.hostlist, "CENTER", -8, -130)
		vQueueFrame.hostlistCancelButton:SetFont("Fonts\\FRIZQT__.TTF", 10)
		vQueueFrame.hostlistCancelButton:SetText("Cancel")
		vQueueFrame.hostlistCancelButton:SetTextColor(209/255, 164/255, 29/255)
		vQueueFrame.hostlistCancelButton:SetButtonState("NORMAL", true)
		vQueueFrame.hostlistCancelButton:SetWidth(vQueueFrame.hostlistCancelButton:GetTextWidth()+20)
		vQueueFrame.hostlistCancelButton:SetHeight(vQueueFrame.hostlistCancelButton:GetTextHeight()+10)
		vQueueFrame.hostlistCancelButton:SetScript("OnMouseDown", function()
			isWaitListShown = false
			vQueueFrame.hostlistLevelField:Hide()
			vQueueFrame.hostlistNameField:Hide()
			vQueueFrame.hostlistCreateButton:Hide()
			vQueueFrame.hostlistHostButton:Show()
			this:Hide()
			if vQueueFrame:IsShown() then
				hostListFrame:Hide()
				hostListFrame:Show()
			end
		end)
		vQueueFrame.hostlistCancelButton:Hide()
		
		vQueueFrame.hostlistCreateButton = CreateFrame("Button", nil, vQueueFrame.hostlist, "UIPanelButtonTemplate")
		vQueueFrame.hostlistCreateButton:SetPoint("CENTER", vQueueFrame.hostlist, "CENTER", -8, -100)
		vQueueFrame.hostlistCreateButton:SetFont("Fonts\\FRIZQT__.TTF", 14)
		vQueueFrame.hostlistCreateButton:SetText("Create group")
		vQueueFrame.hostlistCreateButton:SetTextColor(209/255, 164/255, 29/255)
		vQueueFrame.hostlistCreateButton:SetButtonState("NORMAL", true)
		vQueueFrame.hostlistCreateButton:SetWidth(vQueueFrame.hostlistCreateButton:GetTextWidth()+30)
		vQueueFrame.hostlistCreateButton:SetHeight(vQueueFrame.hostlistCreateButton:GetTextHeight()+20)
		vQueueFrame.hostlistCreateButton:SetScript("OnMouseDown", function()
			if vQueueFrame.hostlistNameField:GetText() ~= "" and vQueueFrame.hostlistLevelField:GetText() ~= "" then
				if tonumber(vQueueFrame.hostlistLevelField:GetText()) < 1 then vQueueFrame.hostlistLevelField:SetText("1") end
				if tonumber(vQueueFrame.hostlistLevelField:GetText()) > 60 then vQueueFrame.hostlistLevelField:SetText("60") end
				local name = vQueueFrame.hostlistNameField:GetText()
				local strippedStr = ""
				for i=1, string.len(name) do
					local add = true
					if string.sub(name, i, i) == ":" or string.sub(name, i, i) == "-" then
						add = false
					end
					if add then
						strippedStr = strippedStr .. string.sub(name, i, i)
					end
				end
				hostOptions[0] = strippedStr
				hostOptions[1] = vQueueFrame.hostlistLevelField:GetText()
				hostOptions[2] = healerSelected
				hostOptions[3] = damageSelected
				hostOptions[4] = tankSelected
				vQueueFrame.topsectionHostName:SetText(hostOptions[0])
				vQueueFrame.topsectionHostName:SetWidth(vQueueFrame.topsectionHostName:GetTextWidth())
				vQueueFrame.hostlistLevelField:Hide()
				vQueueFrame.hostlistNameField:Hide()
				vQueueFrame.hostlistCancelButton:Hide()
				this:Hide()
				vQueueFrame.hostlistEditButton:Show()
				vQueueFrame.hostlistUnlistButton:Show()
				vQueueFrame.hostlistWaitListButton:Show()
				--vQueueFrame.hostlistFindButton:Hide()
				if isHost then return end
				vQueue_SlashCommandHandler( "host " .. selectedQuery )
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
			--( (v:GetTextHeight()*k) + (2*k)) > (this:GetHeight()+(this:GetValue()*(v:GetTextHeight()) + 6))
				local yOffset = v:GetBottom()
				if tonumber(k)+1 < this:GetValue() or (yOffset-v:GetTextHeight()*2) < vQueueFrame.catList:GetBottom() then
					if not setContains(catListHidden, tostring(k)) then
						addToSet(catListHidden, tostring(k))
					end
					if (yOffset-v:GetTextHeight()*2) < vQueueFrame.catList:GetBottom() and not setContains(catListHiddenBot, tostring(k)) then
						addToSet(catListHiddenBot, tostring(k))
					end
				else
					if setContains(catListHidden, tostring(k)) then
						removeFromSet(catListHidden, tostring(k))
					end
					if setContains(catListHiddenBot, tostring(k)) then
						removeFromSet(catListHiddenBot, tostring(k))
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
		--vQueueFrame.title:SetText("vQueue v" .. GetAddOnMetadata("vQueue", "Version") .. "  - Group Finder")
		vQueueFrame.title:SetText("vQueue")
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
		
		
		DEFAULT_CHAT_FRAME:AddMessage("Loaded " .. arg1)
		minimapButton = CreateFrame("Button", "vQueueMap", Minimap)
		minimapButton:SetFrameStrata("HIGH")
		minimapButton:SetWidth(32)
		minimapButton:SetHeight(32)
		minimapButton:ClearAllPoints()
		minimapButton:SetPoint("TOPLEFT", Minimap,"TOPLEFT",54-(75*cos(MinimapPos)),(75*sin(MinimapPos))-55) 
		minimapButton:SetHighlightTexture("Interface\\MINIMAP\\UI-Minimap-ZoomButton-Highlight", "ADD")
		minimapButton:RegisterForDrag("RightButton")
		minimapButton.texture = minimapButton:CreateTexture(nil, "BUTTON")
		minimapButton.texture:SetTexture("Interface\\AddOns\\vQueue\\media\\icon")
		minimapButton.texture:SetPoint("CENTER", minimapButton)
		minimapButton.texture:SetWidth(20)
		minimapButton.texture:SetHeight(20)
		
		minimapButton.border = minimapButton:CreateTexture(nil, "OVERLAY")
		minimapButton.border:SetTexture("Interface\\MINIMAP\\MiniMap-TrackingBorder")
		minimapButton.border:SetPoint("TOPLEFT", minimapButton.texture, -6, 5)
		minimapButton.border:SetWidth(52)
		minimapButton.border:SetHeight(52)
		minimapButton:SetScript("OnMouseDown", function()
			point, relativeTo, relativePoint, xOffset, yOffset = minimapButton.texture:GetPoint(1)
			minimapButton.texture:SetPoint(point, relativeTo, relativePoint, xOffset + 2, yOffset - 2)
		end);
		minimapButton:SetScript("OnLeave", function(self, button)
			--minimapToolTip:Hide()
			minimapButton.texture:SetPoint("CENTER", minimapButton)
		end);
		minimapButton:SetScript("OnMouseUp", function()
			if arg1 == "LeftButton" then
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
			end
			minimapButton.texture:SetPoint("CENTER", minimapButton)
		end);
		minimapButton:SetScript("OnDragStart", function()
			miniDrag = true
		end)
		minimapButton:SetScript("OnDragStop", function()
			miniDrag = false
		end)
		minimapButton:SetScript("OnUpdate", function()
			if miniDrag then
				    local xpos,ypos = GetCursorPosition() 
					local xmin,ymin = Minimap:GetLeft(), Minimap:GetBottom() 

					xpos = xmin-xpos/UIParent:GetScale()+70 
					ypos = ypos/UIParent:GetScale()-ymin-70 
					
					MinimapPos = math.deg(math.atan2(ypos,xpos))
					if (MinimapPos < 0) then
						MinimapPos = MinimapPos + 360
					end
					this:SetPoint("TOPLEFT", Minimap,"TOPLEFT",54-(75*cos(MinimapPos)),(75*sin(MinimapPos))-55) 
			end
		end)
		minimapButton:SetScript("OnEnter", function()
			--minimapToolTip:SetOwner( minimapButton, "ANCHOR_BOTTOMLEFT" );
			--minimapToolTip:AddLine("New players in queue", 1, 1, 1)
			--minimapToolTip:CreateFontString( "minimapToolTipText", nil, "GameTooltipText" )
			--minimapToolTipText:SetFont("Fonts\\MORPHEUS.ttf", 12)
			--minimapToolTipText:SetText("New players in queue")
			--minimapToolTip:AddFontStrings(minimapToolTipText, minimapToolTipText)
			--minimapToolTip:Show()
		end)
		--CreateFrame( "GameTooltip", "minimapToolTip", nil, "GameTooltipTemplate" ); -- Tooltip name cannot be nil
		--minimapToolTip:CreateFontString( "minimapToolTipText", nil, "GameTooltipText" )
		--minimapToolTipText:SetFont("Fonts\\MORPHEUS.ttf", 12)
		--minimapToolTipText:SetText("New players in queue")
		
		
		vQueueFrame.topsectiontitle = CreateFrame("Button", "vQueueButton", vQueueFrame.hostlistTopSection)
		vQueueFrame.topsectiontitle:ClearAllPoints()
		vQueueFrame.topsectiontitle:SetPoint("LEFT", vQueueFrame.hostlistTopSection, "LEFT", 5, vQueueFrame.hostlistTopSection:GetHeight() * 1/6)
		vQueueFrame.topsectiontitle:SetFont("Fonts\\MORPHEUS.ttf", 24, "OUTLINE")
		vQueueFrame.topsectiontitle:SetText("<-- Select a catergory")
		vQueueFrame.topsectiontitle:SetTextColor(247/255, 235/255, 233/255)
		vQueueFrame.topsectiontitle:EnableMouse(false)
		vQueueFrame.topsectiontitle:SetWidth(vQueueFrame.topsectiontitle:GetTextWidth())
		vQueueFrame.topsectiontitle:SetHeight(vQueueFrame.topsectiontitle:GetTextHeight())
		
		vQueueFrame.topsectionHostName = CreateFrame("Button", "vQueueButton", vQueueFrame.topsectiontitle)
		vQueueFrame.topsectionHostName:ClearAllPoints()
		vQueueFrame.topsectionHostName:SetPoint("TOPLEFT", vQueueFrame.topsectiontitle, "BOTTOMLEFT", 0, -3)
		vQueueFrame.topsectionHostName:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
		vQueueFrame.topsectionHostName:SetText("")
		vQueueFrame.topsectionHostName:SetTextColor(209/255, 164/255, 29/255)
		vQueueFrame.topsectionHostName:EnableMouse(false)
		vQueueFrame.topsectionHostName:SetWidth(vQueueFrame.topsectionHostName:GetTextWidth())
		vQueueFrame.topsectionHostName:SetHeight(vQueueFrame.topsectionHostName:GetTextHeight())
		vQueueFrame.topsectionHostName:Hide()
		
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
						realScroll = true
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
							local realText = split(v:GetText(), "%(")
							if realText[1] == args[1] then
								frameExistss = true
							end
						end
						if type(args[1]) == "string" and not frameExistss then
							local dropedItemFrame = CreateFrame("Button", "vQueueButton", vQueueFrame.catList)
							dropedItemFrame:SetFont("Fonts\\FRIZQT__.TTF", 8)
							dropedItemFrame:SetText(args[1] .. "(" .. tostring(tablelength(groups[args[2]])) .. ")")
							dropedItemFrame:SetTextColor(204/255, 159/255, 24/255)
							dropedItemFrame:SetHighlightTextColor(1,1,0)
							dropedItemFrame:SetWidth(dropedItemFrame:GetTextWidth())
							dropedItemFrame:SetHeight(8)
							dropedItemFrame:SetFrameLevel(1)
							dropedItemFrame:SetPoint("RIGHT", vQueueFrame.catList, "TOPLEFT",  round(dropedItemFrame:GetTextWidth() + 10), -(tablelength(catListButtons)*10))
							dropedItemFrame:SetScript("OnMouseDown", function()
								isWaitListShown = false
								if not isHost then realHostedCategory = args[1] end
								local args = {}
								local realText = split(this:GetText(), "%(")
								for k, v in pairs(categories) do
									for i, item in v do
										if type(item) == "string" then
											local tArgs = split(item, "\:")
											if tArgs[1] == realText[1] then 
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
								if not vQueueFrame.hostlistTopSectionBg:SetTexture("Interface\\AddOns\\vQueue\\media\\" .. args[2]) then
									vQueueFrame.hostlistTopSectionBg:SetTexture(0, 0, 0, 0)
								end
								vQueueFrame.hostlistHeal:Show()
								vQueueFrame.hostlistDps:Show()
								vQueueFrame.hostlistTank:Show()
								vQueueFrame.hostlistRoleText:Show()
								vQueueFrame.hostlist:Hide()
								vQueueFrame.hostlist:Show()
								if not isHost and not vQueueFrame.hostlistCreateButton:IsShown() then
									vQueueFrame.hostlistHostButton:Show()
								else
									vQueueFrame.hostlistHostButton:Hide()
								end
								if selectedRole ~= "" then
									vQueueFrame.hostlistFindButton:Show()
								else
									vQueueFrame.hostlistFindButton:Hide()
								end
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
					if not setContains(catListHidden, tostring(k)) then
						point, relativeTo, relativePoint, xOffset, yOffset = v:GetPoint(1)
						v:ClearAllPoints()
						v:SetPoint("RIGHT", vQueueFrame.catList, "TOPLEFT",  xOffset, -((yPosition+1)*10))
						yPosition = yPosition + 1
					end
				end
				local tyPosition = yPosition - 1
				for k, v in ipairs(catListButtons) do
					if setContains(catListHiddenBot, tostring(k)) then
						point, relativeTo, relativePoint, xOffset, yOffset = v:GetPoint(1)
						v:ClearAllPoints()
						v:SetPoint("RIGHT", vQueueFrame.catList, "TOPLEFT",  xOffset, -((tyPosition+1)*10))
						tyPosition = tyPosition + 1
					end
				end
			end
			if realScroll then
				realScroll = false
				local prevVal = scrollbarCat:GetValue()
				scrollbarCat:SetValue(prevVal+1)
				scrollbarCat:SetValue(prevVal)
			end
		end)		
		--categoryListFrame = vQueueFrame.catList
		minimapButton:Show()
		vQueueFrame:Hide()
		vQueueFrame.catList:Hide()
		vQueueFrame.hostlist:Hide()
		vQueueFrame.hostlistFindButton:Hide()
		vQueueFrame.hostlistTank:Hide()
		vQueueFrame.hostlistHeal:Hide()
		vQueueFrame.hostlistDps:Hide()
		vQueueFrame.hostlistRoleText:Hide()
		vQueueFrame.hostlistLevelField:Hide()
		vQueueFrame.hostlistNameField:Hide()
		vQueueFrame.hostlistCreateButton:Hide()
		vQueueFrame.hostlistHostButton:Hide()
	end
	if event == "CHAT_MSG_CHANNEL" then
		if string.lower(arg9) ~= string.lower(channelName) then
			local puncString = filterPunctuation(arg1)
			for kLfm, vLfm in pairs(getglobal("LFMARGS")) do
				if Wholefind(puncString, vLfm) > 0 then
					for kCat, kVal in pairs(getglobal("CATARGS")) do
						for kkCat, kkVal in pairs(kVal) do
							if Wholefind(puncString, kkVal) > 0 then
								local exists = false
								local healerRole = ""
								local damageRole = ""
								local tankRole = ""
								for kHeal, vHeal in pairs(getglobal("ROLEARGS")["Healer"]) do
									if Wholefind(puncString, vHeal) > 0 then
										healerRole = "Healer"
									end
								end
								for kDps, vDps in pairs(getglobal("ROLEARGS")["Damage"]) do
									if Wholefind(puncString, vDps) > 0 then
										damageRole = "Damage"
									end
								end
								for kTank, vTank in pairs(getglobal("ROLEARGS")["Tank"]) do
									if Wholefind(puncString, vTank) > 0 then
										tankRole = "Tank"
									end
								end
								if healerRole == "" and tankRole == "" and damageRole == "" then
									healerRole = "Healer"
									damageRole = "Damage"
									tankRole = "Tank"
								end
								for kGroup, vGroup in pairs(groups[kCat]) do
									local groupArgs = split(vGroup, "\:")
									if groupArgs[2] == arg2 then
										groups[kCat][kGroup] = "(Mouseover to see chat message)" .. ":" .. arg2 .. ":" .. getglobal("MINLVLS")[kCat] .. ":" .. "?" .. ":" .. "Role " .. healerRole .. " " .. damageRole .. " " .. tankRole
										exists = true
										break
									end
								end
								for kGroup, vGroup in pairs(groups) do
									for item, value in pairs(groups[kGroup]) do
										local groupArgs = split(value, "\:")
										if groupArgs[2] == arg2 and kGroup ~= kCat then
											if kGroup == "dead" and kCat == "dm" then break end
											groups[kGroup][item] = nil
											if vQueueFrame:IsShown() and selectedQuery == kGroup then
												hostListFrame:Hide()
												hostListFrame:Show()
											end
											refreshCatList(kGroup)
										end
									end
								end
								local strippedStr = ""
								for i=1, string.len(arg1) do
									local add = true
									if string.sub(arg1, i, i) == ":" then
										add = false
									end
									if add then
										strippedStr = strippedStr .. string.sub(arg1, i, i)
									end
								end
								leaderMessages[arg2] = strippedStr .. ":" .. kCat .. ":" .. tostring(GetTime())
								if not exists and kCat ~= "dm" then
									table.insert(groups[kCat], tablelength(groups[kCat]), "(Mouseover to see chat message)" .. ":" .. arg2 .. ":" .. getglobal("MINLVLS")[kCat] .. ":" .. "?" .. ":" .. "Role " .. healerRole .. " " .. damageRole .. " " .. tankRole)		
								end
								if kCat == 'dm' then
									if not setContains(whoRequestList, arg2) then addToSet(whoRequestList, arg2) end
								end
								refreshCatList(kCat)
								if vQueueFrame:IsShown() and selectedQuery == kCat then
									hostListFrame:Hide()
									hostListFrame:Show()
								end
								break
							end
						end
					end
				end
			end
			if isHost then
			for kLfm, vLfm in pairs(getglobal("LFGARGS")) do
				if Wholefind(puncString, vLfm) > 0 then
					for kCat, kVal in pairs(getglobal("CATARGS")) do
						for kkCat, kkVal in pairs(kVal) do
							for groupindex = 1,MAX_PARTY_MEMBERS do
								if UnitName("party" .. tostring(groupindex)) == arg2 then return end
							end
							if Wholefind(puncString, kkVal) > 0 and isHost and hostedCategory == kCat then
								local exists = false
								local playerRole = ""
								for kHeal, vHeal in pairs(getglobal("ROLEARGS")["Healer"]) do
									if Wholefind(puncString, vHeal) > 0 then
										playerRole = "Healer"
									end
								end
								for kDps, vDps in pairs(getglobal("ROLEARGS")["Damage"]) do
									if Wholefind(puncString, vDps) > 0 then
										playerRole = "Damage"
									end
								end
								for kTank, vTank in pairs(getglobal("ROLEARGS")["Tank"]) do
									if Wholefind(puncString, vTank) > 0 then
										playerRole = "Tank"
									end
								end
								if playerRole == "" then playerRole = "Damage" end
								for kPlayer, vPlayer in pairs(playersQueued) do
									local playerArgs = split(kPlayer, "\:")
									if playerArgs[1] == arg2 then
										removeFromSet(playersQueued, kPlayer)
										addToSet(playersQueued, arg2 .. ":" .. playerArgs[2] .. ":" .. playerArgs[3] .. ":" .. playerRole)
										exists = true
										break
									end
								end
								if not setContains(whoRequestList, arg2) then addToSet(whoRequestList, arg2) end
								local strippedStr = ""
								for i=1, string.len(arg1) do
									local add = true
									if string.sub(arg1, i, i) == ":" then
										add = false
									end
									if add then
										strippedStr = strippedStr .. string.sub(arg1, i, i)
									end
								end
								playerMessages[arg2] = strippedStr .. ":" .. GetTime()
								if not exists then
									addToSet(playersQueued, arg2 .. ":" .. "..." .. ":" .. "..." .. ":" .. playerRole)
								end
								if vQueueFrame:IsShown() and isWaitListShown then
									hostListFrame:Hide()
									hostListFrame:Show()
								end
								break
							end
						end
					end
				end
			end
			end
		end
		if string.lower(arg9) == string.lower(channelName) then
			local vQueueArgs = {}
			if arg1 ~= nil then
				vQueueArgs = split(arg1, "\%s")
			end
			
			if vQueueArgs[1] == "vqgroup" and vQueueArgs[2] ~= nil then
				local name = split(arg1, "\:")
				local healerRole = ""
				local damageRole = ""
				local tankRole = ""
				if vQueueArgs[5] == "true" then
					healerRole = "Healer"
				end
				if vQueueArgs[6] == "true" then
					damageRole = "Damage"
				end
				if vQueueArgs[7] == "true" then
				 tankRole = "Tank"
				end
				local exists = false
				
				if tonumber(vQueueArgs[8]) == 0 and setContains(waitingList, arg2) then removeFromSet(waitingList, arg2)
				elseif tonumber(vQueueArgs[8]) == 1 and not setContains(waitingList, arg2) then addToSet(waitingList, arg2) end
				
				local strippedStr = ""
				for i=1, string.len(name[2]) do
					local add = true
					if string.sub(name[2], i, i) == ":" or string.sub(name[2], i, i) == "-" then
						add = false
					end
					if add then
						strippedStr = strippedStr .. string.sub(name[2], i, i)
					end
				end
				
				leaderMessages[arg2] = strippedStr .. ":" .. vQueueArgs[2] .. ":" .. GetTime()
				
				for k, v in pairs(groups) do
					for key, value in pairs(groups[k]) do
						local groupArgs = split(value, "\:")
						if arg2 == groupArgs[2] and k ~= vQueueArgs[2] then 
							groups[k][key] = nil
							if vQueueFrame:IsShown() and selectedQuery == k then
								hostListFrame:Hide()
								hostListFrame:Show()
							end
							refreshCatList(k)
						end
					end
				end
				
				for k, v in pairs(groups) do
					for key, value in pairs(groups[k]) do
						local groupArgs = split(value, "\:")
						if arg2 == groupArgs[2] then 
							exists = true 
							groups[k][key] = strippedStr .. ":" .. arg2 .. ":" .. vQueueArgs[3] .. ":" .. vQueueArgs[4] .. ":" .. "Role " .. healerRole .. " " .. damageRole .. " " .. tankRole
							break
						end
					end
				end
				if not exists then
					table.insert(groups[vQueueArgs[2]], tablelength(groups[vQueueArgs[2]]), strippedStr .. ":" .. arg2 .. ":" .. vQueueArgs[3] .. ":" .. vQueueArgs[4] .. ":" .. "Role " .. healerRole .. " " .. damageRole .. " " .. tankRole)
				end
				refreshCatList(vQueueArgs[2])
				if vQueueFrame:IsShown() then
					hostListFrame:Hide()
					hostListFrame:Show()
				end
			end
			
			-- if vQueueArgs[1] == "lfg" and vQueueArgs[2] ~= nil and isHost then
				-- for k, v in pairs(blackList) do
					-- local blackListArgs = split(k, "\:")
					-- if blackListArgs[1] == arg2 then return end
				-- end
				
				-- local recentContained = false
				-- for k, v in pairs(recentList) do
					-- local recentArgs = split(k, "\:")
					-- if recentArgs[1] == arg2 then
						-- recentContained = true
						-- if (GetTime() - tonumber(recentArgs[3])) > 10 then
							-- removeFromSet(recentList, k)
							-- recentContained = false
							-- break
						-- else
							-- local msgCount = tostring(tonumber(recentArgs[2])+1)
							-- local msgTime = recentArgs[3]
							-- removeFromSet(recentList, k)
							-- addToSet(recentList, arg2 .. ":" .. msgCount .. ":" .. msgTime)
							-- if tonumber(msgCount) > 5 then
								-- local blackListContained = false
								-- for key, value in pairs(blackList) do
									-- local blackListArgs = split(key, "\:")
									-- if blackListArgs[1] == arg2 then blackListContained = true end
								-- end
								-- if not blackListContained then
									-- addToSet(blackList, arg2 .. ":" .. GetTime())
									-- return
								-- end
							-- end
							-- break
						-- end
					-- end
				-- end
				-- if not recentContained then
					-- addToSet(recentList, arg2 .. ":1:" .. GetTime())
				-- end
				
				-- local inGroup = 0
				-- for k, v in pairs(playersQueued) do
					-- local playersQueuedArgs = split(k, "\:")
					-- if playersQueuedArgs[1] == arg2 then inGroup = 1 end
				-- end
				
				-- local groupSize = GetNumRaidMembers()
				-- if groupSize == 0 then groupSize = GetNumPartyMembers() end
				-- groupSize = groupSize + 1
				-- if hostedCategory == vQueueArgs[2] and not setContains(chatQueue, "vqgroup " .. hostedCategory .. " " .. tostring(hostOptions[1]) .. " " .. groupSize .. " " .. tostring(hostOptions[2]) .. " " .. tostring(hostOptions[3]) .. " " .. tostring(hostOptions[4]) .. " " .. tostring(inGroup) .. " :" .. tostring(hostOptions[0]) .. "-WHISPER-" .. arg2) then
					-- addToSet(chatQueue, "vqgroup " .. hostedCategory .. " " .. tostring(hostOptions[1]) .. " " .. groupSize .. " " .. tostring(hostOptions[2]) .. " " .. tostring(hostOptions[3]) .. " " .. tostring(hostOptions[4]) .. " " .. tostring(inGroup) .. " :" .. tostring(hostOptions[0]) .. "-WHISPER-" .. arg2)
				-- end
			-- end		
		end
	end
	
	if event == "WHO_LIST_UPDATE" then
		for i=1, GetNumWhoResults() do
			name, guild, level, race, class, zone, classFileName, sex = GetWhoInfo(i)
			if leaderMessages[name] ~= nil and level > 40 then
				local groupString = ""
				for item, value in pairs(groups["dead"]) do
					local groupArgs = split(value, "\:")
					if groupArgs[2] == name then
						groupString = groups["dead"][item]
						groups["dead"][item] = nil
					end
				end
				if groupString ~= "" then
					local groupArgs = split(groupString, "\:")
					local groupString = groupArgs[1] .. ":" .. groupArgs[2] .. ":" .. getglobal("MINLVLS")["dm"] .. ":" .. groupArgs[4] .. ":" .. groupArgs[5]
					table.insert(groups["dm"], tablelength(groups["dm"]), groupString)
				end
				refreshCatList("dm")
				refreshCatList("dead")
			elseif leaderMessages[name] ~= nil then
				local leaderArgs = split(leaderMessages[name], "\:")
				leaderMessages[name] = leaderArgs[1] .. ":" .. "dead" .. ":" .. leaderArgs[3]
			end
			if leaderMessages[name] ~= nil then removeFromSet(whoRequestList, name) end
		end
		
		if tablelength(whoRequestList) > 0 then
			if isHost then
				for i=1, GetNumWhoResults() do
					name, guild, level, race, class, zone, classFileName, sex = GetWhoInfo(i)
					for kPlayer, vPlayer in pairs(playersQueued) do
						local playerArgs = split(kPlayer, "\:")
						if playerArgs[1] == name then
							removeFromSet(playersQueued, kPlayer)
							addToSet(playersQueued, name .. ":" .. level .. ":" .. class .. ":" .. playerArgs[4])
							break
						end
					end
					removeFromSet(whoRequestList, name)
				end
				if vQueueFrame:IsShown() and isWaitListShown then
					hostListFrame:Hide()
					hostListFrame:Show()
				end
			end
		end
		if vQueueFrame:IsShown() and not isWaitListShown then
			hostListFrame:Hide()
			hostListFrame:Show()
		end
	end
	
	if event == "CHAT_MSG_WHISPER" then
		local args = {}
		if arg1 ~= nil then
			args = split(arg1, "\%s")
		end
		if next(args) == nil then return end
		-- Group info whispers from hosts
		-- if args[1] == "vqgroup" and args[2] ~= nil then
			-- local name = split(arg1, "\:")
			-- local healerRole = ""
			-- local damageRole = ""
			-- local tankRole = ""
			-- if args[5] == "true" then
				-- healerRole = "Healer"
			-- end
			-- if args[6] == "true" then
				-- damageRole = "Damage"
			-- end
			-- if args[7] == "true" then
			 -- tankRole = "Tank"
			-- end
			-- for k, v in pairs(groups) do
				-- for key, value in pairs(groups[k]) do
					-- local groupArgs = split(value, "\:")
					-- if arg2 == groupArgs[2] then return end
				-- end
			-- end
			-- if tonumber(args[8]) == 0 and setContains(waitingList, arg2) then removeFromSet(waitingList, arg2)
			-- elseif tonumber(args[8]) == 1 and not setContains(waitingList, arg2) then addToSet(waitingList, arg2) end
			-- table.insert(groups[args[2]], tablelength(groups[args[2]]), name[2] .. ":" .. arg2 .. ":" .. args[3] .. ":" .. args[4] .. ":" .. "Role " .. healerRole .. " " .. damageRole .. " " .. tankRole)
			-- if vQueueFrame:IsShown() then
				-- hostListFrame:Hide()
				-- hostListFrame:Show()
			-- end
		-- end
		-- Group request info from players
		if args[1] == "vqrequest" and isHost then
			for groupindex = 1,MAX_PARTY_MEMBERS do
				if UnitName("party" .. tostring(groupindex)) == arg2 then return end
			end
			if not setContains(playersQueued, arg2 .. ":" .. args[2] .. ":" .. args[3] .. ":" .. args[4]) then
				addToSet(playersQueued, arg2 .. ":" .. args[2] .. ":" .. args[3] .. ":" .. args[4])
				playerMessages[arg2] = arg1 .. ":" .. GetTime()
				hostListFrame:Hide()
				hostListFrame:Show()
			end
		end
		if (args[1] == "vqaccept" or args[1] == "vqdecline") and isFinding then
			for k, v in pairs(hostListButtons) do
				local childs = v:GetChildren()
				if childs:GetText() == arg2 then
					for key, value in pairs(groups) do
						for kk, vv in pairs(groups[key]) do
							local groupArgs = split(vv, "\:")
							if arg2 == groupArgs[2] then
								if args[1] == "vqaccept" then
									DEFAULT_CHAT_FRAME:AddMessage("Your application to " .. arg2 .. "'s group(" .. key .. ") has been accepted.", 0.2, 1.0, 0.2)
								elseif args[1] == "vqdecline" then
									DEFAULT_CHAT_FRAME:AddMessage("Your application to " .. arg2 .. "'s group(" .. key .. ") has been declined.", 1.0, 0.2, 0.2)
								end
								removeFromSet(waitingList, arg2)
								groups[key][kk] = nil
								refreshCatList(key)
							end
						end
					end
					hostListFrame:Hide()
					hostListFrame:Show()
				end
			end
		end
		if args[1] == "vqremove" and isHost then
			for k, v in playersQueued do
				local playersArgs = split(k, "\:")
				if playersArgs[1] == arg2 then
					removeFromSet(playersQueued, k)
				end
			end
			hostListFrame:Hide()
			hostListFrame:Show()
		end
		
	end
end

local idleMessage = 0

function vQueue_SlashCommandHandler( msg )
	local args = {}
	if msg ~= nil then
		args = split(msg, "\%s")
	end
	if args[1] == "host" and args[2] ~= nil then
		isHost = true
		hostedCategory = args[2]
		DEFAULT_CHAT_FRAME:AddMessage("Now hosting for " .. hostedCategory)
		idleMessage = 30
		hostListFrame:Hide()
		hostListFrame:Show()
	elseif args[1] == "lfg" and args[2] ~= nil then
		if not setContains(chatQueue, args[2]) then
			addToSet(chatQueue, "lfg " .. args[2] .. "-CHANNEL-" .. tostring(GetChannelName(channelName)))
		end
	elseif args[1] == "request" and args[2] ~= nil then
		if not setContains(chatQueue, "vqrequest " .. UnitLevel("player") .. " " .. UnitClass("player") .. " " .. selectedRole .. "-WHISPER-" .. args[2]) then
			addToSet(chatQueue, "vqrequest " .. UnitLevel("player") .. " " .. UnitClass("player") .. " " .. selectedRole .. "-WHISPER-" .. args[2])
		end
	end
end

local lastUpdate = 0
local whoRequestTimer = 0

function refreshCatList(cat)
	for kChild, child in ipairs(catListButtons) do
		local args = {}
		local realText = split(child:GetText(), "%(")
		for k, v in pairs(categories) do
			for i, item in v do
				if type(item) == "string" then
					local tArgs = split(item, "\:")
					if tArgs[1] == realText[1] and tArgs[2] == cat then 
						args = tArgs
						break
					end
				end
			end
		end
		if args[2] ~= nil and type(args[2]) == "string" then
			child:SetText(realText[1] .. "(" .. tablelength(groups[args[2]]) .. ")")
			child:SetWidth(child:GetTextWidth())
			break
		end
	end
end

function vQueue_OnUpdate()
	local elapsed = GetTime() - startTime
	startTime = GetTime()
	
	for k, v in pairs(blackList) do
		local blackListArgs = split(k, "\:")
		if (GetTime() - tonumber(blackListArgs[2])) > (3*60) then
			removeFromSet(blackList, k)
		end
	end
	
	whoRequestTimer = whoRequestTimer + elapsed
	if whoRequestTimer > 2 then
		whoRequestTimer = 0
		if tablelength(whoRequestList) > 0 and not FriendsFrame:IsShown() then
			local whoString = ""
			for k, v in pairs(whoRequestList) do
				whoString = whoString .. k .. " "
			end
			SetWhoToUI(1)
			FriendsFrame:UnregisterEvent("WHO_LIST_UPDATE")
			SendWho(whoString)
		elseif FriendsFrame:IsShown() then
			FriendsFrame:RegisterEvent("WHO_LIST_UPDATE")
		end
	end
	
	idleMessage = idleMessage + elapsed
	if idleMessage > 30 and tablelength(chatQueue) == 0 then
		idleMessage = 0
		if (isFinding or isHost) and GetChannelName(channelName) < 1 then
			JoinChannelByName(channelName)
		elseif GetChannelName(channelName) > 0 and (isHost == false and isFinding == false) then
			LeaveChannelByName(channelName)
		end
		if isHost then
			local groupSize = GetNumRaidMembers()
			if groupSize == 0 then groupSize = GetNumPartyMembers() end
			groupSize = groupSize + 1
			addToSet(chatQueue, "vqgroup " .. hostedCategory .. " " .. tostring(hostOptions[1]) .. " " .. groupSize .. " " .. tostring(hostOptions[2]) .. " " .. tostring(hostOptions[3]) .. " " .. tostring(hostOptions[4]) .. " " .. tostring(2) .. " :" .. tostring(hostOptions[0]) .. "-CHANNEL-" .. tostring(GetChannelName(channelName)))
		end
		
		-- Removes entries after 5 minutes of no updates
		for k, v in pairs(leaderMessages) do
			if v ~= nil then
				local leaderArgs = split(v, "\:")
				local timeDiff = GetTime() - tonumber(leaderArgs[3])
				if leaderArgs[3] ~= nil and type(tonumber(leaderArgs[3])) == "number" then
					for kk, vv in pairs(groups[leaderArgs[2]]) do
						local groupArgs = split(vv, "\:")
						if timeDiff > (300) then -- delete chat entries after 5 minutes of no updates					
							if groupArgs[2] == k then
								groups[leaderArgs[2]][kk] = nil
								leaderMessages[k] = nil
								if vQueueFrame:IsShown() and selectedQuery == leaderArgs[2] then
									hostListFrame:Hide()
									hostListFrame:Show()
								end
								refreshCatList(leaderArgs[2])
								break
							end
						end
						if timeDiff > (40) then -- remove vQueue groups after 40 seconds
							if groupArgs[2] == k and groupArgs[4] ~= "?" then
								groups[leaderArgs[2]][kk] = nil
								leaderMessages[k] = nil
								if vQueueFrame:IsShown() and selectedQuery == leaderArgs[2] then
									hostListFrame:Hide()
									hostListFrame:Show()
								end
								refreshCatList(leaderArgs[2])
								break
							end
						end
					end
				end
			end
		end
	end
	
	-- CHAT LIMITER
	if(chatRate > 0) then
		lastUpdate = lastUpdate + elapsed
		-- MESSAGES TO SEND GO HERE
		if (lastUpdate > (1/chatRate)) then
			lastUpdate = 0
			--queue of chat messages limited to 3 per second
			if next(chatQueue) ~= nil then
				for key,value in pairs(chatQueue) do 
					local args = split(key, "\-")
					SendChatMessage(args[1] , args[2], nil , args[3]);
					removeFromSet(chatQueue, key)
					break
				end
			end
		end
	end
	elapsed = 0
end

SlashCmdList["vQueue"] = vQueue_SlashCommandHandler
SLASH_vQueue1 = "/vQueue"