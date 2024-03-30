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

ERROR :: "\x1B[31m\x1b[0m"
WARNING :: "\x1B[38;2;255;210;0m\x1b[0m"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else when ODIN_OS == .Linux {
	foreign import lib "system:c"
}

foreign lib {
	@(link_name = "waitpid")
	_unix_waitpid :: proc(pid: pid_t, stat_loc: ^c.uint, options: c.uint) -> pid_t ---
}

waitpid :: proc "contextless" (pid: Pid, status: ^u32, options: Wait_Options) -> (Pid, os.Errno) {
	ret := _unix_waitpid(cast(i32)pid, status, transmute(u32)options)
	return Pid(ret), os.Errno(os.get_last_error())
}

launch :: proc(args: []string) -> StatusCode {
	wpid: Pid
	status: u32

	cmd_path, ok := find_program(args[0]);if !ok {
		fmt.eprintln(WARNING, "command not found:", args[0])
		return .Error
	}

	pid, err := fork();if err != os.ERROR_NONE {
		fmt.eprintln(ERROR, "fork:", ERROR_MSG[err])
		return .Error
	}

	if (pid == 0) {
		err = exec(cmd_path, args[1:]);if err != os.ERROR_NONE {
			fmt.eprintfln("%v ERROR: [%s] %s", WARNING, args[0], ERROR_MSG[err])
			return .Error
		}
		fmt.eprintln(WARNING, "execve: NO ERRORS")
		os.exit(0)
	}

	wpid, _ = waitpid(pid, &status, {.WUNTRACED})

	return wpid == pid && WIFEXITED(status) ? .Ok : .Error
}
