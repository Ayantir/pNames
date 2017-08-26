--[[
-------------------------------------------------------------------------------
-- pNames, by Ayantir
-------------------------------------------------------------------------------
This software is under : CreativeCommons CC BY-NC-SA 4.0
Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)

You are free to:

    Share — copy and redistribute the material in any medium or format
    Adapt — remix, transform, and build upon the material
    The licensor cannot revoke these freedoms as long as you follow the license terms.


Under the following terms:

    Attribution — You must give appropriate credit, provide a link to the license, and indicate if changes were made. You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.
    NonCommercial — You may not use the material for commercial purposes.
    ShareAlike — If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.
    No additional restrictions — You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits.


Please read full licence at : 
http://creativecommons.org/licenses/by-nc-sa/4.0/legalcode
]]

-- Init pNames variables
pNames = pNames or {} -- Need to be leaked for other addons.
local ADDON_NAME = "pNames"
local ADDON_VERSION = "10"
local ADDON_AUTHOR = "Ayantir"
local ADDON_WEBSITE = "http://www.esoui.com/downloads/info243-pNames.html"

local db

local defaults = {
	formatguild = {},
	formatGroup = 2,
	formatGeo = 2,
	formatLocal = 2,
}

local LAM = LibStub('LibAddonMenu-2.0')

-- Format from name
local function ConvertName(chanCode, from, isCS, fromDisplayName)
	
	local function NewFromForGeoChannel(new_from, from, fromDisplayName, dbSetting)
		if db[dbSetting] == 1 then
			return ZO_LinkHandler_CreateLink(fromDisplayName, nil, DISPLAY_NAME_LINK_TYPE, fromDisplayName)
		elseif db[dbSetting] == 3 then
			return ZO_LinkHandler_CreateLink(new_from .. fromDisplayName, nil, DISPLAY_NAME_LINK_TYPE, fromDisplayName)
		else
			return ZO_LinkHandler_CreateLink(new_from, nil, CHARACTER_LINK_TYPE, from)
		end
	end
	
	-- From can be UserID or Character name depending on wich channel we are
	local new_from = from
	
	-- Messages from @Someone (guild / whisps)
	if IsDecoratedDisplayName(from) then
		
		-- Guild / Officer chat only
		if chanCode >= CHAT_CHANNEL_GUILD_1 and chanCode <= CHAT_CHANNEL_OFFICER_5 then
			
			-- Get guild ID based on channel id
			local guildId = GetGuildId((chanCode - CHAT_CHANNEL_GUILD_1) % 5 + 1)
			local guildName = GetGuildName(guildId)
			
			if db.formatguild[guildName] == 2 then -- Char
				local _, characterName = GetGuildMemberCharacterInfo(guildId, GetGuildMemberIndexFromDisplayName(guildId, new_from))
				characterName = zo_strformat(SI_UNIT_NAME, characterName)
				if characterName == "" then characterName = new_from end -- Some buggy rosters
				new_from = ZO_LinkHandler_CreateLink(characterName, nil, CHARACTER_LINK_TYPE, characterName)
			elseif db.formatguild[guildName] == 3 then -- Char@UserID
				local _, characterName = GetGuildMemberCharacterInfo(guildId, GetGuildMemberIndexFromDisplayName(guildId, new_from))
				characterName = zo_strformat(SI_UNIT_NAME, characterName)
				if characterName == "" then characterName = new_from end -- Some buggy rosters
				characterName = characterName .. new_from
				new_from = ZO_LinkHandler_CreateLink(characterName, nil, DISPLAY_NAME_LINK_TYPE, from)
			else
				new_from = ZO_LinkHandler_CreateLink(new_from, nil, DISPLAY_NAME_LINK_TYPE, from)
			end

		else
			-- Wisps with @ We can't guess characterName for those ones
			new_from = ZO_LinkHandler_CreateLink(new_from, nil, DISPLAY_NAME_LINK_TYPE, from)
		end
		
	-- Geo chat, Party, Whisps with characterName
	else
		
		new_from = zo_strformat(SI_UNIT_NAME, new_from)
		
		if not (chanCode == CHAT_CHANNEL_MONSTER_SAY or chanCode == CHAT_CHANNEL_MONSTER_YELL or chanCode == CHAT_CHANNEL_MONSTER_WHISPER or chanCode == CHAT_CHANNEL_MONSTER_EMOTE) then
			
			if chanCode == CHAT_CHANNEL_PARTY then
				new_from = NewFromForGeoChannel(new_from, from, fromDisplayName, "formatGroup")
			elseif chanCode == CHAT_CHANNEL_SAY or chanCode == CHAT_CHANNEL_YELL or chanCode == CHAT_CHANNEL_EMOTE then
				new_from = NewFromForGeoChannel(new_from, from, fromDisplayName, "formatLocal")
			else
				new_from = NewFromForGeoChannel(new_from, from, fromDisplayName, "formatGeo")
			end
			
		end
		
	end
	
	if isCS then -- ZOS icon
		new_from = "|t16:16:EsoUI/Art/ChatWindow/csIcon.dds|t" .. new_from
	end
	
	return new_from
	
end

-- Registers the receiveMsg function with the chat system event handler to manage incoming chat.
-- Unregisters itself from the player activation event with the event manager.
function OnPlayerActivated()
	
	local LC = LibStub('libChat-1.0')
	
	-- register with libChat
	LC:registerName(ConvertName, ADDON_NAME)
	
	-- unregister from activation event
	EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
	
end

local function BuildMenu()
	
	-- Start adding elements to control panel
   local optionsTable = {
		------------GENERAL--------------
		{
			type = "header",
			name = pNames.lang.optionsH,
			width = "full",
		},
		{
			type = "dropdown",
			name = GetString("SI_CHATCHANNELCATEGORIES", CHAT_CATEGORY_PARTY),
			tooltip = pNames.lang.nameformatTT,
			choices = {pNames.lang.formatchoice1, pNames.lang.formatchoice2, pNames.lang.formatchoice3},
			getFunc = function()
				if db.formatGroup == 1 then
					return pNames.lang.formatchoice1
				elseif db.formatGroup == 2 then
					return pNames.lang.formatchoice2
				elseif db.formatGroup == 3 then
					return pNames.lang.formatchoice3
				else
					-- LAM Reset
					return pNames.lang.formatchoice2
				end
			end,
			setFunc = function(choice)
				if choice == pNames.lang.formatchoice1 then
					db.formatGroup = 1
				elseif choice == pNames.lang.formatchoice2 then
					db.formatGroup = 2
				elseif choice == pNames.lang.formatchoice3 then
					db.formatGroup = 3
				else
					-- LAM Reset
					db.formatGroup = defaults.formatGroup
				end				
			end,
			width = "full",
			default = defaults.formatGroup,
		},
		{
			type = "dropdown",
			name = zo_strformat("<<1>> & <<2>>", GetString(SI_CHAT_CHANNEL_NAME_WHISPER), GetString("SI_CHATCHANNELCATEGORIES", CHAT_CATEGORY_ZONE)),
			tooltip = pNames.lang.nameformatTT,
			choices = {pNames.lang.formatchoice1, pNames.lang.formatchoice2, pNames.lang.formatchoice3},
			getFunc = function()
				if db.formatGeo == 1 then
					return pNames.lang.formatchoice1
				elseif db.formatGeo == 2 then
					return pNames.lang.formatchoice2
				elseif db.formatGeo == 3 then
					return pNames.lang.formatchoice3
				else
					-- LAM Reset
					return pNames.lang.formatchoice2
				end
			end,
			setFunc = function(choice)
				if choice == pNames.lang.formatchoice1 then
					db.formatGeo = 1
				elseif choice == pNames.lang.formatchoice2 then
					db.formatGeo = 2
				elseif choice == pNames.lang.formatchoice3 then
					db.formatGeo = 3
				else
					-- LAM Reset
					db.formatGeo = defaults.formatGeo
				end				
			end,
			width = "full",
			default = defaults.formatGeo,
		},
		{
			type = "dropdown",
			name = zo_strformat("<<1>>, <<2>> & <<3>>", GetString("SI_CHATCHANNELCATEGORIES", CHAT_CATEGORY_SAY), GetString("SI_CHATCHANNELCATEGORIES", CHAT_CATEGORY_YELL), GetString("SI_CHATCHANNELCATEGORIES", CHAT_CATEGORY_EMOTE)),
			tooltip = pNames.lang.nameformatTT,
			choices = {pNames.lang.formatchoice1, pNames.lang.formatchoice2, pNames.lang.formatchoice3},
			getFunc = function()
				if db.formatLocal == 1 then
					return pNames.lang.formatchoice1
				elseif db.formatLocal == 2 then
					return pNames.lang.formatchoice2
				elseif db.formatLocal == 3 then
					return pNames.lang.formatchoice3
				else
					-- LAM Reset
					return pNames.lang.formatchoice2
				end
			end,
			setFunc = function(choice)
				if choice == pNames.lang.formatchoice1 then
					db.formatLocal = 1
				elseif choice == pNames.lang.formatchoice2 then
					db.formatLocal = 2
				elseif choice == pNames.lang.formatchoice3 then
					db.formatLocal = 3
				else
					-- LAM Reset
					db.formatLocal = defaults.formatLocal
				end				
			end,
			width = "full",
			default = defaults.formatLocal,
		}
	}
	
	-- Config per guild now
	local optionIndex = 4
	for guildIndex = 1, GetNumGuilds() do
		
		-- Guildname
		local guildId = GetGuildId(guildIndex)
		local guildName = GetGuildName(guildId)
		
		-- Occurs sometimes
		if(not guildName or (guildName):len() < 1) then
			guildName = "Guild " .. guildIndex
		end
		
		-- Guild joined while addon was disabled / new guild just joined
		if not db.formatguild[guildName] then
			db.formatguild[guildName] = 2
		end
		
		-- One submenu / guild
		optionIndex = optionIndex + 1
		optionsTable[optionIndex] = {
			type = "header",
			name = guildName,
			width = "full",
		}
		
		-- Config still store 1/2/3
		optionIndex = optionIndex + 1
		
		optionsTable[optionIndex] = {
			type = "dropdown",
			name = pNames.lang.nameformat,
			tooltip = pNames.lang.nameformatTT,
			choices = {pNames.lang.formatchoice1, pNames.lang.formatchoice2, pNames.lang.formatchoice3},
			getFunc = function()
				-- Config per guild
				if db.formatguild[guildName] then
					if db.formatguild[guildName] == 1 then
						return pNames.lang.formatchoice1
					elseif db.formatguild[guildName] == 2 then
						return pNames.lang.formatchoice2
					elseif db.formatguild[guildName] == 3 then
						return pNames.lang.formatchoice3
					else
						-- Should not happens
						return pNames.lang.formatchoice2
					end
				end
			end,
			setFunc = function(choice)
				if choice == pNames.lang.formatchoice1 then
					db.formatguild[guildName] = 1
				elseif choice == pNames.lang.formatchoice2 then
					db.formatguild[guildName] = 2
				elseif choice == pNames.lang.formatchoice3 then
					db.formatguild[guildName] = 3
				else
					-- Should not happens
					db.formatguild[guildName] = 2
				end				
			end,
			width = "full",
			default = 2,
		}
		
	end
	
    LAM:RegisterOptionControls("pNamesOptions", optionsTable)
	
end

-- Initialises the settings and settings menu
local function OnAddonLoaded(event, addonName)

	--Protect
	if addonName == ADDON_NAME then
	
		--Protect
		if pChat then return end
		
		-- Fetch the saved variables
		db = ZO_SavedVars:NewAccountWide('PNAMES_OPTS', 1.1, nil, defaults)
		
		-- Create control panel
		local panelData = {
			type = "panel",
			name = ADDON_NAME,
			displayName = ZO_HIGHLIGHT_TEXT:Colorize(ADDON_NAME),
			author = ADDON_AUTHOR,
			version = ADDON_VERSION,
			registerForRefresh = true,
			registerForDefaults = true,
			website = ADDON_WEBSITE,
		}
		
		LAM:RegisterAddonPanel("pNamesOptions", panelData)
		
		BuildMenu()
		
		-- Because ChatSystem is loaded after EVENT_ADDON_LOADED triggers, we use EVENT_PLAYER_ACTIVATED wich is run after each reloadui and few ms after chat is loaded
		EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
		
		-- register OnSelfJoinedOrLeftGuild with EVENT_GUILD_SELF_JOINED_GUILD
		EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_GUILD_SELF_JOINED_GUILD, BuildMenu)
		
		-- Register OnSelfJoinedOrLeftGuild with EVENT_GUILD_SELF_LEFT_GUILD
		EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_GUILD_SELF_LEFT_GUILD, BuildMenu)
		
		EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)
		
	end
	
end
   
-- Need to be loaded before chat is activated
EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddonLoaded)