package reader 

// A reader for parsing response frames
Reader :: struct 
{
    src: []byte,
    off: int,
    cur: int, 
}

read_until :: proc(reader: ^Reader, c: byte) -> string
{
    for !at_end(reader) && peak(reader) != c
    {
        reader.off += 1
    }

    out := reader.src[reader.cur : reader.off]

    reader.cur = reader.off

    return string(out)
}

at_end :: proc(reader: ^Reader) -> bool 
{
    return reader.off >= len(reader.src) 
}

peak :: proc(reader: ^Reader) -> byte
{
    if at_end(reader)
    {
        return 0
    }

    return reader.src[reader.off]
}

peak_next :: proc(reader: ^Reader) -> byte
{
    if reader.off + 1 >= len(reader.src)
    {
        return 0
    }

    return reader.src[reader.off + 1]
}

slice :: proc(reader: ^Reader) -> string 
{
    s := reader.src[reader.cur : reader.off]
    return string(s)
}

skip_blank :: proc(reader: ^Reader) 
{
    for !at_end(reader) && (peak(reader) == ' ' || peak(reader) == '\t')
    {
        reader.off += 1
    }

    reader.cur = reader.off
}

advance_and_sync :: proc(reader: ^Reader, step := 1)
{
    reader.off += step
    reader.cur = reader.off
}
