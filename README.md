# zzlib

This is a pure Lua implementation of a depacker for the zlib DEFLATE(RFC1951)/GZIP(RFC1952) file format.

The implementation is pretty fast. It makes use of the built-in bit32 (PUC-Rio
Lua) or bit (LuaJIT) libraries for bitwise operations. Typical run times to
depack lua-5.3.3.tar.gz on my 2013 i5 laptop are 1.02s with Lua 5.3, and 0.42s
with LuaJIT 2.0.4.

zzlib is distributed under the WTFPL licence. See the COPYING file
or http://www.wtfpl.net/ for more details.

## Usage

Its use is straightforward. Read a file into a string, call the depacker, and get a string with the unpacked file contents. The following code snippet illustrates the general behaviour:

```
-- import the zzlib library
zzlib = require("zzlib")

-- read the file into a string
local file,err = io.open("input.gz","rb")
if not file then error(err) end
local in = file:read("*a")
file:close()

-- get the unpacked contents of the file in the 'out' string
local out = zzlib.gunzip(in)
```
