
-- zzlib - zlib decompression in Lua - stub file for the different implementations

local lua_version = tonumber(_VERSION:match("^Lua (.*)"))
local zzlib

if not lua_version or lua_version < 5.3 then
  -- older version of Lua or Luajit being used - use bit/bit32-based implementation
  zzlib = require("zzlib-bit32")
else
  -- From Lua 5.3, use implementation based on bitwise operators
  zzlib = require("zzlib-bwo")
end

return zzlib
