package http

import "core:fmt"
import "core:net"
import "core:bytes"
import "core:strings"
import "core:c"
import "openssl"

HTTP_VERSION :: "HTTP/1.1"
USER_AGENT :: "vsmm"

@(private)
HTTP_PORT :: 80
HTTPS_PORT :: 443

// even though i only use Get im still using this for prosperity
Method :: enum 
{
    Get,
    Post,
    Delete
}

Headers :: map[string]string

RequestOptions :: struct 
{
    headers: Headers,
}

@(private="package")
Connection :: struct 
{
    socket: net.TCP_Socket,
    // only for secure connections will be nil otherwise
    ssl: ^openssl.Ssl,
    ctx: ^openssl.Ctx,
}

// used to hold keep-alive connections and will be managed through get_connection and close_connection
@(private="package")
g_connections := make(map[string]Connection)

get :: proc(url: string, options: RequestOptions = {}) -> (response: Response , ok: bool)
{
    options := options

    if options.headers == nil 
    {
        options.headers = make(Headers)
    }

    url := url_new(url)

    set_default_headers(url, &options.headers)

    frame_details := Request{
        url,
        options.headers,
        .Get
    }

    frame := build_request_frame(&frame_details)

    defer strings.builder_destroy(&frame)

    // TODO: make sure connections are only kept alive if keep-alive is set
    connection := get_connection(url) or_return

    if connection.ssl != nil do return make_secure_request(connection, url, frame.buf[:])
    
    return make_request(connection, url, frame.buf[:])
} 

@(private="package")
get_connection :: proc(url: Url) -> (Connection, bool)
{
    connection, exists := g_connections[url.host]

    if exists 
    {
        return connection, true
    }

    is_https := url.scheme == "https"

    socket, err := net.dial_tcp(url.host, HTTPS_PORT if is_https else HTTP_PORT)

    if err != nil
    {
        return {}, false
    }

    connection = Connection {
        socket = socket
    }

    if is_https 
    {
        ctx := openssl.ctx_new(openssl.tls_client_method())

        ssl := openssl.new(ctx)

        openssl.set_fd(ssl, c.int(socket))

        ssl_hostname := strings.clone_to_cstring(url.host)

        defer delete(ssl_hostname)
        
        openssl.SSL_set_tlsext_host_name(ssl, ssl_hostname)

        if openssl.connect(ssl) != 1
        {
            return {}, false
        }

        connection.ssl = ssl
        connection.ctx = ctx
    }

    g_connections[url.host] = connection

    return connection, true
}

@(private="package")
close_connection :: proc(url: Url)
{
    connection, exists := g_connections[url.host]

    if exists 
    {
        return
    }

    openssl.ctx_free(connection.ctx)
    openssl.free(connection.ssl)

    net.close(connection.socket)

    delete_key(&g_connections, url.host)
}

// sets a header only if it does not exist
// returns true if key was added to headers
set_header :: proc(headers: ^Headers, key, value: string) -> bool
{
    exists := key in headers 

    if !exists 
    {
        headers[key] = value 
    }

    return !exists
}

@(private="file")
set_default_headers :: proc(url: Url, headers: ^Headers)
{
    set_header(headers, "host", url.host)
    set_header(headers, "user-agent", USER_AGENT)
    set_header(headers, "accept", "application/json")
    set_header(headers, "connection", "close")
}

@(private="file")
make_secure_request :: proc(using connection: Connection, url: Url, frame: []byte) -> (Response, bool) 
{
    bytes_left := c.int(len(frame))

    for bytes_left > 0
    {
        written := openssl.write(ssl, raw_data(frame), bytes_left)

        if written <= 0 
        {
            return {}, false 
        }

        bytes_left -= written
    }

    buffer: [4096]u8
    result: strings.Builder

    strings.builder_init(&result)

    read: i32 = 1

    res_buffer: strings.Builder 

    strings.builder_init(&res_buffer)

    defer strings.builder_destroy(&res_buffer)

    for read > 0
    {
        read = openssl.read(ssl, raw_data(buffer[:]), len(buffer))

        if read > 0 
        {
            strings.write_bytes(&res_buffer, buffer[:read])
        }
    }

    // fmt.println(string(frame[:]))
    // fmt.println(string(res_buffer.buf[:]))

    return parse_response_frame(res_buffer.buf[:])
}

@(private="file")
make_request :: proc(using connection: Connection, url: Url, frame: []byte) -> (Response, bool) 
{
    sent, err := net.send_tcp(socket, frame)

    if err != nil
    {
        return {}, false
    }

    read := 0

    buffer: [4096]u8

    read, err = net.recv_tcp(socket, buffer[:])

    fmt.println(string(buffer[:]))

    return parse_response_frame(buffer[:])
}