
-- zzlib - zlib decompression in Lua - stub file for the different implementations

-- Copyright (c) 2016-2020 Francois Galea <fgalea at free.fr>
-- This program is free software. It comes without any warranty, to
-- the extent permitted by applicable law. You can redistribute it
-- and/or modify it under the terms of the Do What The Fuck You Want
-- To Public License, Version 2, as published by Sam Hocevar. See
-- the COPYING file or http://www.wtfpl.net/ for more details.


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
