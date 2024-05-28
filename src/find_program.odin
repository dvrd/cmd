package cmd

import "core:fmt"
import "core:os"
import "core:strings"

find_program :: proc(target: string) -> (string, bool) {
	env_path := os.get_env("PATH")
	dirs := strings.split(env_path, ":")

	if len(dirs) == 0 do return "", false

	for dir in dirs {
		if !os.is_dir(dir) do continue

		fd, err := os.open(dir)
		defer os.close(fd)
		if Errno(err) != .ERROR_NONE do continue

		fis: []os.File_Info
		defer os.file_info_slice_delete(fis)
		fis, err = os.read_dir(fd, -1)
		if Errno(err) != .ERROR_NONE do continue

		for fi in fis {
			if fi.name == target do return fi.fullpath, true
		}
	}

	return "", false
}
