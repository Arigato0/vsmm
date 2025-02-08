package main 

import "core:fmt"
import "core:os"
import "core:strings"

import "cmd"

config_cmd :: proc(ctx: ^cmd.Ctx) -> bool 
{
    if len(ctx.args) == 0 
    {
        ctx.failure_reason = "all config commands expect at least one argument"
        return false 
    }

    if ctx.subcmd == "vs_location"
    {
        home_dir := get_home_dir()

        // assuming we're on a unix system replace ~ with the home dir
        location, was_allocation := strings.replace(ctx.args[0], "~", home_dir, 1)

        defer if was_allocation 
        {
            delete(location)
        }
        
        if !os.exists(location)
        {
            ctx.failure_reason = "the provided filepath does not exist"
            return false
        }

        set_config("vs_location", location)

        fmt.printfln("set vintage story location to {}", location)
    }

    return true
}