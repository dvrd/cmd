package cmd

import "core:os"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else when ODIN_OS == .Linux {
	foreign import lib "system:c"
}

foreign lib {
	@(link_name = "fork")
	_unix_fork :: proc() -> pid_t ---
}

fork :: proc() -> (Pid, Errno) {
	pid := _unix_fork()
	if pid == -1 {
		return Pid(-1), Errno(os.get_last_error())
	}
	return Pid(pid), .ERROR_NONE
}
