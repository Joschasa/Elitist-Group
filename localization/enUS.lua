local ElitistGroup = select(2, ...)
local L = {}
L["--"] = "--"
L["---"] = "---"
L["<1 minute old"] = "<1 minute old"
L["Active"] = "Active"
L["Add"] = "Add"
L["Add an user manually"] = "Add an user manually"
L["Addon communication"] = "Addon communication"
L["Adds summary information to the main inspection window."] = "Adds summary information to the main inspection window."
L["Adds tooltips when mousing over inspected items indicating the items type, and if the gems and enchants pass."] = "Adds tooltips when mousing over inspected items indicating the items type, and if the gems and enchants pass."
L["Affliction"] = "Affliction"
L["After completing a dungeon through the Looking For Dungeon system, automatically popup the /rate frame so you can set notes and rating on your group members."] = "After completing a dungeon through the Looking For Dungeon system, automatically popup the /rate frame so you can set notes and rating on your group members."
L["Alerts you in chat when you receive new notes or gear information from somebody."] = "Alerts you in chat when you receive new notes or gear information from somebody."
L["Alert when grouped with low rated players"] = "Alert when grouped with low rated players"
L["All"] = "All"
L["Allow database syncing"] = "Allow database syncing"
L["Allow gear requests"] = "Allow gear requests"
L["Allows both you and other people on your trusted list to send and request your database of users."] = "Allows both you and other people on your trusted list to send and request your database of users."
L["ALT + Left Click - Open report window for group"] = "ALT + Left Click - Open report window for group"
L["ALT + Right Click - Open rating window for party"] = "ALT + Right Click - Open rating window for party"
L["ALT + Right Click - Open rating window for raid"] = "ALT + Right Click - Open rating window for raid"
L["Always bad"] = "Always bad"
L["Always process group queue"] = "Always process group queue"
L["Announce synced data"] = "Announce synced data"
L["Any data from another server will not be saved, this includes notes! If you would like most of the data to be pruned but notes kept intact change basic pruning and leave this on."] = "Any data from another server will not be saved, this includes notes! If you would like most of the data to be pruned but notes kept intact change basic pruning and leave this on."
L["Any data older than the set number will not be synced."] = "Any data older than the set number will not be synced."
L["Arcane"] = "Arcane"
L["Are you sure you want to reset ALL user data recorded, including notes?"] = "Are you sure you want to reset ALL user data recorded, including notes?"
L["armor by"] = "armor by"
L["armor for"] = "armor for"
L["Arms"] = "Arms"
L["Assassination"] = "Assassination"
L["Automatically"] = "Automatically"
L["Automatically requests main experience (limited at once per an hour) when inspecting."] = "Automatically requests main experience (limited at once per an hour) when inspecting."
L["Automatically requests notes on your group from other Elitist Group users. Only sends requests once per session, and you have to be in a guild."] = "Automatically requests notes on your group from other Elitist Group users. Only sends requests once per session, and you have to be in a guild."
L["Automatically trust all guild members, if you are in a guild."] = "Automatically trust all guild members, if you are in a guild."
L["Automatically trusts all players on your friends list."] = "Automatically trusts all players on your friends list."
L["Auto request main experience"] = "Auto request main experience"
L["Auto request notes"] = "Auto request notes"
L["Average"] = "Average"
L["[average ilvl]"] = "[average ilvl]"
L["average item level below %d"] = "average item level below %d"
L["Average item level of the players equipment."] = "Average item level of the players equipment."
L["Average rating %.2f of %d, rated %d times."] = "Average rating %.2f of %d, rated %d times."
L["[bad enchants]"] = "[bad enchants]"
L["[bad equipment]"] = "[bad equipment]"
L["[bad gems]"] = "[bad gems]"
L["Balance"] = "Balance"
L["Baradin Hold"] = "Baradin Hold"
L["Bastion of Twilight"] = "Bastion of Twilight"
L["Battleground channel"] = "Battleground channel"
L["Beast Mastery"] = "Beast Mastery"
L["Blackwing Descent"] = "Blackwing Descent"
L["Blood"] = "Blood"
L["c%-\"(.-)\""] = "c%-\"(.-)\""
L["Cannot find record of %s in your saved database."] = "Cannot find record of %s in your saved database."
L["Cannot find URL for this player, don't seem to have name, server or region data."] = "Cannot find URL for this player, don't seem to have name, server or region data."
L["Cannot inspect %s yet, you have to wait %.1f seconds before you can inspect again."] = "Cannot inspect %s yet, you have to wait %.1f seconds before you can inspect again."
L["Caster (All)"] = "Caster (All)"
L["Caster (Spirit)"] = "Caster (Spirit)"
L["|cff%02x%02x00%d|r avg, %s (%s)"] = "|cff%02x%02x00%d|r avg, %s (%s)"
L["[|cff%02x%02x00%d%%|r] Enchants"] = "[|cff%02x%02x00%d%%|r] Enchants"
L["[|cff%02x%02x00%d%%|r] Equipment (%s%d|r)"] = "[|cff%02x%02x00%d%%|r] Equipment (%s%d|r)"
L["[|cff%02x%02x00%d%%|r] Gems"] = "[|cff%02x%02x00%d%%|r] Gems"
L["[|cff%02x%02x00%d%%|r] [%s%d|r] Equipment"] = "[|cff%02x%02x00%d%%|r] [%s%d|r] Equipment"
L["|cfffed000Item Type:|r %s%s"] = "|cfffed000Item Type:|r %s%s"
L["[|cffff20200%|r] Enchants"] = "[|cffff20200%|r] Enchants"
L["[|cffff20200%|r] Gems"] = "[|cffff20200%|r] Gems"
L["|cffff2020%d unspent |4point:points;|r"] = "|cffff2020%d unspent |4point:points;|r"
L["|cffff2020%d unspent|r (Secondary)"] = "|cffff2020%d unspent|r (Secondary)"
L["|cffff2020Warning!|r %s is in your group, you rated them %d"] = "|cffff2020Warning!|r %s is in your group, you rated them %d"
L["|cffff2020Warning!|r %s is in your group, you rated them %d for: %s"] = "|cffff2020Warning!|r %s is in your group, you rated them %d for: %s"
L[ [=[
|cffffffffAND|r
]=] ] = [=[
|cffffffffAND|r
]=]
L[ [=[
|cffffffffOR|r
]=] ] = [=[
|cffffffffOR|r
]=]
L["|cffffffff%s|r %s, %s role."] = "|cffffffff%s|r %s, %s role."
L[ [=[|cffffffff%s|r %s, %s role.

The player has not spent %d talent points.]=] ] = [=[|cffffffff%s|r %s, %s role.

The player has not spent %d talent points.]=]
L[ [=[|cffffffff%s|r %s, %s role.

The player put all of his talent points into one tree.]=] ] = [=[|cffffffff%s|r %s, %s role.

The player put all of his talent points into one tree.]=]
L["chance on melee and range"] = "chance on melee and range"
L["chance on melee attack"] = "chance on melee attack"
L["chance on melee or range"] = "chance on melee or range"
L["Channel to report Elitist Group summary to."] = "Channel to report Elitist Group summary to."
L["Classes"] = "Classes"
L["Click to open and close the database viewer."] = "Click to open and close the database viewer."
L["Click to view detailed information."] = "Click to view detailed information."
L["Combat"] = "Combat"
L["Comment"] = "Comment"
L["Comment..."] = "Comment..."
L["Completed %s! Type /rate to rate this group."] = "Completed %s! Type /rate to rate this group."
L["Could not calculate average item level, no data found."] = "Could not calculate average item level, no data found."
L[ [=[Current filters are all players who have:

]=] ] = [=[Current filters are all players who have:

]=]
L["Custom list"] = "Custom list"
L["<= %d"] = "<= %d"
L["> %d%%"] = "> %d%%"
L["%d |4day:days;"] = "%d |4day:days;"
L["%d |4day:days; old"] = "%d |4day:days; old"
L["%d |4hour:hours;"] = "%d |4hour:hours;"
L["%d |4hour:hours; old"] = "%d |4hour:hours; old"
L["%d |4minute:minutes;"] = "%d |4minute:minutes;"
L["%d |4minute:minutes; old"] = "%d |4minute:minutes; old"
L["Database"] = "Database"
L["Data for this player is from a verified source and can be trusted."] = "Data for this player is from a verified source and can be trusted."
L[ [=[Data has been pruned to save database space.

Perhaps you want to change prune settings in /eg config?]=] ] = [=[Data has been pruned to save database space.

Perhaps you want to change prune settings in /eg config?]=]
L["Data is loading, please wait."] = "Data is loading, please wait."
L["%d average rating"] = "%d average rating"
L[">= %d%% bad enchants"] = ">= %d%% bad enchants"
L["> %d%% bad gear"] = "> %d%% bad gear"
L[">= %d%% bad gems"] = ">= %d%% bad gems"
L["deal damage"] = "deal damage"
L["Delete"] = "Delete"
L["Demonology"] = "Demonology"
L["Destruction"] = "Destruction"
L["Discipline"] = "Discipline"
L[ [=[Do not abuse this!

Abuse will result in the feature being removed.]=] ] = [=[Do not abuse this!

Abuse will result in the feature being removed.]=]
L["Do not require players who are below the given level."] = "Do not require players who are below the given level."
L["Don't include"] = "Don't include"
L["Don't include enchants"] = "Don't include enchants"
L["Don't include gear"] = "Don't include gear"
L["Don't include gems"] = "Don't include gems"
L["Don't include item level"] = "Don't include item level"
L["%d%% or more bad enchants"] = "%d%% or more bad enchants"
L["%d%% or more bad equipped items"] = "%d%% or more bad equipped items"
L["%d%% or more bad gems"] = "%d%% or more bad gems"
L["DPS (All)"] = "DPS (All)"
L["DPS (Caster)"] = "DPS (Caster)"
L["DPS, Caster"] = "DPS, Caster"
L["DPS (Melee)"] = "DPS (Melee)"
L["DPS, Melee"] = "DPS, Melee"
L["DPS (Physical)"] = "DPS (Physical)"
L["DPS (Ranged)"] = "DPS (Ranged)"
L["DPS, Ranged"] = "DPS, Ranged"
L["Dungeon"] = "Dungeon"
L["Dungeons"] = "Dungeons"
L["%d unspent |4point:points;"] = "%d unspent |4point:points;"
L[" (%d unused |4socket:sockets;)"] = " (%d unused |4socket:sockets;)"
L["Edit"] = "Edit"
L["/eg config - Opens the configuration"] = "/eg config - Opens the configuration"
L["/eg db [name] - Requests either everyones database or [name]s database if specified"] = "/eg db [name] - Requests either everyones database or [name]s database if specified"
L["/eg gear <name> - Requests gear from another Elitist Group user without inspecting"] = "/eg gear <name> - Requests gear from another Elitist Group user without inspecting"
L["/eg leader - Opens the specialized group manager/former UI"] = "/eg leader - Opens the specialized group manager/former UI"
L["/eg <name> - When <name> is passed opens up the player viewer for that person, otherwise it opens it on yourself"] = "/eg <name> - When <name> is passed opens up the player viewer for that person, otherwise it opens it on yourself"
L["/eg notes [name] - Requests all guild members notes on players, if [name] is passed requests notes FROM [name]"] = "/eg notes [name] - Requests all guild members notes on players, if [name] is passed requests notes FROM [name]"
L["/eg rate - Opens the rating panel for your group"] = "/eg rate - Opens the rating panel for your group"
L["/eg report - Opens the reporting UI for sending to chat summaries on your group"] = "/eg report - Opens the reporting UI for sending to chat summaries on your group"
L["/eg send <name> - Sends your gear to another Elitist Group user"] = "/eg send <name> - Sends your gear to another Elitist Group user"
L["/eg summary - Displays the summary page for your party or raid"] = "/eg summary - Displays the summary page for your party or raid"
L["Elemental"] = "Elemental"
L["Elitist Group (%s): showing %d players. Format is, [name] (%s)"] = "Elitist Group (%s): showing %d players. Format is, [name] (%s)"
L["Enable comms"] = "Enable comms"
L["Enabled channels"] = "Enabled channels"
L["Enchant"] = "Enchant"
L["Enchant: |cffff2020[!]|r |cffffffffNone found|r"] = "Enchant: |cffff2020[!]|r |cffffffffNone found|r"
L["Enchant: |cffff2020[!]|r |cffffffff%s|r enchant"] = "Enchant: |cffff2020[!]|r |cffffffff%s|r enchant"
L["Enchant: |cffffffffCannot enchant|r"] = "Enchant: |cffffffffCannot enchant|r"
L["Enchant: |cffffffffPass|r"] = "Enchant: |cffffffffPass|r"
L["Enchants"] = "Enchants"
L["Enchants [|cff%02x%02x00%d%%|r]"] = "Enchants [|cff%02x%02x00%d%%|r]"
L["Enchants [|cffff20200%|r]"] = "Enchants [|cffff20200%|r]"
L["Enchants: |cffffffff%d bad|r"] = "Enchants: |cffffffff%d bad|r"
L["Enchants: |cffffffffPass|r"] = "Enchants: |cffffffffPass|r"
L["Enchants: |cffffffffThe player does not have any enchants|r"] = "Enchants: |cffffffffThe player does not have any enchants|r"
L["Enhancement"] = "Enhancement"
L["Equipment"] = "Equipment"
L["Equipment: |cffffffff%d bad items found|r"] = "Equipment: |cffffffff%d bad items found|r"
L["Equipment: |cffffffffPass|r"] = "Equipment: |cffffffffPass|r"
L["Experience"] = "Experience"
L["Experienced"] = "Experienced"
L["fear duration"] = "fear duration"
L["Feral"] = "Feral"
L["Fire"] = "Fire"
L["Frost"] = "Frost"
L["Fury"] = "Fury"
L["Gear"] = "Gear"
L["Gear received from %s."] = "Gear received from %s."
L["Gems"] = "Gems"
L["Gems [|cff%02x%02x00%d%%|r]"] = "Gems [|cff%02x%02x00%d%%|r]"
L["Gems [|cffff20200%|r]"] = "Gems [|cffff20200%|r]"
L["Gems: |cffff2020[!]|r |cffffffff%d bad|r%s"] = "Gems: |cffff2020[!]|r |cffffffff%d bad|r%s"
L["Gems: |cffffffff%d bad|r"] = "Gems: |cffffffff%d bad|r"
L["Gems: |cffffffffFailed to find any gems|r"] = "Gems: |cffffffffFailed to find any gems|r"
L["Gems: |cffffffffNo sockets|r"] = "Gems: |cffffffffNo sockets|r"
L["Gems: |cffffffffPass|r"] = "Gems: |cffffffffPass|r"
L["Gems/Enchant"] = "Gems/Enchant"
L["General"] = "General"
L["Great"] = "Great"
L["guild"] = "guild"
L["Guild"] = "Guild"
L["Guild channel"] = "Guild channel"
L["Hard"] = "Hard"
L["harmful spell"] = "harmful spell"
L["Healer"] = "Healer"
L["Healer (All)"] = "Healer (All)"
L["Healer/DPS"] = "Healer/DPS"
L["Healing Priest/Druid"] = "Healing Priest/Druid"
L["Help"] = "Help"
L["helpful spell"] = "helpful spell"
L["Heroic"] = "Heroic"
L["Holy"] = "Holy"
L["How many days before removing all data on a player. This includes comments and ratings, even your own!"] = "How many days before removing all data on a player. This includes comments and ratings, even your own!"
L[ [=[How many days before talents/experience/equipment should be pruned, notes will be kept!

If the player has no notes or rating on them, all data is removed.]=] ] = [=[How many days before talents/experience/equipment should be pruned, notes will be kept!

If the player has no notes or rating on them, all data is removed.]=]
L["How many inspects to save"] = "How many inspects to save"
L["If you leave a rating on somebody of 2 or less, the next time you group with them you will get a warning in chat."] = "If you leave a rating on somebody of 2 or less, the next time you group with them you will get a warning in chat."
L["Ignore below level"] = "Ignore below level"
L["Ignore data older than (days)"] = "Ignore data older than (days)"
L["Inexperienced"] = "Inexperienced"
L["Inspecting only in an instance"] = "Inspecting only in an instance"
L["Inspection"] = "Inspection"
L["Inspect queue empty"] = "Inspect queue empty"
L["Instead of listing item link when viewing overall status, you'll instead see the name of the slot."] = "Instead of listing item link when viewing overall status, you'll instead see the name of the slot."
L["Integrate tooltips"] = "Integrate tooltips"
L["Integrate window"] = "Integrate window"
L["Item #%d not in cache"] = "Item #%d not in cache"
L["Item levels <= %d"] = "Item levels <= %d"
L["Left Click - Open player/target information"] = "Left Click - Open player/target information"
L["Loading"] = "Loading"
L["Loading data"] = "Loading data"
L["magical heals"] = "magical heals"
L["Main/alt experience"] = "Main/alt experience"
L[ [=[Main/alt experience is a way of letting other Elitist Group users see that you have experience in dungeons on more than one character. By setting a main, when people inspect your alt they will see your experience on both your main and alt. Your main will remain anonymous, only the experience data is shown to other users.
This will only show up for people who inspect you.]=] ] = [=[Main/alt experience is a way of letting other Elitist Group users see that you have experience in dungeons on more than one character. By setting a main, when people inspect your alt they will see your experience on both your main and alt. Your main will remain anonymous, only the experience data is shown to other users.
This will only show up for people who inspect you.]=]
L["Mains experience on left, %s on right"] = "Mains experience on left, %s on right"
L["Make %s my main"] = "Make %s my main"
L["Marksmanship"] = "Marksmanship"
L["Match all filters"] = "Match all filters"
L[ [=[Match all item level, gear, enchant and gem filters to report.

If unchecked, only have to match one.]=] ] = [=[Match all item level, gear, enchant and gem filters to report.

If unchecked, only have to match one.]=]
L["Melee (Agi)"] = "Melee (Agi)"
L["Melee (Str)"] = "Melee (Str)"
L["melee and ranged"] = "melee and ranged"
L["melee or range"] = "melee or range"
L["n%-\"(.-)\""] = "n%-\"(.-)\""
L["Name"] = "Name"
L["Nearly-experienced"] = "Nearly-experienced"
L["No"] = "No"
L[" (no belt buckle)"] = " (no belt buckle)"
L["Nobody in your group matched the entered filters."] = "Nobody in your group matched the entered filters."
L["No channel selected"] = "No channel selected"
L["No comment"] = "No comment"
L["No data found for %s, and an inspection is pending. You'll have to wait a second and try again."] = "No data found for %s, and an inspection is pending. You'll have to wait a second and try again."
L["No data found on group, you might need to wait a minute for it to load."] = "No data found on group, you might need to wait a minute for it to load."
L["No enchants found"] = "No enchants found"
L["No enchants found."] = "No enchants found."
L["No filters are enabled, nothing to report based off of."] = "No filters are enabled, nothing to report based off of."
L["No filters setup, you need at least one to report."] = "No filters setup, you need at least one to report."
L["No gems found."] = "No gems found."
L["No gems found. Possibly due to a data error, but most likely they do not have any."] = "No gems found. Possibly due to a data error, but most likely they do not have any."
L["No item equipped"] = "No item equipped"
L["No notes found"] = "No notes found"
L["No notes were found for this player."] = "No notes were found for this player."
L["No player found for unit %s."] = "No player found for unit %s."
L["No rating data on this player found."] = "No rating data on this player found."
L["Normal"] = "Normal"
L["No secondary spec"] = "No secondary spec"
L["Notes (%d)"] = "Notes (%d)"
L["Nothing is wrong with this players enchants!"] = "Nothing is wrong with this players enchants!"
L["Nothing is wrong with this players equipment!"] = "Nothing is wrong with this players equipment!"
L["Nothing is wrong with this players gems!"] = "Nothing is wrong with this players gems!"
L["Not rated"] = "Not rated"
L["officer"] = "officer"
L["Officer"] = "Officer"
L["Ok"] = "Ok"
L["Other players have left a note on this person."] = "Other players have left a note on this person."
L["party"] = "party"
L["Party"] = "Party"
L["Party channel"] = "Party channel"
L["periodic damage"] = "periodic damage"
L["Physical (All)"] = "Physical (All)"
L["Pit Lord Argaloth"] = "Pit Lord Argaloth"
L["Player info"] = "Player info"
L["Play on alts all the time? Check out /eg config -> Main/alt experience to have your mains achievements carry over."] = "Play on alts all the time? Check out /eg config -> Main/alt experience to have your mains achievements carry over."
L["Pops up the summary window when you first zone into an instance using the Looking for Dungeon system showing you info on your group."] = "Pops up the summary window when you first zone into an instance using the Looking for Dungeon system showing you info on your group."
L["Protection"] = "Protection"
L["Prune all data (days)"] = "Prune all data (days)"
L["Prune basic data (days)"] = "Prune basic data (days)"
L["PVP"] = "PVP"
L["PVP/Elemental Shaman"] = "PVP/Elemental Shaman"
L["Queue: %d players left"] = "Queue: %d players left"
L["raid"] = "raid"
L["Raid"] = "Raid"
L["Raid channel"] = "Raid channel"
L["Raids"] = "Raids"
L["ranged critical"] = "ranged critical"
L["Rated %d of %d"] = "Rated %d of %d"
L["Rating"] = "Rating"
L["Remove"] = "Remove"
L["Report"] = "Report"
L["Report to channel %s"] = "Report to channel %s"
L["Requested gear from %s, this might take a second."] = "Requested gear from %s, this might take a second."
L["Requesting Elitist Group database from %s. Keep in mind this is hard throttled at once per hour."] = "Requesting Elitist Group database from %s. Keep in mind this is hard throttled at once per hour."
L["Requesting Elitist Group databases from everyone in your guild, this could take a while. Keep in mind this is hard throttled at once per hour."] = "Requesting Elitist Group databases from everyone in your guild, this could take a while. Keep in mind this is hard throttled at once per hour."
L["Requesting Elitist Group notes from everyone in your guild, this could take a minute. Keep in mind this is hard throttled at onnce every 30 minutes."] = "Requesting Elitist Group notes from everyone in your guild, this could take a minute. Keep in mind this is hard throttled at onnce every 30 minutes."
L["Requesting Elitist Group notes from %s. Keep in mind this is hard throttled at once every 30 minutes."] = "Requesting Elitist Group notes from %s. Keep in mind this is hard throttled at once every 30 minutes."
L["Reset all user data."] = "Reset all user data."
L["Restoration"] = "Restoration"
L["Retribution"] = "Retribution"
L["Right Click - Open summary for your party"] = "Right Click - Open summary for your party"
L["Right Click - Open summary for your raid"] = "Right Click - Open summary for your raid"
L["Role"] = "Role"
L["root duration"] = "root duration"
L["run speed"] = "run speed"
L["s%-\"(.-)\""] = "s%-\"(.-)\""
L["Save foreign server data"] = "Save foreign server data"
L["%s - |cffffffff%d|r missing |4gem:gems;"] = "%s - |cffffffff%d|r missing |4gem:gems;"
L["%s - |cffffffff%s|r"] = "%s - |cffffffff%s|r"
L["%s - |cffffffff%s|r gem"] = "%s - |cffffffff%s|r gem"
L["%s - |cffffffff%s|r item"] = "%s - |cffffffff%s|r item"
L["%s - |cffffffff%s|r quality gem"] = "%s - |cffffffff%s|r quality gem"
L["%s does not have any users to send you."] = "%s does not have any users to send you."
L["(%s%d|r) Gear [|cff%02x%02x00%d%%|r]"] = "(%s%d|r) Gear [|cff%02x%02x00%d%%|r]"
L["Search..."] = "Search..."
L["Secondary"] = "Secondary"
L[ [=[Seen as %s - %s:
|cffffffff%s|r]=] ] = [=[Seen as %s - %s:
|cffffffff%s|r]=]
L["%s either disabled database syncing, or you are not on their trusted list."] = "%s either disabled database syncing, or you are not on their trusted list."
L["Select all"] = "Select all"
L["Semi-experienced"] = "Semi-experienced"
L["Sent your gear to %s! It will arrive in a few seconds"] = "Sent your gear to %s! It will arrive in a few seconds"
L["Set role as damage."] = "Set role as damage."
L["Set role as healer."] = "Set role as healer."
L["Set role as tank."] = "Set role as tank."
L["Shadow"] = "Shadow"
L[ [=[Should you want finer control over who is on the trusted list, you can manually add players here.

Stored by faction/realm]=] ] = [=[Should you want finer control over who is on the trusted list, you can manually add players here.

Stored by faction/realm]=]
L["Show rating after dungeon"] = "Show rating after dungeon"
L["Show slot names"] = "Show slot names"
L["Show summary on dungeon start"] = "Show summary on dungeon start"
L["silence duration"] = "silence duration"
L["Slash commands (/eg, /elitistgroup)"] = "Slash commands (/eg, /elitistgroup)"
L["%s - Missing belt buckle or gem"] = "%s - Missing belt buckle or gem"
L["spell damage"] = "spell damage"
L["%s, %s"] = "%s, %s"
L["%s - %s, level %s %s."] = "%s - %s, level %s %s."
L["%s - %s, level %s, unknown class."] = "%s - %s, level %s, unknown class."
L["%s, %s role."] = "%s, %s role."
L[ [=[%s, %s role.

This player has not spent all of their talent points!]=] ] = [=[%s, %s role.

This player has not spent all of their talent points!]=]
L["%s: %s - %s, level %s %s"] = "%s: %s - %s, level %s %s"
L["%s: %s - %s, level %s, unknown class"] = "%s: %s - %s, level %s, unknown class"
L["%s (Trusted)"] = "%s (Trusted)"
L["stun duration"] = "stun duration"
L["stun resistance"] = "stun resistance"
L["Subtlety"] = "Subtlety"
L["Suggested dungeons"] = "Suggested dungeons"
L["Suitational (Caster)"] = "Suitational (Caster)"
L["Suitational (Healer)"] = "Suitational (Healer)"
L["%s - Unenchanted"] = "%s - Unenchanted"
L["%s, unknown class"] = "%s, unknown class"
L["%s (Untrusted)"] = "%s (Untrusted)"
L["Survival"] = "Survival"
L["T11 Dungeons"] = "T11 Dungeons"
L["Talents unavailable"] = "Talents unavailable"
L["Tank"] = "Tank"
L["Tank/DPS"] = "Tank/DPS"
L["Tank/PVP"] = "Tank/PVP"
L["Tank/Ranged DPS"] = "Tank/Ranged DPS"
L["Terrible"] = "Terrible"
L["The data you see should be accurate. However, it is not guaranteed as it is from an unverified source."] = "The data you see should be accurate. However, it is not guaranteed as it is from an unverified source."
L["The player has not purchased dual specialization yet."] = "The player has not purchased dual specialization yet."
L["Throne of the Four Winds"] = "Throne of the Four Winds"
L["Trust friends"] = "Trust friends"
L["Trust guild members"] = "Trust guild members"
L["Trust list and addon communication options can be found in the menu to your left."] = "Trust list and addon communication options can be found in the menu to your left."
L[ [=[Trust list is an easy way for you to see at a glance how much faith can be placed in data. It is also used for determining whether somebody can send or receive database and full note requests.
Both parties have to be on each others trust lists.]=] ] = [=[Trust list is an easy way for you to see at a glance how much faith can be placed in data. It is also used for determining whether somebody can send or receive database and full note requests.
Both parties have to be on each others trust lists.]=]
L["Trust management"] = "Trust management"
L["Unchecking this disables other Elitist Group users from requesting your gear without inspecting."] = "Unchecking this disables other Elitist Group users from requesting your gear without inspecting."
L[ [=[Unchecking this will completely disable all communications in Elitist Group.

You will not be able to send or receive notes on players, or check gear without inspecting.]=] ] = [=[Unchecking this will completely disable all communications in Elitist Group.

You will not be able to send or receive notes on players, or check gear without inspecting.]=]
L["Unholy"] = "Unholy"
L["Unknown"] = "Unknown"
L["URL"] = "URL"
L["User data not available yet."] = "User data not available yet."
L["User data pruned"] = "User data pruned"
L["User %s is or went offline during syncing."] = "User %s is or went offline during syncing."
L["View"] = "View"
L["View info on %s."] = "View info on %s."
L["Welcome! Type /elitistgroup help (or /eg help) to see a list of available slash commands."] = "Welcome! Type /elitistgroup help (or /eg help) to see a list of available slash commands."
L["When automatically scanning your group, this is the number of inspects that will be saved so you can still inspect other people while the scan runs.|n|nThe more inspects you keep, the longer a scan will take."] = "When automatically scanning your group, this is the number of inspects that will be saved so you can still inspect other people while the scan runs.|n|nThe more inspects you keep, the longer a scan will take."
L["When /eg summary is closed, the group inspect queue will always be processed.|n|nUnchecking this means the inspect queue is reset when /eg summary is closed."] = "When /eg summary is closed, the group inspect queue will always be processed.|n|nUnchecking this means the inspect queue is reset when /eg summary is closed."
L["when hit"] = "when hit"
L[ [=[Whether enchants should be included in the report.

When set, it will show people with a percentage of bad enchants higher than the entered amount.]=] ] = [=[Whether enchants should be included in the report.

When set, it will show people with a percentage of bad enchants higher than the entered amount.]=]
L[ [=[Whether equipment should be included in the report.

When set, it will show people with a percentage of bad gear higher than the entered amount.]=] ] = [=[Whether equipment should be included in the report.

When set, it will show people with a percentage of bad gear higher than the entered amount.]=]
L["Whether item level should be included in the report, or only show average item levels below the selected value."] = "Whether item level should be included in the report, or only show average item levels below the selected value."
L["While the player data should be accurate, it is not guaranteed as the source is unverified."] = "While the player data should be accurate, it is not guaranteed as the source is unverified."
L["Yes"] = "Yes"
L["You are not inside chat channel #%d, can't send report."] = "You are not inside chat channel #%d, can't send report."
L["You can choose which channels communication is accepted over. As long as communications are enabled, whisper is accepted. Communications are queued while in combat regardless."] = "You can choose which channels communication is accepted over. As long as communications are enabled, whisper is accepted. Communications are queued while in combat regardless."
L["You can edit or add a note on this player here."] = "You can edit or add a note on this player here."
L["You cannot request the database of everyone in your guild without being a guild!"] = "You cannot request the database of everyone in your guild without being a guild!"
L["You cannot request the notes of everyone in your guild without being a guild!"] = "You cannot request the notes of everyone in your guild without being a guild!"
L["You can only send a report once every 60 seconds."] = "You can only send a report once every 60 seconds."
L["You did not set a channel to report to."] = "You did not set a channel to report to."
L["You have not set a main yet."] = "You have not set a main yet."
L["You have to add %s to your trusted list before you can use this."] = "You have to add %s to your trusted list before you can use this."
L["You have to enter a name for this to work."] = "You have to enter a name for this to work."
L["You must be in a group to use this."] = "You must be in a group to use this."
L["You need to be in a guild to output to this channel."] = "You need to be in a guild to output to this channel."
L["You need to be in a party to output to this channel."] = "You need to be in a party to output to this channel."
L["You need to be in a raid to output to this channel."] = "You need to be in a raid to output to this channel."
L["You need to currently be in a group, or have been in a group to use the rating tool."] = "You need to currently be in a group, or have been in a group to use the rating tool."
L["You need to enable database syncing in /eg config -> Addon communication to use this."] = "You need to enable database syncing in /eg config -> Addon communication to use this."
L["Your main is currently: %s."] = "Your main is currently: %s."
L[ [=[You wrote %s ago:
|cffffffff%s|r]=] ] = [=[You wrote %s ago:
|cffffffff%s|r]=]


L["Cloth"] = "Cloth"
L["Leather"] = "Leather"
L["Mail"] = "Mail"
L["Plate"] = "Plate"
L["%s - Missing specialization bonus"] = "%s - Missing specialization bonus"


ElitistGroup.L = L
--[===[@debug@
ElitistGroup.L = setmetatable(ElitistGroup.L, {
	__index = function(tbl, value)
		rawset(tbl, value, value)
		return value
	end,
})
--@end-debug@]===]