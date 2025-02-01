package main

import "core:fmt"
import "core:encoding/json"
import "http"
// import "odinhttp/client"

Test :: struct 
{
    mod: struct 
    {
        modid: int
    }
}

main :: proc()
{
    // res, err := client.get("https://mods.vintagestory.at/api/mod/xskills")

    // body, allocation, berr := client.response_body(&res)
	// if berr != nil {
	// 	fmt.printf("Error retrieving response body: %s", berr)
	// 	return
	// }
	// defer client.body_destroy(body, allocation)

	// fmt.println(body)
    response, ok := http.get("https://mods.vintagestory.at/api/mod/xskills")

    if !ok || response.status != 200
    {
        fmt.println("could not make http request", response.message)
        return
    }

    test: Test 
    unmarshal_err := json.unmarshal(response.body, &test)
	if unmarshal_err != nil {
		fmt.eprintln("Failed to parse the json file.")
		fmt.eprintln("Error:", unmarshal_err)
		return
	}
	// defer json.destroy_value(json_data)

	// Access the Root Level Object
	// root := json_data.(json.Object)

    // fmt.println(root["mod"].(json.Object)["modid"])

    fmt.println(test.mod.modid)
}