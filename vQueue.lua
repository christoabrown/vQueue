local chatRate = 3 -- limit to 3 msg/sec
local startTime = 0 -- used to get elapsed in onupdate
local channelName = "vQueue"
local filterEnabled = false -- chat filter

local isHost = false
local hostedCategory = ""
local playersQueued = {}
local chatQueue = {}
local hostWhisperQueue = {}
local groups = {}
local requestWhisperQueue = {}

local vQueueFrame = {}
local catListButtons = {}
local vQueueFrameShown = false

local categories = {}
local hostListButtons = {}

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
			"Deadmines:dm",
			"Ragefire Chasm:rfc",
			"Wailing Caverns:wc"
		
		}
		categories["Raids"] =
		{
			expanded = false,
			"Molten Core:mc",
			"Onyxia's Lair:ony",
			"ayy lmao:lmao"
		
		}
		categories["Battlegrounds"] =
		{
			expanded = false,
			"Warsong Gulch:wsg",
			"Arathi Basin:ab",
			"Alterac Valley:av"
		
		}
		
		groups = 
		{
			"Test group 1",
			"Test group 2",
			"Test group 3",
			"Test group 4",
			"Test group 5",
			"Test group 6",
			"Test group 1",
			"Test group 2",
			"Test group 3",
			"Test group 4",
			"Test group 5",
			"Test group 6",
			"Test group 1",
			"Test group 2",
			"Test group 3",
			"Test group 4",
			"Test group 5",
			"Test group 6",
			"Test group 1",
			"Test group 2",
			"Test group 3",
			"Test group 4",
			"Test group 5",
			"Test group 6",
			"Test group 1",
			"Test group 2",
			"Test group 3",
			"Test group 4",
			"Test group 5",
			"Test group 6",
			"Test group 1",
			"Test group 2",
			"Test group 3",
			"Test group 4",
			"Test group 5",
			"Test group 6",
			"Test group 1",
			"Test group 2",
			"Test group 3",
			"Test group 4",
			"Test group 5",
			"Test group 6",
			"Test group 1",
			"Test group 2",
			"Test group 3",
			"Test group 4",
			"Test group 5",
			"Test group 6",
			
		}
		
		vQueueFrame = CreateFrame("Frame", UIParent)
		vQueueFrame:SetWidth(GetScreenWidth()/2.3)
		vQueueFrame:SetHeight(vQueueFrame:GetWidth()/1.61803398875)
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
		end)
		vQueueFrame:SetScript("OnMouseUp", function(self, button)
			vQueueFrame:StopMovingOrSizing()
		end)
		
		vQueueFrame.texture = vQueueFrame:CreateTexture(nil, "BACKGROUND")
		--vQueueFrame.texture:SetTexture("Interface\\AddOns\\CustomNameplates\\barSmall")
		vQueueFrame.texture:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
		vQueueFrame.texture:SetVertexColor(0.2, 0.2, 0.2, 1)
		vQueueFrame.texture:ClearAllPoints()
		vQueueFrame.texture:SetPoint("CENTER", vQueueFrame, "CENTER")
		vQueueFrame.texture:SetWidth(vQueueFrame:GetWidth())
		vQueueFrame.texture:SetHeight(vQueueFrame:GetHeight())
		
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
		
		--vQueueFrame.scrollframe:SetScrollChild(vQueueFrame.catList)
		
		vQueueFrame.catListBg = vQueueFrame.catList:CreateTexture(nil, "BACKGROUND")
		vQueueFrame.catListBg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
		vQueueFrame.catListBg:ClearAllPoints()
		vQueueFrame.catListBg:SetVertexColor(1, 1, 1, 1)
		vQueueFrame.catListBg:SetPoint("CENTER", vQueueFrame.catList, "CENTER")
		vQueueFrame.catListBg:SetWidth(vQueueFrame.catList:GetWidth())
		vQueueFrame.catListBg:SetHeight(vQueueFrame.catList:GetHeight())
		
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
			--DEFAULT_CHAT_FRAME:AddMessage(tostring(arg1))
			if arg1 == 1 then
				scrollbar:SetValue(scrollbar:GetValue()-1)
			elseif arg1 == -1 then
				scrollbar:SetValue(scrollbar:GetValue()+1)
			end
		end)
		
		vQueueFrame.hostlistBg = vQueueFrame.hostlist:CreateTexture(nil, "BACKGROUND")
		vQueueFrame.hostlistBg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
		vQueueFrame.hostlistBg:ClearAllPoints()
		vQueueFrame.hostlistBg:SetVertexColor(1, 1, 1, 1)
		vQueueFrame.hostlistBg:SetPoint("CENTER", vQueueFrame.hostlist, "CENTER")
		vQueueFrame.hostlistBg:SetWidth(vQueueFrame.hostlist:GetWidth())
		vQueueFrame.hostlistBg:SetHeight(vQueueFrame.hostlist:GetHeight())
		
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
		
		
		--scrollframe = CreateFrame("ScrollFrame", vQueueFrame.hostlist) 
		--local texture = scrollframe:CreateTexture() 
		--texture:SetPoint("CENTER", vQueueFrame.hostlist, "CENTER")
		--texture:SetWidth(vQueueFrame.hostlist:GetWidth())
		--texture:SetHeight(vQueueFrame.hostlist:GetHeight())
		--texture:SetTexture(.5,.5,.5,0.2) 
		
		--scrollbar
		scrollbar = CreateFrame("Slider", nil, vQueueFrame.hostlist, "UIPanelScrollBarTemplate") 
		scrollbar:SetPoint("TOPLEFT", vQueueFrame.hostlist, "TOPRIGHT", -16, -16)
		--scrollbar:SetPoint("BOTTOMLEFT", vQueueFrame.hostlist, "BOTTOMRIGHT", 0, 16)
		scrollbar:SetMinMaxValues(1, 2)
		scrollbar:SetValueStep(1)
		scrollbar.scrollStep = 1
		scrollbar:SetValue(0)
		scrollbar:EnableMouse(true)
		scrollbar:EnableMouseWheel(true)
		scrollbar:SetWidth(16)
		scrollbar:SetHeight(vQueueFrame.hostlist:GetHeight() - 32)
		scrollbar:SetScript("OnValueChanged",
		function (self, value)
		--DEFAULT_CHAT_FRAME:AddMessage(tostring(this:GetValue()))
		--this:GetParent():SetVerticalScroll(this:GetValue())
			for k, v in pairs(hostListButtons) do
				--DEFAULT_CHAT_FRAME:AddMessage(tostring(k))
				if k+1 < this:GetValue() or (v:GetTextHeight()*k) > (this:GetHeight()+(this:GetValue()*v:GetTextHeight())) then
					v:Hide()
				else
					v:Show()
				end
			end
			local position = 1
			for k, v in pairs(hostListButtons) do
				if k == 0 then break end
				if hostListButtons[0]:IsShown() and k == 1 then
					point, relativeTo, relativePoint, xOffset, yOffset = hostListButtons[0]:GetPoint(1)
					hostListButtons[0]:SetPoint(point, relativeTo, relativePoint, xOffset, -(position*10))
					position = position+1
				end
				if v:IsShown() then
					point, relativeTo, relativePoint, xOffset, yOffset = v:GetPoint(1)
					v:SetPoint(point, relativeTo, relativePoint, xOffset, -(position*10))
					position = position+1
				end
			end
		end)
		local scrollbg = scrollbar:CreateTexture(nil, "BACKGROUND")
		scrollbg:SetAllPoints(scrollbar)
		scrollbg:SetTexture(0, 0, 0, 0.4)
		
		for k, v in pairs(groups) do
			hostListButtons[tablelength(hostListButtons)] = CreateFrame("Button", "vQueueButton", vQueueFrame.hostlist)
			hostListButtons[tablelength(hostListButtons)-1]:SetFont("Fonts\\FRIZQT__.TTF", 10)
			hostListButtons[tablelength(hostListButtons)-1]:SetText(v)
			hostListButtons[tablelength(hostListButtons)-1]:SetTextColor(1, 1, 1)
			hostListButtons[tablelength(hostListButtons)-1]:SetHighlightTextColor(1, 1, 0)
			hostListButtons[tablelength(hostListButtons)-1]:SetPushedTextOffset(0,0)
			hostListButtons[tablelength(hostListButtons)-1]:SetWidth(hostListButtons[tablelength(hostListButtons)-1]:GetTextWidth())
			hostListButtons[tablelength(hostListButtons)-1]:SetHeight(10)
			hostListButtons[tablelength(hostListButtons)-1]:SetPoint("RIGHT", vQueueFrame.hostlist, "TOPLEFT",  round(hostListButtons[tablelength(hostListButtons)-1]:GetTextWidth()), -(tablelength(hostListButtons)*10))
			scrollbar:SetMinMaxValues(1, k)
			scrollbar:SetValue(2)
			scrollbar:SetValue(1)
		end
		
		vQueueFrame.title = CreateFrame("Button", "vQueueButton", vQueueFrame.catList)
		vQueueFrame.title:ClearAllPoints()
		--vQueueFrame.button:SetVertexColor(1, 1, 1, 1)
		vQueueFrame.title:SetPoint("CENTER", vQueueFrame.catList, "TOP", 0 , 8)
		vQueueFrame.title:SetFont("Fonts\\FRIZQT__.TTF", 10)
		vQueueFrame.title:SetText("Categories")
		vQueueFrame.title:SetTextColor(0.85, 0.85, 0)
		vQueueFrame.title:SetPushedTextOffset(0,0)
		vQueueFrame.title:SetWidth(20)
		vQueueFrame.title:SetHeight(20)
		
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
		
		vQueueFrame.catList:SetScript("OnShow", function(self)
			for key, value in pairs(categories) do
				local frameExists = false
				local textKey = key
				for k, v in pairs(catListButtons)  do
					if string.sub(v:GetText(), 3, -1) == key then
						frameExists = true
						--DEFAULT_CHAT_FRAME:AddMessage("exists")
					end
				end
				if not frameExists then
					catListButtons[tablelength(catListButtons)] = CreateFrame("Button", "vQueueButton", vQueueFrame.catList)
					catListButtons[tablelength(catListButtons)-1]:SetFont("Fonts\\FRIZQT__.TTF", 10)
					catListButtons[tablelength(catListButtons)-1]:SetText("+ " .. textKey)
					catListButtons[tablelength(catListButtons)-1]:SetTextColor(1, 1, 1)
					catListButtons[tablelength(catListButtons)-1]:SetHighlightTextColor(1, 1, 0)
					catListButtons[tablelength(catListButtons)-1]:SetPushedTextOffset(0,0)
					catListButtons[tablelength(catListButtons)-1]:SetWidth(catListButtons[tablelength(catListButtons)-1]:GetTextWidth())
					catListButtons[tablelength(catListButtons)-1]:SetHeight(10)
					catListButtons[tablelength(catListButtons)-1]:SetPoint("RIGHT", vQueueFrame.catList, "TOPLEFT",  round(catListButtons[tablelength(catListButtons)-1]:GetTextWidth()), -(tablelength(catListButtons)*10))
					catListButtons[tablelength(catListButtons)-1]:SetScript("OnMouseDown", function(self, button)
						local keyPressed = string.sub(this:GetText(), 3, -1)
						--DEFAULT_CHAT_FRAME:AddMessage(keyPressed)
						if not categories[keyPressed][0] then
							this:SetText("- " .. keyPressed)
							categories[keyPressed][0] = true
							vQueueFrame.catList:Hide()
							vQueueFrame.catList:Show()
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
							vQueueFrame.catList:Hide()
							vQueueFrame.catList:Show()
						end
					end)
				end
				if categories[key][0] then
					for keyy, valuee in pairs(categories[key]) do
						local frameExistss = false
						for k, v in pairs(catListButtons)  do
							if v:GetText() == valuee then
								frameExistss = true
							end
						end
						if type(valuee) == "string" and not frameExistss then
							local dropedItemFrame = CreateFrame("Button", "vQueueButton", vQueueFrame.catList)
							dropedItemFrame:SetFont("Fonts\\FRIZQT__.TTF", 8)
							dropedItemFrame:SetText(valuee)
							dropedItemFrame:SetTextColor(0.8, 0.8, 0.8)
							dropedItemFrame:SetHighlightTextColor(1, 1, 0)
							--dropedItemFrame:SetPushedTextOffset(1,1)
							dropedItemFrame:SetWidth(dropedItemFrame:GetTextWidth())
							dropedItemFrame:SetHeight(8)
							dropedItemFrame:SetPoint("RIGHT", vQueueFrame.catList, "TOPLEFT",  round(dropedItemFrame:GetTextWidth() + 10), -(tablelength(catListButtons)*10))
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
				for k, v in pairs(catListButtons) do
					point, relativeTo, relativePoint, xOffset, yOffset = v:GetPoint(1)
					v:ClearAllPoints()
					v:SetPoint("RIGHT", vQueueFrame.catList, "TOPLEFT",  xOffset, -((k+1)*10))
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
	end
	if event == "CHAT_MSG_CHANNEL" then
		--DEFAULT_CHAT_FRAME:AddMessage("test " .. arg9)
		if arg9 == channelName then
			--DEFAULT_CHAT_FRAME:AddMessage("asdawda")
			local args = {}
			if arg1 ~= nil then
				args = split(arg1, "\%s")
			end
			if next(args) == nil then return end
			if args[1] == "lfg" and args[2] ~= nil and UnitName("player") ~= arg2 then
				DEFAULT_CHAT_FRAME:AddMessage(arg2)
				if hostedCategory == args[2] and not setContains(hostWhisperQueue, arg2) and not setContains(playersQueued, arg2) then
					addToSet(hostWhisperQueue, arg2)
					DEFAULT_CHAT_FRAME:AddMessage("added " .. arg2)
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
			if not setContains(groups, args[2]) then
				addToSet(groups, args[2])
				groups[args[2]] = {}
			end
			if not setContains(groups[args[2]], arg2) then
				addToSet(groups[args[2]], arg2)
				--DEFAULT_CHAT_FRAME:AddMessage("added " .. args[2] .. " " .. groups[args[2]])
			end
		end
		-- Group request info from players
		if args[1] == "vqrequest" and isHost then
			if not setContains(playersQueued, arg2) then
				addToSet(playersQueued, arg2)
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
		lfgMsg = "lfg " .. args[2]
		if not setContains(chatQueue, lfgMsg) then
			addToSet(chatQueue, lfgMsg)
		end
	elseif args[1] == "list" then
		for category,value in pairs(groups) do 
			for hostname,valuee in pairs(value) do 
				DEFAULT_CHAT_FRAME:AddMessage(category .. " " .. hostname)
			end
		end
	elseif args[1] == "request" and args[2] ~= nil and args[3] ~= nil then
		for category,value in pairs(groups) do 
			for hostname,valuee in pairs(value) do 
				if args[2] == category and args[3] == hostname then
					if not setContains(requestWhisperQueue, hostname) then
						addToSet(requestWhisperQueue, hostname)
					end
				end
			end
		end
	elseif args[1] == "queue" and isHost then
		for playerName,value in pairs(playersQueued) do 
			DEFAULT_CHAT_FRAME:AddMessage(playerName .. " is in your queue for " .. hostedCategory)
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
					SendChatMessage("vqgroup " .. hostedCategory, "WHISPER", nil , key);
					removeFromSet(hostWhisperQueue, key)
				end
			--request whispers to host
			--TODO ADD PLAYER INFO TO REQUESTS
			elseif next(requestWhisperQueue) ~= nil then
				for key,value in pairs(requestWhisperQueue) do 
					SendChatMessage("vqrequest ", "WHISPER", nil , key);
					removeFromSet(requestWhisperQueue, key)
				end
			end
			lastUpdate = 0
		end
	end
	elapsed = 0
end

SlashCmdList["vQueue"] = vQueue_SlashCommandHandler
SLASH_vQueue1 = "/vQueue"