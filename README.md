# zzlib

This is a pure Lua implementation of a depacker for the zlib DEFLATE(RFC1951)/GZIP(RFC1952) file format.
zzlib also allows the decoding of zlib-compressed data (RFC1950).

The implementation is pretty fast. It makes use of the built-in bit32 (PUC-Rio
Lua) or bit (LuaJIT) libraries for bitwise operations. Typical run times to
depack lua-5.3.3.tar.gz on my 2013 i5 laptop are 0.87s with Lua 5.3, and 0.28s
with LuaJIT 2.0.4.

zzlib is distributed under the WTFPL licence. See the COPYING file
or http://www.wtfpl.net/ for more details.

## Usage

There are two ways of using the library. You can either stream the input from a
file, or read it from a string.


### Stream from a gzip file

```
-- import the zzlib library
zzlib = require("zzlib")

-- get the unpacked contents of the file in the 'output' string
local output,err = zzlib.gunzipf("input.gz")
if not output then error(err) end
```

### Read from a string

Read a file into a string, call the depacker, and get a string with the unpacked file contents, as follows:

```
-- import the zzlib library
zzlib = require("zzlib")
...

if use_gzip then
  -- unpack the gzip input data to the 'output' string
  output = zzlib.gunzip(input)
else
  -- unpack the zlib input data to the 'output' string
  output = zzlib.inflate(input)
end
```
