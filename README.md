# zzlib

This is a pure Lua implementation of a depacker for the zlib DEFLATE(RFC1951)/GZIP(RFC1952) file format.

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
