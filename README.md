# Cmd
Tiny personal library to launch commands in posix

### Usage
```odin
import "libs:cmd"

main :: proc() {
  // You can just call the launcher
  r: CmdRunner
  ok := cmd.launch(&r, {"ls"})
  if !ok {
    fmt.println(r.err)
    return 1
  }

  // Or you can use the runner to have more fine grained control
  r: CmdRunner
  ok = cmd.init(&r, {"ls"})  // finds and the command and forks the process
  if !ok {
    fmt.println(r.err)
    return 1
  }

  ok = cmd.run(&r)           // runs execve with the entire environment copied to it
  if !ok {
    fmt.println(r.err)
    return 1
  }

  ok = cmd.wait(&r)          // waits for the process to finish
  if !ok {
    fmt.println(r.err)
    return 1
  }
}
```
