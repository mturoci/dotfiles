-- Drives the Twingate menu bar item. Loaded at runtime by "Twingate Toggle.app"
-- so edits here do not invalidate that app's Accessibility grant (TCC pins the
-- ad-hoc code signature, and rebuilding the bundle silently revokes it).
--
-- Twingate's menu ignores AX actions and synthetic "click at", so AX is used
-- only to locate elements; the click itself is posted by the ./click helper.
--
-- Every AX read is an Apple Event and every "do shell script" forks a shell,
-- so both are kept to a minimum: log lines are buffered into one write, and
-- only "dump" walks the full menu tree.

global logBuf

on logLine(msg)
	set end of logBuf to (msg as text)
end logLine

on flushLog()
	if logBuf is {} then return
	set AppleScript's text item delimiters to linefeed
	set blob to logBuf as text
	set AppleScript's text item delimiters to ""
	set c to (POSIX path of (path to home folder)) & ".cache"
	do shell script "mkdir -p " & quoted form of c & "; printf '%s\\n' " & quoted form of blob & " >> " & quoted form of (c & "/twingate-net.log")
	set logBuf to {}
end flushLog

on clicker()
	return quoted form of ((POSIX path of (path to home folder)) & ".local/share/twingate-net/click")
end clicker

on centerOf(el)
	tell application "System Events"
		set p to position of el
		set sz to size of el
	end tell
	return {(item 1 of p) + ((item 1 of sz) / 2), (item 2 of p) + ((item 2 of sz) / 2)}
end centerOf

on openStatusMenu()
	if not (application "Twingate" is running) then
		do shell script "open -g -a Twingate"
		delay 3
	end if
	tell application "System Events"
		tell process "Twingate"
			set mbi to menu bar item 1 of menu bar 2
			try
				perform action "AXPress" of mbi
			on error
				click mbi
			end try
			repeat 25 times
				if (exists menu 1 of mbi) then return
				delay 0.1
			end repeat
		end tell
	end tell
end openStatusMenu

on closeMenu()
	tell application "System Events"
		tell process "Twingate"
			if (exists menu 1 of menu bar item 1 of menu bar 2) then key code 53
		end tell
	end tell
end closeMenu

-- The first resource row, found by the only marker that identifies one: a
-- submenu offering a renewal. Returns {menu item index, name, expiry text}.
on findResource()
	tell application "System Events"
		tell process "Twingate"
			set mbi to menu bar item 1 of menu bar 2
			repeat with i from 1 to (count of menu items of menu 1 of mbi)
				set mit to menu item i of menu 1 of mbi
				try
					if (exists menu 1 of mit) then
						set subNames to name of every menu item of menu 1 of mit
						if subNames contains "Renew Session" then
							set rname to ""
							try
								set rname to (name of mit) as text
							end try
							set expiry to ""
							repeat with n in subNames
								if (contents of n) is not missing value then
									if ((contents of n) as text) starts with "Auth expires" then set expiry to (contents of n) as text
								end if
							end repeat
							return {i, rname, expiry}
						end if
					end if
				end try
			end repeat
		end tell
	end tell
	return {0, "", ""}
end findResource

on run
	set logBuf to {}
	my logLine("--- " & ((current date) as text))
	set modeFile to (POSIX path of (path to home folder)) & ".cache/twingate-net.mode"
	set mode to ""
	try
		set mode to do shell script "cat " & quoted form of modeFile & " 2>/dev/null"
	end try
	try
		if mode is "expiry" then
			my readExpiry()
		else if mode is "dump" then
			my dumpMenu()
		else if mode is "renew" then
			my renewSession()
		else
			my flipSwitch()
		end if
	on error errMsg number errNum
		my logLine("ERROR " & errNum & ": " & errMsg)
		try
			my closeMenu()
		end try
	end try
	my logLine("DONE")
	my flushLog()
end run

on readExpiry()
	my openStatusMenu()
	set res to my findResource()
	my closeMenu()
	if (item 1 of res) is 0 then
		my logLine("ERROR: no resource found (connected?)")
	else
		my logLine("resource: " & (item 2 of res) & " | " & (item 3 of res))
	end if
end readExpiry

-- Flips the "Connect to network" switch in the account row.
on flipSwitch()
	set origin to do shell script my clicker() & " pos"
	my openStatusMenu()

	tell application "System Events"
		tell process "Twingate"
			-- The account row is a custom view; the switch is its AXUnknown child.
			set sw to missing value
			repeat with k in (UI elements of UI element 1 of menu item 1 of menu 1 of menu bar item 1 of menu bar 2)
				if ((role of k) as text) is "AXUnknown" then set sw to contents of k
			end repeat
		end tell
	end tell
	if sw is missing value then
		my logLine("ERROR: switch not found in account row")
		my closeMenu()
		return
	end if

	set ctr to my centerOf(sw)
	my logLine("clicking switch at " & (item 1 of ctr) & ", " & (item 2 of ctr))
	do shell script my clicker() & " click " & (item 1 of ctr) & " " & (item 2 of ctr) & " " & origin
	delay 0.6
	my closeMenu()
end flipSwitch

-- Renews the first resource whose submenu offers a renewal.
on renewSession()
	set origin to do shell script my clicker() & " pos"
	my openStatusMenu()
	set res to my findResource()

	if (item 1 of res) is 0 then
		my logLine("ERROR: no resource offers Renew Session (connected?)")
		my closeMenu()
		return
	end if
	my logLine("resource: " & (item 2 of res) & " | " & (item 3 of res))

	tell application "System Events"
		tell process "Twingate"
			set resRow to menu item (item 1 of res) of menu 1 of menu bar item 1 of menu bar 2
		end tell
	end tell

	-- Hover the row so the submenu is really displayed, then click the item.
	set resRowCtr to my centerOf(resRow)
	do shell script my clicker() & " move " & (item 1 of resRowCtr) & " " & (item 2 of resRowCtr)
	delay 0.5

	tell application "System Events"
		tell process "Twingate"
			set renewItem to menu item "Renew Session" of menu 1 of resRow
		end tell
	end tell
	set ctr to my centerOf(renewItem)
	my logLine("clicking Renew Session at " & (item 1 of ctr) & ", " & (item 2 of ctr))
	do shell script my clicker() & " click " & (item 1 of ctr) & " " & (item 2 of ctr) & " " & origin
	delay 0.8
	my closeMenu()
	my logLine("RENEWED: " & (item 2 of res))
end renewSession

-- Diagnostics: dump the whole status menu tree to the log.
on dumpEl(el, depth, prefix)
	if depth > 5 then return
	set info to prefix
	tell application "System Events"
		try
			set info to info & ((role of el) as text)
		end try
		try
			set info to info & " title=[" & ((title of el) as text) & "]"
		end try
		try
			set info to info & " value=[" & ((value of el) as text) & "]"
		end try
		set kids to {}
		try
			set kids to UI elements of el
		end try
	end tell
	my logLine(info)
	repeat with i from 1 to (count of kids)
		my dumpEl(item i of kids, depth + 1, prefix & "  ")
	end repeat
end dumpEl

on dumpMenu()
	my openStatusMenu()
	tell application "System Events"
		tell process "Twingate"
			set mi to menu items of menu 1 of menu bar item 1 of menu bar 2
		end tell
	end tell
	my logLine("menu items: " & (count of mi))
	repeat with i from 1 to (count of mi)
		my logLine("== item " & i)
		my dumpEl(item i of mi, 1, "  ")
	end repeat
	my closeMenu()
end dumpMenu
