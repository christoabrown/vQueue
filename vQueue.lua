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
		DEFAULT_CHAT_FRAME:AddMessage("Loaded " .. arg1)
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