package http 

import "core:net"

Url :: struct 
{
    scheme: string,
    host: string, 
    path: string, 
    queries: map[string]string, 
    fragment: string
}

url_new :: proc(raw: string) -> Url 
{
    scheme, host, path, queries, fragment := net.split_url(raw)

    return Url{
        scheme,
        host,
        path,
        queries,
        fragment
    }
}