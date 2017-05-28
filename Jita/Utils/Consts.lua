--[[
	Bunch of constants mostly copied from ChatLog and thrown here for eternity
	for I don't want to see them more than I need to.
]]--

local Jita = Apollo.GetAddon("Jita")
local Consts = Jita.Consts

--

Consts.ChatChannels =
{
	[ChatSystemLib.ChatChannel_Command]         = "Command"         ,
	[ChatSystemLib.ChatChannel_System]          = "System"          ,
	[ChatSystemLib.ChatChannel_Debug]           = "Debug"           ,
	[ChatSystemLib.ChatChannel_Say]             = "Say"             ,
	[ChatSystemLib.ChatChannel_Yell]            = "Yell"            ,
	[ChatSystemLib.ChatChannel_Whisper]         = "Whisper"         ,
	[ChatSystemLib.ChatChannel_Party]           = "Party"           ,
	[ChatSystemLib.ChatChannel_AnimatedEmote]   = "Animated Emote"  ,
	[ChatSystemLib.ChatChannel_Zone]            = "Zone"            ,
	[ChatSystemLib.ChatChannel_ZoneGerman]      = "Zone German"     ,
	[ChatSystemLib.ChatChannel_ZoneFrench]      = "Zone French"     ,
	[ChatSystemLib.ChatChannel_ZonePvP]         = "Zone PvP"        ,
	[ChatSystemLib.ChatChannel_Trade]           = "Trade"           ,
	[ChatSystemLib.ChatChannel_Guild]           = "Guild"           ,
	[ChatSystemLib.ChatChannel_GuildOfficer]    = "Guild Officer"   ,
	[ChatSystemLib.ChatChannel_NPCSay]          = "NPC Say"         ,
	[ChatSystemLib.ChatChannel_NPCYell]         = "NPC Yell"        ,
	[ChatSystemLib.ChatChannel_NPCWhisper]      = "NPC Whisper"     ,
	[ChatSystemLib.ChatChannel_Datachron]       = "Datachron"       ,
	[ChatSystemLib.ChatChannel_Combat]          = "Combat"          ,
	[ChatSystemLib.ChatChannel_Realm]           = "Realm"           ,
	[ChatSystemLib.ChatChannel_Loot]            = "Loot"            ,
	[ChatSystemLib.ChatChannel_Emote]           = "Emote"           ,
	[ChatSystemLib.ChatChannel_PlayerPath]      = "PlayerPath"      ,
	[ChatSystemLib.ChatChannel_Instance]        = "Instance"        ,
	[ChatSystemLib.ChatChannel_WarParty]        = "WarParty"        ,
	[ChatSystemLib.ChatChannel_WarPartyOfficer] = "WarParty Officer",
	[ChatSystemLib.ChatChannel_Nexus]           = "Nexus"           ,
	[ChatSystemLib.ChatChannel_NexusGerman]     = "Nexus German"    ,
	[ChatSystemLib.ChatChannel_NexusFrench]     = "Nexus French"    ,
	[ChatSystemLib.ChatChannel_AccountWhisper]  = "Account Whisper" ,
}

Consts.ChatChannelsSlangs =
{
	[ChatSystemLib.ChatChannel_Party]   = "ChatCircle2",
	[ChatSystemLib.ChatChannel_Society] = "ChatCircle2",
	[ChatSystemLib.ChatChannel_Guild]   = "ChatGuild",
	[1950815839]                        = "xkcdAcidGreen",  -- ws
	[33474419]                          = "xkcdAcidGreen",  -- lf
	[4013610982]                        = "xkcdBarbiePink", -- dn
}

Consts.ChatChannelsAbbreviations =
{
	[ChatSystemLib.ChatChannel_Command]    = "C",
	[ChatSystemLib.ChatChannel_System]     = "S",
	[ChatSystemLib.ChatChannel_Debug]      = "D",
	[ChatSystemLib.ChatChannel_NPCSay]     = "N",
	[ChatSystemLib.ChatChannel_NPCYell]    = "NY",
	[ChatSystemLib.ChatChannel_NPCWhisper] = "NW",
	[ChatSystemLib.ChatChannel_Datachron]  = "D", 
	[ChatSystemLib.ChatChannel_Loot]       = "L", 
	[ChatSystemLib.ChatChannel_Realm]      = "R", 
	[ChatSystemLib.ChatChannel_PlayerPath] = "PP",
}

Consts.ChatMessagesColors =
{
	-- W* Default scheme

	[ChatSystemLib.ChatChannel_Command]         = ApolloColor.new("ChatCommand"),
	[ChatSystemLib.ChatChannel_System]          = ApolloColor.new("ChatSystem"),
	[ChatSystemLib.ChatChannel_Debug]           = ApolloColor.new("ChatDebug"), 
	[ChatSystemLib.ChatChannel_Say]             = ApolloColor.new("ChatSay"),
	[ChatSystemLib.ChatChannel_Yell]            = ApolloColor.new("ChatShout"),
	[ChatSystemLib.ChatChannel_Whisper]         = ApolloColor.new("ChatWhisper"),
	[ChatSystemLib.ChatChannel_Party]           = ApolloColor.new("ChatParty"),
	[ChatSystemLib.ChatChannel_AnimatedEmote]   = ApolloColor.new("ChatEmote"),
	[ChatSystemLib.ChatChannel_Zone]            = ApolloColor.new("ChatZone"),
	[ChatSystemLib.ChatChannel_ZoneGerman]      = ApolloColor.new("ChatZone"),
	[ChatSystemLib.ChatChannel_ZoneFrench]      = ApolloColor.new("ChatZone"),
	[ChatSystemLib.ChatChannel_ZonePvP]         = ApolloColor.new("ChatPvP"),
	[ChatSystemLib.ChatChannel_Trade]           = ApolloColor.new("ChatTrade"),
	[ChatSystemLib.ChatChannel_Guild]           = ApolloColor.new("ChatGuild"),
	[ChatSystemLib.ChatChannel_GuildOfficer]    = ApolloColor.new("ChatGuildOfficer"),
	[ChatSystemLib.ChatChannel_Society]         = ApolloColor.new("ChatCircle2"),
	[ChatSystemLib.ChatChannel_Custom]          = ApolloColor.new("ChatCustom"),
	[ChatSystemLib.ChatChannel_NPCSay]          = ApolloColor.new("ChatNPC"),
	[ChatSystemLib.ChatChannel_NPCYell]         = ApolloColor.new("ChatNPC"),
	[ChatSystemLib.ChatChannel_NPCWhisper]      = ApolloColor.new("ChatNPC"),
	[ChatSystemLib.ChatChannel_Datachron]       = ApolloColor.new("ChatNPC"),
	[ChatSystemLib.ChatChannel_Combat]          = ApolloColor.new("ChatGeneral"),
	[ChatSystemLib.ChatChannel_Realm]           = ApolloColor.new("ChatSupport"),
	[ChatSystemLib.ChatChannel_Loot]            = ApolloColor.new("ChatLoot"),
	[ChatSystemLib.ChatChannel_Emote]           = ApolloColor.new("ChatEmote"),
	[ChatSystemLib.ChatChannel_PlayerPath]      = ApolloColor.new("ChatGeneral"),
	[ChatSystemLib.ChatChannel_Instance]        = ApolloColor.new("ChatInstance"),
	[ChatSystemLib.ChatChannel_WarParty]        = ApolloColor.new("ChatWarParty"),
	[ChatSystemLib.ChatChannel_WarPartyOfficer] = ApolloColor.new("ChatWarPartyOfficer"),
	[ChatSystemLib.ChatChannel_Nexus]           = ApolloColor.new("ChatNexus"),
	[ChatSystemLib.ChatChannel_NexusGerman]     = ApolloColor.new("ChatNexus"),
	[ChatSystemLib.ChatChannel_NexusFrench]     = ApolloColor.new("ChatNexus"),
	[ChatSystemLib.ChatChannel_AccountWhisper]  = ApolloColor.new("ChannelAccountWisper"),

	-- Jita Overwrites

	[ChatSystemLib.ChatChannel_Debug]          = ApolloColor.new("ChannelLoot"),
	[ChatSystemLib.ChatChannel_Emote]          = ApolloColor.new("ItemQuality_Excellent"),
	[ChatSystemLib.ChatChannel_AnimatedEmote]  = ApolloColor.new("FFDCDCDC"),
	[ChatSystemLib.ChatChannel_AccountWhisper] = ApolloColor.new("FFFF1493"),

	-- Highlighting

	["O"] = ApolloColor.new("ChannelLoot"),           -- OOC comments
	["A"] = ApolloColor.new("ItemQuality_Excellent"), -- Inline emotes (asterisks and such)
	["Q"] = ApolloColor.new("ItemQuality_Good"),      -- Quote, double quote.
	["K"] = ApolloColor.new("ItemQuality_Artifact"),  -- Keyword and Mentions
	["U"] = ApolloColor.new("FF7FFFB9"),              -- URL
}

Consts.ChatMessagesFonts = 
{
	"Default",
	
	"CRB_Interface9",
	"CRB_Header9",
	
	"CRB_Interface10",
	"CRB_Header10",
	
	"CRB_Interface11",
	"CRB_Header11",
	
	"CRB_Interface12",
	"CRB_Header12",

	"CRB_Header13",
	
	"CRB_Interface14",
	"CRB_Header14",
	
	"CRB_Interface16",
	"CRB_Header16",

	"CRB_Header16",
	"CRB_Header18",
	"CRB_Header24",
	
	"CRB_FloaterGigantic", 
	"CRB_AlienHuge", 
	
	"Subtitle",

	"Courier",
	"CRB_Dialog_Heading_Small",
	"CRB_Dialog_Heading",
	"CRB_Dialog_Heading_Huge",
	"Nameplates",
	"CRB_Pixel",
}

Consts.EnumInterestsTypes = {
	PvP     = 1, --     1
	Dailies = 2, --    10
	Vets    = 3, --   100
	Raid    = 4, --  1000
	Social  = 5, -- 10000
}

--

Consts.kstrColorChatRegular  = "ff7fffb9"
Consts.kstrColorChatShout    = "ffd9eef7"
Consts.kstrColorChatRoleplay = "ff58e3b0"
Consts.kstrBubbleFont        = "CRB_Dialog"
Consts.kstrDialogFont        = "CRB_Dialog"
Consts.kstrDialogFontRP      = "CRB_Dialog_I"

Consts.kstrGMIcon = "Icon_Windows_UI_GMIcon"

Consts.ktChatJoinOutputStrings =
{
	[ChatSystemLib.ChatChannelResult_BadPassword]           = Apollo.GetString("CRB_Channel_password_incorrect"),
	[ChatSystemLib.ChatChannelResult_AlreadyMember]         = Apollo.GetString("ChatLog_AlreadyMember"),
	[ChatSystemLib.ChatChannelResult_BadName]               = Apollo.GetString("ChatLog_BadName"),
	[ChatSystemLib.ChatChannelResult_InvalidPasswordText]   = Apollo.GetString("ChatLog_InvalidPasswordText"),
	[ChatSystemLib.ChatChannelResult_NoPermissions]         = Apollo.GetString("CRB_Channel_no_permissions"),
	[ChatSystemLib.ChatChannelResult_TooManyCustomChannels]	= Apollo.GetString("ChatLog_TooManyCustom")
}

Consts.ktChatActionOutputStrings =
{
	[ChatSystemLib.ChatChannelAction_PassOwner]       = Apollo.GetString("ChatLog_PassedOwnership"),
	[ChatSystemLib.ChatChannelAction_AddModerator]    = Apollo.GetString("ChatLog_MadeModerator"),
	[ChatSystemLib.ChatChannelAction_RemoveModerator] = Apollo.GetString("ChatLog_MadeMember"),
	[ChatSystemLib.ChatChannelAction_Muted]           = Apollo.GetString("ChatLog_PlayerMuted"),
	[ChatSystemLib.ChatChannelAction_Unmuted]         = Apollo.GetString("ChatLog_PlayerUnmuted"),
	[ChatSystemLib.ChatChannelAction_Kicked]          = Apollo.GetString("ChatLog_PlayerKicked"),
	[ChatSystemLib.ChatChannelAction_AddPassword]     = Apollo.GetString("ChatLog_PasswordAdded"),
	[ChatSystemLib.ChatChannelAction_RemovePassword]  = Apollo.GetString("ChatLog_PasswordRemoved")
}

Consts.ktChatResultOutputStrings =
{
	[ChatSystemLib.ChatChannelResult_DoesntExist]          = Apollo.GetString("CRB_Channel_does_not_exist"),
	[ChatSystemLib.ChatChannelResult_BadPassword]          = Apollo.GetString("CRB_Channel_password_incorrect"),
	[ChatSystemLib.ChatChannelResult_NoPermissions]        = Apollo.GetString("CRB_Channel_no_permissions"),
	[ChatSystemLib.ChatChannelResult_NoSpeaking]           = Apollo.GetString("CRB_Channel_no_speaking"),
	[ChatSystemLib.ChatChannelResult_Muted]                = Apollo.GetString("CRB_Channel_muted"),
	[ChatSystemLib.ChatChannelResult_Throttled]            = Apollo.GetString("CRB_Channel_throttled"),
	[ChatSystemLib.ChatChannelResult_NotInGroup]           = Apollo.GetString("CRB_Not_in_group"),
	[ChatSystemLib.ChatChannelResult_NotInGuild]           = Apollo.GetString("CRB_Channel_not_in_guild"),
	[ChatSystemLib.ChatChannelResult_NotInSociety]         = Apollo.GetString("CRB_Channel_not_in_society"),
	[ChatSystemLib.ChatChannelResult_NotGuildOfficer]      = Apollo.GetString("CRB_Channel_not_guild_officer"),
	[ChatSystemLib.ChatChannelResult_AlreadyMember]        = Apollo.GetString("ChatLog_AlreadyInChannel"),
	[ChatSystemLib.ChatChannelResult_BadName]              = Apollo.GetString("ChatLog_InvalidChannel"),
	[ChatSystemLib.ChatChannelResult_NotMember]            = Apollo.GetString("ChatLog_TargetNotInChannel"),
	[ChatSystemLib.ChatChannelResult_NotInWarParty]        = Apollo.GetString("ChatLog_NotInWarparty"),
	[ChatSystemLib.ChatChannelResult_NotWarPartyOfficer]   = Apollo.GetString("ChatLog_NotWarpartyOfficer"),
	[ChatSystemLib.ChatChannelResult_InvalidMessageText]   = Apollo.GetString("ChatLog_InvalidMessage"),
	[ChatSystemLib.ChatChannelResult_InvalidPasswordText]  = Apollo.GetString("ChatLog_UseDifferentPassword"),
	[ChatSystemLib.ChatChannelResult_TruncatedText]        = Apollo.GetString("ChatLog_MessageTruncated"),
	[ChatSystemLib.ChatChannelResult_InvalidCharacterName] = Apollo.GetString("ChatLog_InvalidCharacterName"),
	[ChatSystemLib.ChatChannelResult_GMMuted]              = Apollo.GetString("ChatLog_MutedByGm"),
	[ChatSystemLib.ChatChannelResult_MissingEntitlement]   = Apollo.GetString("ChatLog_MissingEntitlement"),
}

Consts.ktStringToPath =
{
	[Apollo.GetString("PlayerPathSoldier")  ] = PlayerPathLib.PlayerPathType_Soldier  ,
	[Apollo.GetString("PlayerPathSettler")  ] = PlayerPathLib.PlayerPathType_Settler  ,
	[Apollo.GetString("PlayerPathScientist")] = PlayerPathLib.PlayerPathType_Scientist,
	[Apollo.GetString("PlayerPathExplorer") ] = PlayerPathLib.PlayerPathType_Explorer ,
}

Consts.karFactionToString =
{
	[Unit.CodeEnumFaction.ExilesPlayer]   = Apollo.GetString("CRB_Exile"),
	[Unit.CodeEnumFaction.DominionPlayer] = Apollo.GetString("CRB_Dominion"),
}

Consts.karGenderToString =
{
	['Chua']                     = Apollo.GetString("RaceChua"),
	[Unit.CodeEnumGender.Male]   = Apollo.GetString("CRB_Male"),
	[Unit.CodeEnumGender.Female] = Apollo.GetString("CRB_Female"),
}

Consts.karRaceToString =
{
	[GameLib.CodeEnumRace.Human]   = Apollo.GetString("RaceHuman"),
	[GameLib.CodeEnumRace.Granok]  = Apollo.GetString("RaceGranok"),
	[GameLib.CodeEnumRace.Aurin]   = Apollo.GetString("RaceAurin"),
	[GameLib.CodeEnumRace.Draken]  = Apollo.GetString("RaceDraken"),
	[GameLib.CodeEnumRace.Mechari] = Apollo.GetString("RaceMechari"),
	[GameLib.CodeEnumRace.Chua]    = Apollo.GetString("RaceChua"),
	[GameLib.CodeEnumRace.Mordesh] = Apollo.GetString("CRB_Mordesh"),
}

Consts.karRaceToFaction =
{
	[GameLib.CodeEnumRace.Human]   = 0,

	[GameLib.CodeEnumRace.Mechari] = Unit.CodeEnumFaction.DominionPlayer,
	[GameLib.CodeEnumRace.Draken]  = Unit.CodeEnumFaction.DominionPlayer,
	[GameLib.CodeEnumRace.Chua]    = Unit.CodeEnumFaction.DominionPlayer,

	[GameLib.CodeEnumRace.Mordesh] = Unit.CodeEnumFaction.ExilesPlayer,
	[GameLib.CodeEnumRace.Granok]  = Unit.CodeEnumFaction.ExilesPlayer,
	[GameLib.CodeEnumRace.Aurin]   = Unit.CodeEnumFaction.ExilesPlayer,
}

Consts.karClassToString =
{
	[GameLib.CodeEnumClass.Warrior]      = Apollo.GetString("ClassWarrior"),
	[GameLib.CodeEnumClass.Engineer]     = Apollo.GetString("ClassEngineer"),
	[GameLib.CodeEnumClass.Esper]        = Apollo.GetString("ClassESPER"),
	[GameLib.CodeEnumClass.Medic]        = Apollo.GetString("ClassMedic"),
	[GameLib.CodeEnumClass.Stalker]      = Apollo.GetString("ClassStalker"),
	[GameLib.CodeEnumClass.Spellslinger] = Apollo.GetString("ClassSpellslinger"),
}

Consts.ktPathToString =
{
	[PlayerPathLib.PlayerPathType_Soldier]   = Apollo.GetString("PlayerPathSoldier"),
	[PlayerPathLib.PlayerPathType_Settler]   = Apollo.GetString("PlayerPathSettler"),
	[PlayerPathLib.PlayerPathType_Scientist] = Apollo.GetString("PlayerPathScientist"),
	[PlayerPathLib.PlayerPathType_Explorer]  = Apollo.GetString("PlayerPathExplorer"),
}

Consts.karEvalColors =
{
	[Item.CodeEnumItemQuality.Inferior]  = "ItemQuality_Inferior",
	[Item.CodeEnumItemQuality.Average]   = "ItemQuality_Average",
	[Item.CodeEnumItemQuality.Good]      = "ItemQuality_Good",
	[Item.CodeEnumItemQuality.Excellent] = "ItemQuality_Excellent",
	[Item.CodeEnumItemQuality.Superb]    = "ItemQuality_Superb",
	[Item.CodeEnumItemQuality.Legendary] = "ItemQuality_Legendary",
	[Item.CodeEnumItemQuality.Artifact]  = "ItemQuality_Artifact",
}
