package http 

import "core:net"
import "core:strings"

Url :: struct 
{
    scheme: string,
    host: string, 
    path: string, 
    queries: map[string]string, 
    fragment: string,
    raw: string,
}

get_path_and_query :: proc(url: Url) -> string 
{
    occurrence := 0
    index := 0

    for occurrence < 3
    {
        c := url.raw[index]

        if c == '/'
        {
            occurrence += 1
        }

        index += 1
    }

    return url.raw[index-1:]
}

url_new :: proc(raw: string) -> Url 
{
    scheme, host, path, queries, fragment := net.split_url(raw)

    return Url{
        scheme,
        host,
        path,
        queries,
        fragment,
        raw
    }
}