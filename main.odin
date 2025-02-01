package main

import "core:fmt"
import "core:encoding/json"
import "http"

// the json response from mods.vintagestory.at
ModInfoResponse :: struct 
{
    mod: struct 
    {
        modid: int,
        releases: []struct 
        {
            modversion: string,
            fileid: int,
        }
    }
}

ModInfo :: struct 
{
    name: string,
    modid: string,
    version: string,
}

main :: proc()
{
    // response, ok := http.get("https://mods.vintagestory.at/api/mod/xskills")

    // defer http.destroy_response(&response)

    // if !ok || response.status != 200
    // {
    //     fmt.println("could not make http request", response.message)
    //     return
    // }

    // test: ModInfoResponse 
    // unmarshal_err := json.unmarshal(response.body, &test)
	// if unmarshal_err != nil {
	// 	fmt.eprintln("Failed to parse the json file.")
	// 	fmt.eprintln("Error:", unmarshal_err)
	// 	return
	// }
	// // defer json.destroy_value(json_data)

	// // Access the Root Level Object
	// // root := json_data.(json.Object)

    // // fmt.println(root["mod"].(json.Object)["modid"])

    // fmt.println(test.mod.releases[0])

    response, ok := http.get("https://mods.vintagestory.at/download?fileid=31694")

    defer http.destroy_response(&response)

    if !ok || response.status != 200
    {
        fmt.println("could not make http request", response.message)
        return
    }

    fmt.println(string(response.body))
}