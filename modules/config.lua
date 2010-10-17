local ElitistGroup = select(2, ...)
local Config = ElitistGroup:NewModule("Config")
local L = ElitistGroup.L
local options, AceConfigRegistery, AceConfigDialog

local function set(info, value)
	local parentKey = info.arg or info[#(info) - 1]
	local key = info[#(info)]
	ElitistGroup.db.profile[parentKey][key] = value

	if( parentKey == "comm" ) then
		ElitistGroup.modules.Sync:Setup()
	elseif( key == "mouseover" ) then
		ElitistGroup.modules.Mouseover:Setup()
	elseif( parentKey == "inspect" ) then
		ElitistGroup.modules.Inspect:OnInitialize()
	end
end

local function get(info, value)
	return ElitistGroup.db.profile[info.arg or info[#(info) - 1]][info[#(info)]]
end

local function loadOptions()
	options = {}
	options.general = {
		order = 1,
		type = "group",
		name = "Elitist Group",
		set = set,
		get = get,
		args = {
			help = {
				order = 0,
				type = "group",
				inline = true,
				name = L["Help"],
				args = {
					help = {
						order = 1,
						type = "description",
						name = L["Trust list and addon communication options can be found in the menu to your left."],
					}
				},
			},
			general = {
				order = 1,
				type = "group",
				inline = true,
				name = L["General"],
				args = {
					announceData = {
						order = 1,
						type = "toggle",
						name = L["Announce synced data"],
						desc = L["Alerts you in chat when you receive new notes or gear information from somebody."],
					},
					sep = { order = 2, type = "description", name = "", width = "full"},
					summaryQueue = {
						order = 2,
						type = "toggle",
						name = L["Always process group queue"],
						desc = L["When /eg summary is closed, the group inspect queue will always be processed.|n|nUnchecking this means the inspect queue is reset when /eg summary is closed."]
					},
					showSlotName = {
						order = 3,
						type = "toggle",
						name = L["Show slot names"],
						desc = L["Instead of listing item link when viewing overall status, you'll instead see the name of the slot."],
					}
				},
			},
			auto = {
				order = 1.5,
				type = "group",
				inline = true,
				name = L["Automatically"],
				args = {
					alertRating = {
						order = 1,
						type = "toggle",
						name = L["Alert when grouped with low rated players"],
						desc = L["If you leave a rating on somebody of 2 or less, the next time you group with them you will get a warning in chat."],
						width = "full",
					},
					autoPopup = {
						order = 2,
						type = "toggle",
						name = L["Show rating after dungeon"],
						desc = L["After completing a dungeon through the Looking For Dungeon system, automatically popup the /rate frame so you can set notes and rating on your group members."],
					},
					autoSummary = {
						order = 3,
						type = "toggle",
						name = L["Show summary on dungeon start"],
						desc = L["Pops up the summary window when you first zone into an instance using the Looking for Dungeon system showing you info on your group."],
					},
					keepInspects = {
						order = 4,
						type = "range",
						name = L["How many inspects to save"],
						desc = L["When automatically scanning your group, this is the number of inspects that will be saved so you can still inspect other people while the scan runs.|n|nThe more inspects you keep, the longer a scan will take."],
						min = 0, max = 5, step = 1,
					}
				},
			},
			main = {
				order = 2,
				type = "group",
				inline = true,
				name = L["Main/alt experience"],
				args = {
					help = {
						order = 1,
						type = "description",
						name = function()
							local text = L["Main/alt experience is a way of letting other Elitist Group users see that you have experience in dungeons on more than one character. By setting a main, when people inspect your alt they will see your experience on both your main and alt. Your main will remain anonymous, only the experience data is shown to other users.\nThis will only show up for people who inspect you."]
							if( ElitistGroup.db.global.main.character ) then
								return text .. "\n\n" .. string.format(L["Your main is currently: %s."], ElitistGroup.db.global.main.character)
							end

							return text .. "\n\n" .. L["You have not set a main yet."]
						end,
					},
					sep = {order = 2, type = "header", name = ""},
					setMain = {
						order = 3,
						type = "toggle",
						name = string.format(L["Make %s my main"], ElitistGroup.playerID),
						set = function(info, value)
							if( ElitistGroup.db.global.main.character ~= ElitistGroup.playerID ) then
								ElitistGroup.db.global.main.character = ElitistGroup.playerID
								ElitistGroup:OnDatabaseShutdown()
							else
								ElitistGroup.db.global.main.character = nil
								ElitistGroup.db.global.main.data = nil
							end
							
							ElitistGroup.modules.Sync:ResetPlayerCache()
						end,
						get = function(info) return ElitistGroup.db.global.main.character == ElitistGroup.playerID end,
						width = "full",
					},
				},
			},
			inspect = {
				order = 3,
				type = "group",
				inline = true,
				name = L["Inspection"],
				args = {
					window = {
						order = 1,
						type = "toggle",
						name = L["Integrate window"],
						desc = L["Adds summary information to the main inspection window."],
					},
					tooltips = {
						order = 2,
						type = "toggle",
						name = L["Integrate tooltips"],
						desc = L["Adds tooltips when mousing over inspected items indicating the items type, and if the gems and enchants pass."],
					},
				},
			},
			database = {
				order = 4,
				type = "group",
				inline = true,
				name = L["Database"],
				args = {
					saveForeign = {
						order = 1,
						type = "toggle",
						name = L["Save foreign server data"],
						desc = L["Any data from another server will not be saved, this includes notes! If you would like most of the data to be pruned but notes kept intact change basic pruning and leave this on."],
					},
					ignoreBelow = {
						order = 2,
						type = "range",
						name = L["Ignore below level"],
						desc = L["Do not require players who are below the given level."],
						min = 0, max = MAX_PLAYER_LEVEL, step = 5,
					},
					pruneBasic = {
						order = 2,
						type = "range",
						name = L["Prune basic data (days)"],
						desc = L["How many days before talents/experience/equipment should be pruned, notes will be kept!\n\nIf the player has no notes or rating on them, all data is removed."],
						min = 1, max = 30, step = 1,
					},
					pruneFull = {
						order = 3,
						type = "range",
						name = L["Prune all data (days)"],
						desc = L["How many days before removing all data on a player. This includes comments and ratings, even your own!"],
						min = 30, max = 365, step = 1,
					},
				},
			},
		},
	}
	
	options.comm = {
		order = 1,
		type = "group",
		name = L["Addon communication"],
		disabled = function(info) return not ElitistGroup.db.profile.comm.enabled end,
		set = function(info, value) ElitistGroup.db.profile.comm.areas[info[#(info)]] = value end,
		get = function(info) return ElitistGroup.db.profile.comm.enabled and ElitistGroup.db.profile.comm.areas[info[#(info)]] end,
		args = {
			comm = {
				order = 1,
				type = "group",
				inline = true,
				name = L["General"],
				args = {
					enabled = {
						order = 1,
						type = "toggle",
						name = L["Enable comms"],
						desc = L["Unchecking this will completely disable all communications in Elitist Group.\n\nYou will not be able to send or receive notes on players, or check gear without inspecting."],
						set = set,
						get = get,
						disabled = false,
					},
					gearRequests = {
						order = 2,
						type = "toggle",
						name = L["Allow gear requests"],
						desc = L["Unchecking this disables other Elitist Group users from requesting your gear without inspecting."],
						set = set,
						get = get,
					},
					autoNotes = {
						order = 3,
						type = "toggle",
						name = L["Auto request notes"],
						desc = L["Automatically requests notes on your group from other Elitist Group users. Only sends requests once per session, and you have to be in a guild."],
						set = set,
						get = get,
					},
					autoMain = {
						order = 4,
						type = "toggle",
						name = L["Auto request main experience"],
						desc = L["Automatically requests main experience (limited at once per an hour) when inspecting."],
						set = set,
						get = get,
					},
				},
			},
			database = {
				order = 2,
				type = "group",
				inline = true,
				name = L["Database"],
				args = {
					databaseSync = {
						order = 1,
						type = "toggle",
						name = L["Allow database syncing"],
						desc = L["Allows both you and other people on your trusted list to send and request your database of users."],
						set = set,
						get = get,
						arg = "comm",
					},
					databaseThreshold = {
						order = 1,
						type = "range",
						name = L["Ignore data older than (days)"],
						desc = L["Any data older than the set number will not be synced."],
						set = set,
						get = get,
						arg = "comm",
						min = 1, max = 365, step = 1,
					},
				},
			},
			enabled = {
				order = 3,
				type = "group",
				inline = true,
				name = L["Enabled channels"],
				args = {
					description = {
						order = 11,
						type = "description",
						name = L["You can choose which channels communication is accepted over. As long as communications are enabled, whisper is accepted. Communications are queued while in combat regardless."],
					},
					GUILD = {
						order = 12,
						type = "toggle",
						name = L["Guild channel"],
					},
					RAID = {
						order = 13,
						type = "toggle",
						name = L["Raid channel"],
					},
					PARTY = {
						order = 14,
						type = "toggle",
						name = L["Party channel"],
					},
					BATTLEGROUND = {
						order = 15,
						type = "toggle",
						name = L["Battleground channel"],
					},
				},
			},
		},
	}
	
	local removeTrustList
	local function rebuildManualTrust()
		for key in pairs(options.trust.args.list.args) do
			if( key ~= "add" and key ~= "sep" ) then
				options.trust.args.list.args[key] = nil
			end
		end
		
		local order = 10
		for idName, textName in pairs(ElitistGroup.db.factionrealm.trusted) do
			options.trust.args.list.args[idName .. "label"] = {
				order = order,
				type = "description",
				name = textName,
				fontSize = "medium",
				width = "half",
			}
			
			options.trust.args.list.args[idName] = {
				order = order + 5,
				type = "execute",
				name = L["Remove"],
				func = removeTrustList,
				width = "half",
			}
			
			options.trust.args.list.args[idName .. "sep"] = {order = order + 7, type = "description", name = ""}
			
			order = order + 10
		end
		
	end
	
	removeTrustList = function(info)
		ElitistGroup.db.factionrealm.trusted[info[#(info)]] = nil
		rebuildManualTrust()
	end
	
	options.trust = {
		order = 3,
		type = "group",
		name = L["Trust management"],
		args = {
			help = {
				order = 0,
				type = "group",
				inline = true,
				name = L["Help"],
				args = {
					help = {
						order = 0,
						type = "description",
						name = L["Trust list is an easy way for you to see at a glance how much faith can be placed in data. It is also used for determining whether somebody can send or receive database and full note requests.\nBoth parties have to be on each others trust lists."],
					},
				},
			},
			comm = {
				order = 1,
				type = "group",
				inline = true,
				name = L["General"],
				args = {
					trustGuild = {
						order = 1,
						type = "toggle",
						name = L["Trust guild members"],
						desc = L["Automatically trust all guild members, if you are in a guild."],
						set = set,
						get = get,
					},
					trustFriends = {
						order = 2,
						type = "toggle",
						name = L["Trust friends"],
						desc = L["Automatically trusts all players on your friends list."],
						set = set,
						get = get,
					},
				},
			},
			list = {
				order = 2,
				type = "group",
				inline = true,
				name = L["Custom list"],
				args = {
					add = {
						order = 1,
						type = "input",
						name = L["Add an user manually"],
						desc = L["Should you want finer control over who is on the trusted list, you can manually add players here.\n\nStored by faction/realm"],
						set = function(info, value)
							if( value and string.trim(value) ~= "" ) then
								ElitistGroup.db.factionrealm.trusted[string.lower(value)] = value
								rebuildManualTrust()
							end
						end,
					},
					sep = {order = 2, type = "header", name = ""},
				},
			},
		},
	}
	
	rebuildManualTrust()
end

SLASH_ELITISTGROUPRATE1 = "/rate"
SlashCmdList["ELITISTGROUPRATE"] = function(msg)
	local Notes = ElitistGroup.modules.Notes
	if( not Notes.haveActiveGroup ) then
		ElitistGroup:Print(L["You need to currently be in a group, or have been in a group to use the rating tool."])
		return
	end
	
	Notes:Show()
end	

SLASH_ELITISTGROUP1 = "/elitistgroup"
SLASH_ELITISTGROUP2 = "/elitistgroups"
SLASH_ELITISTGROUP3 = "/eg"
SlashCmdList["ELITISTGROUP"] = function(msg)
	local cmd, arg = string.split(" ", msg or "", 2)
	cmd = string.lower(cmd or "")

	if( cmd == "config" or cmd == "ui" ) then
		InterfaceOptionsFrame:Show()
		InterfaceOptionsFrame_OpenToCategory("Elitist Group")
		return
	elseif( cmd == "send" and arg ) then
		ElitistGroup.modules.Sync:SendCmdGear(arg)
		return
	elseif( cmd == "gear" and arg ) then
		ElitistGroup.modules.Sync:RequestGear(arg)
		return
	elseif( cmd == "db" ) then
		ElitistGroup.modules.Sync:RequestDatabase(arg)
		return
	elseif( cmd == "notes" ) then
		ElitistGroup.modules.Sync:RequestNotes(arg)
		return
	elseif( cmd == "rate" ) then
		SlashCmdList["ELITISTGROUPRATE"]("")
		return
	elseif( cmd == "leader" and IsAddOnLoaded("ElitistGroupLeader") ) then
		SlashCmdList["EGLEADER"]("")
		return
	elseif( cmd == "reset" ) then
		if( not StaticPopupDialogs["ELITISTGROUP_CONFIRM_RESET"] ) then
			StaticPopupDialogs["ELITISTGROUP_CONFIRM_RESET"] = {
				text = L["Are you sure you want to reset ALL user data recorded, including notes?"],
				button1 = L["Yes"],
				button2 = L["No"],
				OnAccept = function()
					table.wipe(ElitistGroup.userData)

					ElitistGroup.db.faction.users = {}
					ElitistGroup.db.faction.lastModified = {}
					ElitistGroup.writeQueue = {}
					ElitistGroup.modules.Scan:InspectUnit("player")
					ElitistGroup.modules.Users:ResetUserList()
					
					ElitistGroup:Print(L["Reset all user data."])
				end,
				timeout = 30,
				whileDead = 1,
				hideOnEscape = 1,
			}
		end
		
		StaticPopup_Show("ELITISTGROUP_CONFIRM_RESET")
		return
	elseif( cmd == "report" ) then
		if( GetNumPartyMembers() == 0 and GetNumRaidMembers() == 0 ) then
			ElitistGroup:Print(L["You must be in a group to use this."])
			return
		end
		
		ElitistGroup.modules.Report:Show()
		return
	elseif( cmd == "summary" ) then
		local instanceType = select(2, IsInInstance())
		if( GetNumPartyMembers() == 0 and GetNumRaidMembers() == 0 ) then
			ElitistGroup:Print(L["You must be in a group to use this."])
			return
		end
	
		if( GetNumRaidMembers() > 0 ) then
			ElitistGroup.modules.RaidSummary:Show()
		else
			ElitistGroup.modules.PartySummary:Show()
		end
		return
	elseif( cmd == "help" or cmd == "notes" or cmd == "gear" or cmd == "send" ) then
		ElitistGroup:Print(L["Slash commands (/eg, /elitistgroup)"])
		DEFAULT_CHAT_FRAME:AddMessage(L["/eg config - Opens the configuration"])
		DEFAULT_CHAT_FRAME:AddMessage(L["/eg gear <name> - Requests gear from another Elitist Group user without inspecting"])
		DEFAULT_CHAT_FRAME:AddMessage(L["/eg send <name> - Sends your gear to another Elitist Group user"])
		DEFAULT_CHAT_FRAME:AddMessage(L["/eg notes [name] - Requests all guild members notes on players, if [name] is passed requests notes FROM [name]"])
		DEFAULT_CHAT_FRAME:AddMessage(L["/eg db [name] - Requests either everyones database or [name]s database if specified"])
		DEFAULT_CHAT_FRAME:AddMessage(L["/eg report - Opens the reporting UI for sending to chat summaries on your group"])
		DEFAULT_CHAT_FRAME:AddMessage(L["/eg summary - Displays the summary page for your party or raid"])
		DEFAULT_CHAT_FRAME:AddMessage(L["/eg rate - Opens the rating panel for your group"])
		if( IsAddOnLoaded("ElitistGroupLeader") ) then
			DEFAULT_CHAT_FRAME:AddMessage(L["/eg leader - Opens the specialized group manager/former UI"])
		end
		
		DEFAULT_CHAT_FRAME:AddMessage(L["/eg <name> - When <name> is passed opens up the player viewer for that person, otherwise it opens it on yourself"])
		return
	end
	
	-- Show the players data
	if( cmd == "" ) then
		local playerID
		if( UnitExists("target") and UnitIsFriend("target", "player") and not UnitIsUnit("target", "player") and UnitIsPlayer("target") ) then
			if( CanInspect("target", true) ) then
				playerID = ElitistGroup:GetPlayerID("target")
				if( not ElitistGroup.userData[playerID] and ElitistGroup.modules.Scan:GetInspectTimer() ) then
					ElitistGroup:Print(string.format(L["Cannot inspect %s yet, you have to wait %.1f seconds before you can inspect again."], UnitName("target"), ElitistGroup.modules.Scan:GetInspectTimer()))
				elseif( not ElitistGroup.modules.Scan:IsInspectPending() ) then
					ElitistGroup.modules.Scan:InspectUnit("target")
					ElitistGroup.modules.Sync:RequestMainData("target")
				elseif( not ElitistGroup.userData[playerID] ) then
					ElitistGroup:Print(string.format(L["No data found for %s, and an inspection is pending. You'll have to wait a second and try again."], UnitName("target")))
				end
			end
		else
			ElitistGroup.modules.Scan:InspectUnit("player")
			playerID = ElitistGroup.playerID
		end

		local userData = playerID and ElitistGroup.userData[playerID]
		if( userData ) then
			ElitistGroup.modules.Users:Show(userData)
		end
		return
	end
	
	local data
	local search = not string.match(cmd, "%-") and string.format("^%s%%-", cmd)
	for name in pairs(ElitistGroup.db.faction.users) do
		if( ( search and string.match(string.lower(name), search) ) or ( string.lower(name) == cmd ) ) then
			data = ElitistGroup.userData[name]
			break
		end
	end
	
	if( not data ) then
		ElitistGroup:Print(string.format(L["Cannot find record of %s in your saved database."], msg))
		return
	end
	
	ElitistGroup.modules.Users:Show(data)
end

local register = CreateFrame("Frame", nil, InterfaceOptionsFrame)
register:SetScript("OnShow", function(self)
	self:SetScript("OnShow", nil)
 
	local AceConfig = LibStub("AceConfig-3.0")
	AceConfigDialog = LibStub("AceConfigDialog-3.0")
	AceConfigRegistery = LibStub("AceConfigRegistry-3.0")
	
	loadOptions()

	AceConfigRegistery:RegisterOptionsTable("ElitistGroup", options.general)
	AceConfigDialog:AddToBlizOptions("ElitistGroup", "Elitist Group")
	
	AceConfigRegistery:RegisterOptionsTable("ElitistGroup-Sync", options.comm)
	AceConfigDialog:AddToBlizOptions("ElitistGroup-Sync", options.comm.name, "Elitist Group")

	AceConfigRegistery:RegisterOptionsTable("ElitistGroup-Trusted", options.trust)
	AceConfigDialog:AddToBlizOptions("ElitistGroup-Trusted", options.trust.name, "Elitist Group")

	local profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(ElitistGroup.db, true)
	AceConfigRegistery:RegisterOptionsTable("ElitistGroup-Profile", profile)
	AceConfigDialog:AddToBlizOptions("ElitistGroup-Profile", profile.name, "Elitist Group")
end)
