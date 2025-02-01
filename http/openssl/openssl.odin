// adapted from https://github.com/laytan/odin-http

package openssl

import "core:c"
import "core:c/libc"

SHARED :: #config(OPENSSL_SHARED, false)

when ODIN_OS == .Windows 
{
	when SHARED 
	{
		foreign import lib {
			"./includes/windows/libssl.lib",
			"./includes/windows/libcrypto.lib",
		}
	} 
	else 
	{
		@(extra_linker_flags="/nodefaultlib:libcmt")
		foreign import lib {
			"./includes/windows/libssl_static.lib",
			"./includes/windows/libcrypto_static.lib",
			"system:ws2_32.lib",
			"system:gdi32.lib",
			"system:advapi32.lib",
			"system:crypt32.lib",
			"system:user32.lib",
		}
	}
} else when ODIN_OS == .Darwin 
{
	foreign import lib {
		"system:ssl.3",
		"system:crypto.3",
	}
} 
else 
{
	foreign import lib {
		"system:ssl",
		"system:crypto",
	}
}

Version :: bit_field u32 
{
	pre_release: uint | 4,
	patch:       uint | 16,
	minor:       uint | 8,
	major:       uint | 4,
}

VERSION: Version

@(private, init)
version_check :: proc() 
{
    VERSION = Version(version_num())
    assert(VERSION.major == 3, "invalid OpenSSL library version, expected 3.x")
}

Method :: struct {}
Ctx :: struct {}
Ssl :: struct {}

SSL_CTRL_SET_TLSEXT_HOSTNAME :: 55

TLSEXT_NAMETYPE_host_name :: 0

foreign lib 
{
	@(link_name="TLS_client_method")
	tls_client_method :: proc() -> ^Method ---

	@(link_name="SSL_CTX_new")
	ctx_new :: proc(method: ^Method) -> ^Ctx ---

	@(link_name="SSL_new")
	new :: proc(ctx: ^Ctx) -> ^Ssl ---

	@(link_name="SSL_set_fd")
	set_fd :: proc(ssl: ^Ssl, fd: c.int) -> c.int ---

	@(link_name="SSL_connect")
	connect :: proc(ssl: ^Ssl) -> c.int ---

	@(link_name="SSL_get_error")
	get_error :: proc(ssl: ^Ssl, ret: c.int) -> c.int ---

	@(link_name="SSL_read")
	read :: proc(ssl: ^Ssl, buf: [^]byte, num: c.int) -> c.int ---

	@(link_name="SSL_write")
	write :: proc(ssl: ^Ssl, buf: [^]byte, num: c.int) -> c.int ---

	@(link_name="SSL_free")
	free :: proc(ssl: ^Ssl) ---

	@(link_name="SSL_CTX_free")
	ctx_free :: proc(ctx: ^Ctx) ---

	@(link_name="ERR_print_errors_fp")
	print_errors_fp :: proc(fp: ^libc.FILE) ---

	@(link_name="SSL_ctrl")
	ctrl :: proc(ssl: ^Ssl, cmd: c.int, larg: c.long, parg: rawptr) -> c.long ---

	@(link_name="OpenSSL_version_num")
    version_num :: proc() -> c.ulong ---
}

// This is a macro in c land.
SSL_set_tlsext_host_name :: proc(ssl: ^Ssl, name: cstring) -> c.int 
{
	return c.int(ctrl(ssl, SSL_CTRL_SET_TLSEXT_HOSTNAME, TLSEXT_NAMETYPE_host_name, rawptr(name)))
}

ERR_print_errors :: proc 
{
	print_errors_fp,
	ERR_print_errors_stderr,
}

ERR_print_errors_stderr :: proc() 
{
	print_errors_fp(libc.stderr)
}
