#+ private package

package http

import "core:strings"
import "core:net"

Request :: struct 
{
    url: Url,
    headers: Headers,
    method: Method,
}

build_request_frame :: proc(request: ^Request) -> strings.Builder 
{
    frame: strings.Builder

    strings.builder_init(&frame)

    path_and_query := get_path_and_query(request.url)

    #partial switch request.method
    {
        case .Get:
            strings.write_string(&frame, "GET ")
            strings.write_string(&frame, path_and_query)
            strings.write_rune(&frame, ' ')
            strings.write_string(&frame, HTTP_VERSION)
            strings.write_string(&frame, "\r\n")
    }

    for key, value in request.headers 
    {
        strings.write_string(&frame, key)
        strings.write_string(&frame, ": ")
        strings.write_string(&frame, value)
        strings.write_string(&frame, "\r\n")
    }

    strings.write_string(&frame, "\r\n")

    return frame
}