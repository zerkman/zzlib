
-- zzlib - zlib decompression in Lua

-- Copyright (c) 2016 Francois Galea <fgalea at free.fr>
-- This program is free software. It comes without any warranty, to
-- the extent permitted by applicable law. You can redistribute it
-- and/or modify it under the terms of the Do What The Fuck You Want
-- To Public License, Version 2, as published by Sam Hocevar. See
-- the COPYING file or http://www.wtfpl.net/ for more details.


local zzlib = {}

local reverse = {}

local bit = bit32 or bit

local function bitstream_init(buf,pos)
  local function flushb(bs,n)
    bs.n = bs.n - n
    bs.b = bit.rshift(bs.b,n)
  end
  local function getb(bs,n)
    while bs.n < n do
      bs.b = bs.b + bit.lshift(bs.buf:byte(bs.pos),bs.n)
      bs.pos = bs.pos + 1
      bs.n = bs.n + 8
    end
    local ret = bit.band(bs.b,bit.lshift(1,n)-1)
    flushb(bs,n)
    return ret
  end
  local function getv(bs,hufftable,n)
    while bs.n < n do
      bs.b = bs.b + bit.lshift(bs.buf:byte(bs.pos),bs.n)
      bs.pos = bs.pos + 1
      bs.n = bs.n + 8
    end
    local h = reverse[bit.band(bs.b,255)]
    local l = reverse[bit.band(bit.rshift(bs.b,8),255)]
    local v = bit.band(bit.rshift(bit.lshift(h,8)+l,16-n),2^n-1)
    local e = hufftable[v]
    local len = bit.band(e,15)
    local ret = bit.rshift(e,4)
    flushb(bs,len)
    return ret
  end
  local bs = {
    buf = buf,  -- buffer
    pos = pos,  -- position in string
    b = 0,      -- bits buffer
    n = 0,      -- number of bits in buffer
    flushb = flushb,
    getb = getb,
    getv = getv
  }
  return bs
end

local function read32(str,pos)
  local x = bit.lshift(str:byte(pos+3),24)
          + bit.lshift(str:byte(pos+2),16)
          + bit.lshift(str:byte(pos+1),8)
          + str:byte(pos)
  return x
end

local function hufftable_create(depths)
  local nvalues = #depths
  local nbits = 1
  local bl_count = {}
  local next_code = {}
  for i=1,nvalues do
    local d = depths[i]
    if d > nbits then
      nbits = d
    end
    bl_count[d] = (bl_count[d] or 0) + 1
  end
  local table = {}
  local code = 0
  bl_count[0] = 0
  for i=1,nbits do
    code = (code + (bl_count[i-1] or 0)) * 2
    next_code[i] = code
  end
  for i=1,nvalues do
    local len = depths[i] or 0
    if len > 0 then
      local e = (i-1)*16 + len
      local code = next_code[len]
      next_code[len] = next_code[len] + 1
      local code0 = code * 2^(nbits-len)
      local code1 = (code+1) * 2^(nbits-len)
      -- print("code="..code.." code0="..code0.." code1="..code1.." e="..e)
      if code1 > 2^nbits then
        error("code error")
      end
      for j=code0,code1-1 do
        table[j] = e
      end
    end
  end
  return table,nbits
end

local function inflate_loop(out,bs,nlit,ndist,littable,disttable)
  local lit
  repeat
    lit = bs:getv(littable,nlit)
    if lit < 256 then
      table.insert(out,lit)
    elseif lit > 256 then
      local nbits = 0
      local size = 3
      local dist = 1
      if lit < 265 then
        size = size + lit - 257
      elseif lit < 285 then
        nbits = bit.rshift(lit-261,2)
        size = size + bit.lshift(bit.band(lit-261,3)+4,nbits)
      else
        size = 258
      end
      if nbits > 0 then
        size = size + bs:getb(nbits)
      end
      local v = bs:getv(disttable,ndist)
      if v < 4 then
        dist = dist + v
      else
        nbits = bit.rshift(v-2,1)
        dist = dist + bit.lshift(bit.band(v,1)+2,nbits)
        dist = dist + bs:getb(nbits)
      end
      local p = #out-dist+1
      while size > 0 do
        table.insert(out,out[p])
        p = p + 1
        size = size - 1
      end
    end
  until lit == 256
  return o
end

local function inflate_dynamic(out,bs)
  local order = { 17, 18, 19, 1, 9, 8, 10, 7, 11, 6, 12, 5, 13, 4, 14, 3, 15, 2, 16 }
  local hlit = 257 + bs:getb(5)
  local hdist = 1 + bs:getb(5)
  local hclen = 4 + bs:getb(4)
  local depths = {}
  for i=1,hclen do
    local v = bs:getb(3)
    depths[order[i]] = v
  end
  for i=hclen+1,19 do
    depths[order[i]] = 0
  end
  local lengthtable,nlen = hufftable_create(depths)
  local i=1
  while i<=hlit+hdist do
    local v = bs:getv(lengthtable,nlen)
    if v < 16 then
      depths[i] = v
      i = i + 1
    elseif v < 19 then
      local nbt = {2,3,7}
      local nb = nbt[v-15]
      local c = 0
      local n = 3 + bs:getb(nb)
      if v == 16 then
        c = depths[i-1]
      elseif v == 18 then
        n = n + 8
      end
      for j=1,n do
        depths[i] = c
        i = i + 1
      end
    else
      error("wrong entry in depth table for literal/length alphabet: "..v);
    end
  end
  local litdepths = {} for i=1,hlit do table.insert(litdepths,depths[i]) end
  local littable,nlit = hufftable_create(litdepths)
  local distdepths = {} for i=hlit+1,#depths do table.insert(distdepths,depths[i]) end
  local disttable,ndist = hufftable_create(distdepths)
  inflate_loop(out,bs,nlit,ndist,littable,disttable)
end

local function inflate_static(out,bs)
  local cnt = { 144, 112, 24, 8 }
  local dpt = { 8, 9, 7, 8 }
  local depths = {}
  for i=1,4 do
    local d = dpt[i]
    for j=1,cnt[i] do
      table.insert(depths,d)
    end
  end
  local littable,nlit = hufftable_create(depths)
  depths = {}
  for i=1,32 do
    depths[i] = 5
  end
  local disttable,ndist = hufftable_create(depths)
  inflate_loop(out,bs,nlit,ndist,littable,disttable)
end

local function inflate_uncompressed(out,bs)
  bs:flushb(bit.band(bs.n,7))
  local len = bs:getb(16)
  if bs.n > 0 then
    error("Unexpected.. should be zero remaining bits in buffer.")
  end
  local nlen = bs:getb(16)
  if bit.bxor(len,nlen) ~= 65535 then
    error("LEN and NLEN don't match")
  end
  local ret = bs.buf:sub(bs.pos,bs.pos+len-1)
  for i=bs.pos,bs.pos+len-1 do
    table.insert(out,bs.buf:byte(i,i))
  end
  bs.pos = bs.pos + len
end

function zzlib.gunzip(buf)
  local p=11
  local size = buf:len()
  local last,type
  if bit.band(buf:byte(4),8) ~= 0 then
    local pos = buf:find("\0",p)
    local name = buf:sub(p,pos-1)
    p = pos+1
  end
  local unpacked_size = read32(buf,size-3)
  local bs = bitstream_init(buf,p)
  local output = {}
  repeat
    local block
    last = bs:getb(1)
    type = bs:getb(2)
    if type == 0 then
      inflate_uncompressed(output,bs)
    elseif type == 1 then
      inflate_static(output,bs)
    elseif type == 2 then
      inflate_dynamic(output,bs)
    else
      error("unsupported block type")
    end
  until last == 1
  bs:flushb(bit.band(bs.n,7))
  local str = ""
  local size = #output
  local i=1
  while size > 0 do
    local bsize = size>=2000 and 2000 or size
    str = str .. string.char(unpack(output,i,i+bsize-1))
    i = i + bsize
    size = size - bsize
  end
  return str
end

-- init reverse array
for i=0,255 do
  local k=0
  for j=0,7 do
    if bit.band(i,bit.lshift(1,j)) ~= 0 then
      k = k + bit.lshift(1,7-j)
    end
  end
  reverse[i] = k
end

return zzlib
