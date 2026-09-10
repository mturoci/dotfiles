-- Stable shim: never edit or rebuild this app, or its Accessibility grant is revoked.
on run
	set p to (POSIX path of (path to home folder)) & ".local/share/twingate-net/logic.scpt"
	run script (POSIX file p as alias)
end run
