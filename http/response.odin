package http 

import "reader"
import "core:strconv"
import "core:fmt"
import "core:strings"

Response :: struct 
{
    status: int,
    message: string,
    headers: Headers,
    body: []byte,
    _buffer: []byte
}

destroy_response :: proc(response: ^Response)
{
    delete(response._buffer)

    // only need to delete the body if it is chunked otherwise it will just be a slice of _buffer
    if is_chunked(response.headers)
    {
        delete(response.body)
    }

    delete(response.headers)
}

@(private="package")
is_chunked :: proc(headers: Headers) -> bool
{
    encoding, has_encoding := headers["Transfer-Encoding"]

    return has_encoding && encoding == "chunked" 
}

@(private="package")
parse_response_frame :: proc(buffer: []byte) -> (response: Response, ok: bool)
{
    rdr := reader.Reader {
        src = buffer
    }

    // read past http version 
    reader.read_until(&rdr, ' ')
    reader.advance_and_sync(&rdr)

    // read and parse status code
    status_str := reader.read_until(&rdr, ' ')

    response.status = strconv.parse_int(status_str) or_return

    reader.advance_and_sync(&rdr)

    response.message = reader.read_until(&rdr, '\r')
    reader.advance_and_sync(&rdr)

    response.headers = make(Headers)

    for !reader.at_end(&rdr) && reader.peak(&rdr) != '\r'
    {
        key := reader.read_until(&rdr, ':')

        reader.advance_and_sync(&rdr)

        reader.skip_blank(&rdr)

        value := reader.read_until(&rdr, '\r')

        reader.advance_and_sync(&rdr, 2)

        response.headers[key] = value
    }

    reader.advance_and_sync(&rdr, 2)

    if is_chunked(response.headers) 
    {
        response.body = get_chunked_body(buffer[rdr.cur:])
    }
    else 
    {
        content_length_str, has_content_len := response.headers["Content-Length"]

        if has_content_len
        {
            length := strconv.parse_int(content_length_str) or_return

            end := rdr.cur + length 

            response.body = buffer[rdr.cur : end]
        }
    }

    return response, true
}

get_chunked_body :: proc(buffer: []byte) -> []byte 
{
    rdr := reader.Reader{
        src = buffer
    }

    body: strings.Builder

    strings.builder_init(&body)

    for !reader.at_end(&rdr)
    {
        len_str := reader.read_until(&rdr, '\r')

        reader.advance_and_sync(&rdr, 2)

        chunk_length, _ := strconv.parse_int(len_str, 16)

        if chunk_length < 0 
        {
            break
        }

        end := rdr.cur + chunk_length

        strings.write_bytes(&body, buffer[rdr.cur : end])
    }

    return body.buf[:]
}

