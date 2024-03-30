package cmd

import "core:c"
import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "libs:failz"

StatusCode :: enum {
	Ok,
	Error,
	Usage,
}

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else when ODIN_OS == .Linux {
	foreign import lib "system:c"
}

foreign lib {
	@(link_name = "waitpid")
	_unix_waitpid :: proc(pid: pid_t, stat_loc: ^c.uint, options: c.uint) -> pid_t ---
}

waitpid :: proc "contextless" (pid: Pid, status: ^u32, options: Wait_Options) -> (Pid, failz.Errno) {
	ret := _unix_waitpid(cast(i32)pid, status, transmute(u32)options)
	return Pid(ret), failz.Errno(os.get_last_error())
}

launch :: proc(args: []string) -> bool {
	wpid: Pid
	status: u32

	cmd_path, ok := find_program(args[0]);if !ok {
		failz.warn(msg = fmt.tprint(args[0], "command not found:"))
		return false
	}

	pid, err := fork();if err != .ERROR_NONE {
		failz.warn(err, "fork:")
		return false
	}

	if (pid == 0) {
		err = exec(cmd_path, args[1:]);if err != .ERROR_NONE {
			failz.warn(err, "execve:")
			return false
		}
		os.exit(0)
	}

	wpid, err = waitpid(pid, &status, {.WUNTRACED})
	failz.warn(err, "waitpid:")

	return wpid == pid && WIFEXITED(status)
}
