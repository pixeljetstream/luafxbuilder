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

-- each generator is evaluated in its own environment

local glsluniform = dofile( fxrelfile( "fxlibgenerator.lua") )

do
  function glsluniform:genheader(obj,code,effect,env)
    
    local out = 
  [[
    /* HEADER BEGIN */
    #version 330

    #define MAXLIGHTS 8

    #ifndef PI
    #define PI 3.14159265358979
    #endif
    
    #ifndef ]]..codeDomain(code)..eol..[[
    #define ]]..codeDomain(code)..eol..[[
    #endif
    
    #define SYS_ATTRIBUTES()
    
    uniform mat4 sys_ViewMatrices[2];
    #define sys_ViewProjMatrix  sys_ViewMatrices[0]
    #define sys_ViewMatrixI     sys_ViewMatrices[1]
    
    uniform mat4 sys_WorldMatrices[2];
    #define sys_WorldMatrix     sys_WorldMatrices[0]
    #define sys_WorldMatrixIT   sys_WorldMatrices[1]
    /* HEADER END */]]..eol
    
    return out..exportEnums()
  end
  
  function glsluniform:MakeStorageName(group)
    local structclass = groupStructClass(group)
    return "sys_"..structclass
  end    
  
  function glsluniform:MakeStorage(group)
    return fxenums.storage.uniform, uniformlayout:Group(group)
  end
  
  function glsluniform:genuniforms(obj, code, effect, env, groups)
    local unis    = ""
    local defs    = ""
    local undefs  = ""
    
    for i,group in ipairs(groups or effect.group) do
      local structclass = groupStructClass(group)
      local storename   = self:MakeStorageName(group)
      if (not env.uniforms[structclass]) then
        env.uniforms[structclass] = true
        unis  = unis..
                groupStruct(group,nil,structclass,env.hints)..
                "uniform "..structclass.." "..storename..";"..eol..eol
      end
      defs    = defs..
                groupDefine(group,nil,storename..".")
      undefs  = undefs..
                groupUndefine(group,nil)
    end
    
    return {unis = unis, defs = defs, undefs = undefs }
  end
  
  function glsluniform:genlights(obj,code,effect,env)
    local out = ""
    
    -- allow light loops for following techniqes
    env.lights = env.lights or {}
    
    
    -- export all light uniforms
    if ( not env.lightGroupExported) then
      env.lightGroupExported = true
      
        out = out..
              "/* LIGHTGROUP BEGIN */"..eol
      
      -- struct defines
      for i,light in ipairs(fxlights.effects) do
        assert(countEffectTypeClasses(light,{sampler = true, image = true},"instanced") == 0, "only scalars supported in instanced light groups")
        
        local group = getEffectGroup(light,"instanced",1)
        if group then
          local structclass = light.class.."_"..light.name.."_s"
        
          out = out..
                groupStruct(group,nil,structclass,env.hints)..eol
        end
      end
      
      -- light arrays
        out = out..
              "layout(std140) uniform sys_lights_buffer {"..eol..
              perLight(
              "  int             sys_num_lights_$LIGHT;"..eol
              )..eol..
              perLight(
              "  light_$LIGHT_s  sys_lights_$LIGHT[$MAXLIGHTS];"..eol
              )..eol..
              "};"..eol..
              "/* LIGHTGROUP END */"..eol..eol
    end
    
    local lights = {}
    out = out..
          exportLights(self,obj,lights,function(...) return self:genuniforms(...) end, "")
  
    env.lights[obj.code] = {
      lights = lights,
      technique = obj.technique,
    }
  
    return out
  end
   
end

return glsluniform