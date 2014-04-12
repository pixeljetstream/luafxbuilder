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

local glslnvload  = dofile( fxrelfile( "fxlibgenerator.lua") )
local glsluniform = dofile( fxrelfile( "fxlibgenerator_uniform.lua") )

do
  function glslnvload:genheader(obj,code,effect)
    local out = 
  [[
    /* HEADER BEGIN */
    #version 330
    #extension GL_NV_shader_buffer_load : enable
    #define NDE int
    #define GRP ivec2
    
    #define MAXLIGHTS 8

    #ifndef PI
    #define PI 3.14159265358979
    #endif
    
    #ifndef ]]..codeDomain(code)..eol..[[
    #define ]]..codeDomain(code)..eol..[[
    #endif

    #if defined(_VERTEX_)

    flat in layout(location=13) NDE   sys_World;
    flat in layout(location=14) GRP   sys_geometryGroups;
    flat in layout(location=15) GRP   sys_materialGroups;


    out sys_attributes {

      flat NDE  sys_World;
      flat GRP  sys_geometryGroups;
      flat GRP  sys_materialGroups;

    } SYSOUT;

    void SYS_ATTRIBUTES()
    {
      SYSOUT.sys_World = sys_World;
      SYSOUT.sys_geometryGroups = sys_geometryGroups;
      SYSOUT.sys_materialGroups = sys_materialGroups;
    }

    #elif defined(_GEOMETRY_) || defined(_TESS_CONTROL_) || defined(_TESS_EVAL_)

    in sys_attributes {

      flat NDE  sys_World;
      flat GRP  sys_geometryGroups;
      flat GRP  sys_materialGroups;

    } SYSIN[];

    out sys_attributes {

      flat NDE  sys_World;
      flat GRP  sys_geometryGroups;
      flat GRP  sys_materialGroups;

    } SYSOUT;

    void SYS_ATTRIBUTES()
    {
      SYSOUT.sys_World = SYSIN[0].sys_World;
      SYSOUT.sys_geometryGroups = SYSIN[0].sys_geometryGroups;
      SYSOUT.sys_materialGroups = SYSIN[0].sys_materialGroups;
    }

    #define sys_World SYSIN[0].sys_World
    #define sys_geometryGroups SYSIN[0].sys_geometryGroups
    #define sys_materialGroups SYSIN[0].sys_materialGroups

    #else 

    in sys_attributes {

      flat NDE  sys_World;
      flat GRP  sys_geometryGroups;
      flat GRP  sys_materialGroups;

    } SYSIN;

    #define sys_World SYSIN.sys_World
    #define sys_geometryGroups SYSIN.sys_geometryGroups
    #define sys_materialGroups SYSIN.sys_materialGroups

    #endif
    
    #undef GRP
    #undef NDE
    
    uniform mat4 sys_ViewMatrices[2];
    #define sys_ViewProjMatrix  sys_ViewMatrices[0]
    #define sys_ViewMatrixI     sys_ViewMatrices[1]
    
    uniform mat4* sys_world_buffer;
    #define sys_WorldMatrix     sys_world_buffer[sys_World * 2 + 0]
    #define sys_WorldMatrixIT   sys_world_buffer[sys_World * 2 + 1]
    /* HEADER END */]]..eol

    return out..exportEnums()
  end
  
  function glslnvload:canBuffer(group)
    return (countGroupTypeClasses(group,{sampler=true,image=true,atomic=true,}) == 0)
  end
  
  function glslnvload:MakeStorageName(group,buffered)
    if (buffered or self:canBuffer(group)) then
      return "sys_"..groupStructClass(group).."_buffer"
    else
      return glsluniform:MakeStorageName(group)
    end
  end

  function glslnvload:MakeStorage(group)
    if (not self:canBuffer(group)) then
      return glsluniform:MakeStorage(group)
    elseif (group.mode == "instanced") then
      return fxenums.storage.nvloadbuffer_indexed,nvloadlayout:Group(group)
    else
      return fxenums.storage.nvloadbuffer,        nvloadlayout:Group(group)
    end
  end

  function glslnvload:genuniforms(obj, code, effect, env, groups)
    local unis    = ""
    local defs    = ""
    local undefs  = ""
    
    local batchcnt = 0
    for i,group in ipairs(groups or effect.group) do
      local buffered    = self:canBuffer(group)
      if (buffered) then
        local structclass = groupStructClass(group)
        local storename   = self:MakeStorageName(group)
        local batched = group.mode == "instanced"
        local access  = batched and "[sys_"..effect.class.."Groups["..batchcnt.."]]" or "[0]"
        
        batchcnt = batchcnt + (batched and 1 or 0)
        
        if (not env.uniforms[structclass]) then
          env.uniforms[structclass] = true
          unis  = unis..
                  groupStruct(group,nil,structclass,env.hints)..
                  "uniform "..structclass.."* "..storename..";"..eol
                  ..eol
                  
        end
        
        defs    = defs..
                  groupDefine(group,nil,storename..access..".")
        undefs  = undefs..
                  groupUndefine(group,nil)
      else
        local fallback = glsluniform:genuniforms(obj,code,effect,env,{group})
        unis    = unis..fallback.unis
        defs    = defs..fallback.defs
        undefs  = undefs..fallback.undefs
      end
    end
    
    return { unis = unis, defs = defs, undefs = undefs }
  end
  
  function glslnvload:genlights(obj,code,effect,env)
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
        if (group) then
          local structclass = light.class.."_"..light.name.."_s"
        
          out = out..
                groupStruct(group,nil,structclass,env.hints)..eol
        end
      end
      
      -- arrays
        out = out..
              "struct sys_lights_buffer_s {"..eol..
              perLight(
              "  int             sys_num_lights_$LIGHT;"..eol
              )..eol..
              perLight(
              "  light_$LIGHT_s  sys_lights_$LIGHT[$MAXLIGHTS];"..eol
              )..eol..
              "};"..eol..
              "uniform sys_lights_buffer_s* sys_lights_buffer;"..eol..
              eol..
              perLight(
              "#define  sys_num_lights_$LIGHT sys_lights_buffer->sys_num_lights_$LIGHT"..eol..
              "#define  sys_lights_$LIGHT     sys_lights_buffer->sys_lights_$LIGHT"..eol
              )..eol..
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

return glslnvload
