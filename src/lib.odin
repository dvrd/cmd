package cmd

import "core:c"
import "core:c/libc"
import "core:fmt"
import "core:os"

Pid :: distinct i32
pid_t :: i32

/// Termination signal
/// Only retrieve the code if WIFSIGNALED(s) = true
WTERMSIG :: #force_inline proc "contextless" (s: u32) -> u32 {
	return s & 0x7f
}

/// Check if the process signaled
WIFSIGNALED :: #force_inline proc "contextless" (s: u32) -> bool {
	return cast(i8)(((s) & 0x7f) + 1) >> 1 > 0
}

/// Check if the process terminated normally (via exit.2)
WIFEXITED :: #force_inline proc "contextless" (s: u32) -> bool {
	return WTERMSIG(s) == 0
}

WaitOption :: enum {
	WNOHANG     = 0,
	WUNTRACED   = 1,
	WSTOPPED    = WUNTRACED,
	WEXITED     = 2,
	WCONTINUED  = 3,
	WNOWAIT     = 24,
	// For processes created using clone
	__WNOTHREAD = 29,
	__WALL      = 30,
	__WCLONE    = 31,
}

WaitOptions :: bit_set[WaitOption;u32]

CmdRunner :: struct {
	args: []string,
	path: string,
	pid:  Pid,
	err:  Errno,
}

launch :: proc(cmd: ^CmdRunner, args: []string) -> bool {
	return init(cmd, args) && run(cmd) && wait(cmd)
}

init :: proc(cmd: ^CmdRunner, args: []string) -> (ok: bool) {
	cmd.args = args
	cmd.path, ok = find_program(args[0])
	if !ok {
		cmd.err = .ENOENT
		return false
	}

	cmd.pid, cmd.err = fork()
	return cmd.err == .ERROR_NONE
}

run :: proc(cmd: ^CmdRunner) -> bool {
	if (cmd.pid == 0) {
		err := exec(cmd.path, cmd.args[1:])
		return err == .ERROR_NONE
	}
	return true
}

wait :: proc(cmd: ^CmdRunner) -> bool {
	status: u32
	wpid, err := waitpid(cmd.pid, &status, {.WUNTRACED})
	cmd.err = err
	return wpid == cmd.pid && WIFEXITED(status)
}
