# VSMM

VSMM is a vintage story mod manager i wrote for myself to automatically update my mods and create mod lists. It is only a command line tool because im a nerd and i hate writing guis feel free to write a frontend for it if so inclined.

## Usage

## Technical details

You might notice i wrote an http client from scratch and thats mostly because i first assumed odin had an http client built in but realized it did not so i decided to write my own and shortly realized odin-http exists. But already being in the mindset that i will write my own i decided to not use it and indeed wrote an ok http client. Mine does have some advantages over odin-http since mine supports keep-alive which is very useful for this use case. Performance should be fairly decent as well. Special thanks for odin-http for writing openssl bindings that is the only piece of code this project shares with odin-http.