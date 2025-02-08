#+feature dynamic-literals

package main 

import "core:fmt"

import "cmd"

register_cmds :: proc(handler: ^cmd.Handler)
{
    cmd.add_cmd(handler, cmd.Cmd{
        name = "config",
        description = "a general purpose command for configuring the behavior of vsmm",
        subcmds = [dynamic]string{"vs_location"},
        exec = config_cmd
    })
}