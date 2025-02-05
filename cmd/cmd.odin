package cmd

import "core:slice"

ExecProc :: proc(^Ctx) -> bool
ErrorProc :: proc(^Ctx)

RunError :: enum 
{
    None,
    NoCommand,
    CommandNotFound,
    ExpectedSubCommand,
    CommandFailed,
}

@(private="file")
g_error_strings := [RunError]string{
    .None = "No error happened",
    .NoCommand = "expected a command",
    .CommandNotFound = "The given command does not exist",
    .ExpectedSubCommand = "Expected a sub command but none or an invalid sub command was given",
    .CommandFailed = "The executing command failed",
}

get_error_message :: proc(err: RunError) -> string
{
    return g_error_strings[err]
}

Handler :: struct
{
    app_name: string,
    app_description: string,
    help_cmd: ExecProc,
    error_handler: ErrorProc,
    cmds: map[string]Cmd,
    error_message: string
}

Ctx :: struct
{
    args: []string,
    handler: ^Handler,
    subcmd: string,
    // should be set by the command exec in case of a failure for more detailed error handling
    failure_reason: string,
}

Cmd :: struct
{
    name: string,
    description: string,
    subcmds: []string,
    exec: ExecProc
}

default_help_cmd :: proc(using ctx: ^Ctx) -> bool
{

    return true
}

default_error_handler :: proc(using ctx: ^Ctx)
{

}

init :: proc(using handler: ^Handler)
{
    cmds = make(map[string]Cmd)

    if help_cmd == nil
    {
        help_cmd = default_help_cmd
    }
    if error_handler == nil
    {
        error_handler = default_error_handler
    }
}

deinit :: proc(using handler: ^Handler)
{
    delete(cmds)
}

add_cmd :: proc(using handler: ^Handler, cmd: Cmd)
{
    assert(cmd.name != "", "command name must not be empty")

    cmds[cmd.name] = cmd
}

remove_cmd :: proc(using handler: ^Handler, name: string)
{
    assert(name != "", "command name must not be empty")

    cmd, exists := cmds[name]

    if !exists
    {
        return
    }

    delete_key(&cmds, name)
}

@(private)
eval_subcmds :: proc(cmd: Cmd, args: []string) -> bool 
{
    if len(args) == 0
    {
        return false
    }

    subcmd := args[0]

    // performance doesnt matter here so this is fine
    _, found := slice.linear_search(cmd.subcmds, subcmd)

    return found
}

run_cmd :: proc(handler: ^Handler, args: []string) -> RunError
{
    args := args
    if len(args) == 0
    {
        return .NoCommand
    }

    cmd, exists := handler.cmds[args[0]]

    if !exists 
    {
        return .CommandNotFound
    }

    args = args[1:]

    ctx := Ctx{
        handler = handler,
    }

    if cmd.subcmds != nil 
    {
        ok := eval_subcmds(cmd, args)

        if !ok 
        {
            return .ExpectedSubCommand
        }

        ctx.subcmd = args[0]

        args = args[1:]
    }

    ctx.args = args 

    ok := cmd.exec(&ctx)

    return .None if ok else .CommandFailed
}
