package main 

import "core:os"
import "core:encoding/json"
import "core:strings"
import "core:path/filepath"

VSMM_DATA_DIR :: "vsmm_data"
CONFIG_JSON :: "config.json"

Config :: struct 
{
    vs_location: string,
}

get_home_dir :: proc() -> string
{
    when ODIN_OS == .Linux
    {
        home_dir, _ := os.lookup_env("HOME")
        return home_dir
    }
    else 
    {
        #panic("No home dir specified for target os")
    }
}

get_data_dir :: proc() -> string 
{
    home_dir := get_home_dir()

    when ODIN_OS == .Linux 
    {
        result, _ := strings.concatenate([]string{home_dir, "/.config"})
        return result
    } 
    else 
    {
        #panic("No data directory specified for target os")
    }

    unreachable();
}

get_default_vs_location :: proc() -> string 
{
    home_dir := get_home_dir()

    when ODIN_OS == .Linux
    {
        result, _ := strings.concatenate([]string{home_dir, "/.local/share/vintagestory"})

        return result
    }
    else 
    {
        #panic("No default vs location specified for this os")
    }

    unreachable();
}

get_config_json_path :: proc() -> string
{
    data_dir := get_data_dir()

    return filepath.join([]string{data_dir, VSMM_DATA_DIR, CONFIG_JSON})
}

validate_config :: proc()
{
    data_dir := get_data_dir()

    vsmm_data_dir := filepath.join([]string{data_dir, VSMM_DATA_DIR})
    config_path := get_config_json_path()

    defer 
    {
        delete(data_dir)
        delete(vsmm_data_dir)
        delete(config_path)
    }

    if os.exists(config_path)
    {
        return
    }
    
    os.make_directory(vsmm_data_dir)

    file, _ := os.open(config_path, os.O_RDWR | os.O_CREATE, 0o777)

    defer os.close(file)

    config := Config {
        vs_location = get_default_vs_location()
    }

    contents, _ := json.marshal(config)

    os.write(file, contents)
}

get_config :: proc() -> (config: Config)
{
    config_path := get_config_json_path()

    // can assume this works because of validate_config or maybe not
    contents, _ := os.read_entire_file(config_path)

    json.unmarshal(contents, &config)

    return config
}

set_config :: proc(key: string, value: json.Value)
{
    config_path := get_config_json_path()

    // can assume this works because of validate_config or maybe not
    contents, _ := os.read_entire_file(config_path)

    parsed, _ := json.parse(contents)

    root := parsed.(json.Object)

    root[key] = value

    contents, _ = json.marshal(root)

    os.write_entire_file(config_path, contents)
}