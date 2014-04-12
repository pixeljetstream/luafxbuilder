--[[
    Copyright (c) 2012, NVIDIA CORPORATION. All rights reserved.
    Copyright (c) 2012, Christoph Kubisch. All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions
    are met:
     * Redistributions of source code must retain the above copyright
       notice, this list of conditions and the following disclaimer.
     * Neither the name of NVIDIA CORPORATION nor the names of its
       contributors may be used to endorse or promote products derived
       from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS ``AS IS'' AND ANY
    EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
    IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
    PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
    CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
    EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
    PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
    PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
    OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
    OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

    Contact: Christoph Kubisch ckubisch@nvidia.com 
]]

fxdebug = true

dofile("lua/fxlibprocessor.lua")
 
local function dump(filename,str)
  local f = io.open(filename,"wb")
  f:write(str)
  f:close()
end

local function dumptech(file,eff,techstr,codestr)
  local tech = eff.technique[techstr]
  assert(tech)
  local codeobj = fxcodegen(tech,codestr,"GLSL::uniform")
  dump( (file.."_"..eff.class.."_"..eff.name.."_uniform.glsl"),codeobj)
  local codeobj = fxcodegen(tech,codestr,"GLSL::ubo")
  dump( (file.."_"..eff.class.."_"..eff.name.."_ubo.glsl"),codeobj)
  local codeobj = fxcodegen(tech,codestr,"GLSL::nvload")
  dump( (file.."_"..eff.class.."_"..eff.name.."_nvload.glsl"),codeobj)
  local codeobj = fxcodegen(tech,codestr,"GLSL::nvloadtex")
  dump( (file.."_"..eff.class.."_"..eff.name.."_nvloadtex.glsl"),codeobj)
  local codeobj = fxcodegen(tech,codestr,"GLSL::ubossbotex")
  dump( (file.."_"..eff.class.."_"..eff.name.."_ubossbotex.glsl"),codeobj)
end

local function setGeneratorLights()
  for i,v in ipairs(fxlib.light.effects) do
    fxlights.effects[i] = v
    fxlights.max[i]     = 16
  end
end

if (true) then
  fxfile( "test/testfx.luafx")
    
  setGeneratorLights()
  
  if (true) then
    dumptech("test/out/testfx",fxlib.material.effects.simple,  "GLSL::forward","FragmentShader")
    dumptech("test/out/testfx",fxlib.material.effects.normals, "GLSL::forward","FragmentShader")
    dumptech("test/out/testfx",fxlib.material.effects.difflit, "GLSL::forward","FragmentShader")
    dumptech("test/out/testfx",fxlib.geometry.effects.standard,"GLSL::PosNormalUV","VertexShader")
    dumptech("test/out/testfx",fxlib.geometry.effects.shrink,  "GLSL::PosNormalUV","GeometryShader")
    dumptech("test/out/testfx",fxlib.geometry.effects.hinttest,"GLSL::Test","VertexShader")
  end
  
  if (false) then
    local light  = fxlib.light.effects.gradient
    local group  = light.group.instance
    local function storagedump(group,gen)
      local stype,_,struct = fxgroupstore(group,gen)
      DisplayOutput(group.name,gen,stype,"\n")
      for i,v in ipairs(struct) do
        local str = group.parameter[i] and group.parameter[i].varname or "struct "
        for n,k in pairs(v) do
          str = str.."\t"..n..": "..k.."\t"
        end
        DisplayOutput(str,"\n")
      end
    end
    storagedump(group,"GLSL::ubo")
    storagedump(group,"GLSL::nvload")
  end
end

