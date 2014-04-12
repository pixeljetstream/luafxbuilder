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

do
  -------------------------------
  -- Memory Layout Logic

  local function newLayout()
    local layout = {}
    function layout:Parameter(var)
      error("interface not complete, lacks implementation")
    end
    function layout:Struct(variables)
      error("interface not complete, lacks implementation")
    end
    function layout:Group(group)
      local struct = {}
      
      for i,p in ipairs(group.parameter) do
        table.insert(struct,self:Parameter(p))
      end
      
      -- add self as last content
      storage = self:Struct(struct)
      table.insert(struct,storage)
      
      return #struct,struct
    end
    
    return layout
  end

  local function baseValue(v,b)
    return math.ceil(v/b)*b
  end
  local function alignValue(v,a)
    local offset = (v % a)
    return v + (offset ~= 0 and (a - offset) or 0)
  end
  
 
  -----------------------
  -- uniformlayout 

  uniformlayout = newLayout()
  function uniformlayout:Parameter(var)
    assert(var.typeclass and datatypes[var.typeclass.name])
    local storage = newStorage()
    if (var.typeclass.class ~= "scalar") then
      return storage
    end
    
    local isarray  = var.arraycnt > 0
    local typesize = var.typeclass.size
    
    local align   =  typesize
    local element = (var.typerow or 1) * typesize

    storage.align   = align
    storage.size    = element * (var.typecol or 1) * (math.max(var.arraycnt,1))
    storage.stride  = element
    storage.element = element
    
    return storage
  end

  function uniformlayout:Struct(vars)
    local storage = newStorage()
    local offset = 0
    local maxalign
    for i,var in ipairs(vars) do
      var.offset = alignValue(offset, var.align)
      offset = var.offset + var.size
      maxalign = maxalign and (math.max(maxalign,var.align)) or var.align
    end
    local size      = baseValue(offset,maxalign)
    storage.align   = maxalign
    storage.size    = size
    storage.element = size
    storage.stride  = size
    
    return storage
  end

  -----------------------
  -- std140layout 
  
  std140layout = newLayout()
  function std140layout:Parameter(var)
    assert(var.typeclass and datatypes[var.typeclass.name])
    local storage = newStorage()
    if (var.typeclass.class ~= "scalar") then
      return storage
    end
    
    local isarray  = var.arraycnt > 0
    local typesize = var.typeclass.size
    
    local align   = ((var.typecol or isarray) and 4 or var.typerow or 1)
          align   = (align == 3 and 4) or align
          align   =  align * typesize
    local element = (var.typerow or 1) * typesize
    local stride  = ((var.typecol or isarray) and 4 or var.typerow or 1) * typesize
    storage.align   = align
    storage.size    = stride * (var.typecol or 1) * (math.max(var.arraycnt,1))
    storage.stride  = stride
    storage.element = element
    
    return storage
  end

  function std140layout:Struct(vars)
    local storage = newStorage()
    local offset = 0
    for i,var in ipairs(vars) do
      var.offset = alignValue(offset, var.align)
      offset = var.offset + var.size
    end
    local size      = baseValue(offset,16)
    storage.align   = 16
    storage.size    = size
    storage.element = size
    storage.stride  = size
    
    return storage
  end
  
  -----------------------
  -- std430layout 

  std430layout = newLayout()
  function std430layout:Parameter(var)
    assert(var.typeclass and datatypes[var.typeclass.name])
    local storage = newStorage()
    --if (var.typeclass.class ~= "scalar") then
    --  return storage
    --end
    
    local isarray = var.arraycnt > 0
    local typesize = var.typeclass.size
    
    local align   =  var.typerow or 1
          align   = (align == 3  and 4) or align
          align   =  align * var.typeclass.size
    local element = (var.typerow or 1) * typesize
    local stride  = (var.typerow == 3 and (isarray or var.typecol) and 4 or var.typerow or 1) * typesize

    storage.align   = align
    storage.size    = stride * (var.typecol or 1) * (math.max(var.arraycnt,1))
    storage.stride  = stride
    storage.element = element
    
    return storage
  end

  function std430layout:Struct(vars)
    local storage = newStorage()
    local offset = 0
    local maxalign
    for i,var in ipairs(vars) do
      var.offset = alignValue(offset, var.align)
      offset = var.offset + var.size
      maxalign = maxalign and (math.max(maxalign,var.align)) or var.align
    end
    local size      = baseValue(offset,maxalign)
    storage.align   = maxalign
    storage.size    = size
    storage.element = size
    storage.stride  = size
    
    return storage
  end
  
  -----------------------
  -- nvloadlayout 

  nvloadlayout = newLayout()
  function nvloadlayout:Parameter(var)
    assert(var.typeclass and datatypes[var.typeclass.name])
    local storage = newStorage()
    --if (var.typeclass.class ~= "scalar") then
    --  return storage
    --end
    
    local isarray = var.arraycnt > 0
    local typesize = var.typeclass.size
    
    local align   =  var.typerow or 1
          align   = (align == 3  and 4) or align
          align   =  align * var.typeclass.size
    local element = (var.typerow or 1) * typesize
    local stride  = (var.typerow == 3 and (isarray or var.typecol) and 4 or var.typerow or 1) * typesize

    storage.align   = align
    storage.size    = stride * (var.typecol or 1) * (math.max(var.arraycnt,1))
    storage.stride  = stride
    storage.element = element
    
    return storage
  end

  function nvloadlayout:Struct(vars)
    local storage = newStorage()
    local offset = 0
    local maxalign
    for i,var in ipairs(vars) do
      var.offset = alignValue(offset, var.align)
      offset = var.offset + var.size
      maxalign = maxalign and (math.max(maxalign,var.align)) or var.align
    end
    local size      = baseValue(offset,maxalign)
    storage.align   = maxalign
    storage.size    = size
    storage.element = size
    storage.stride  = size
    
    return storage
  end
  
end

do
  -------------------------------------------------
  -- helper functions for codegen 
  
  function countGroupTypeClasses(group,classes)
    local found = 0
    for i,p in ipairs(group.parameter) do
      if (classes and classes[p.typeclass.class]) then
        found = found + 1
      end
    end
    
    return found
  end
  
  function countEffectTypeClasses(effect,classes,mode)
    local found = 0
    for i,group in ipairs(effect.group) do
      if (not mode or group.mode == mode ) then
        found = found + countGroupTypeClasses(group,classes)
      end
    end
    
    return found
  end
  
  function countEffectGroups(effect,mode)
    local found = 0
    for i,group in ipairs(effect.group) do
      found = found + (group.mode == mode and 1 or 0)
    end
    
    return found
  end
  
  function getEffectGroup(effect,mode,n)
    local found = 0
    for i,group in ipairs(effect.group) do
      found = found + (group.mode == mode and 1 or 0)
      if (found == n) then
        return group 
      end
    end
  end
  
    
  function groupStructClass(group)
    local grpeffect   = group.host
    return grpeffect.class.."_"..grpeffect.name.."_"..group.name
  end
  
  function groupParameters(group,ignoreclass,entry,hints)
    local content = ""
    for n,p in ipairs(group.parameter) do
      if not (ignoreclass and ignoreclass[p.typeclass.class]) then
        local ph    = hints and hints[p.name] or {}
        local param = entry:gsub("$(%w+)",ph)
              param = param:gsub("$(%w+)",p)
              param = param:gsub(" enum "," int ")
              param = param:gsub(" ushort "," uint ")
        
        content = content..param..eol
      end
    end
    
    return content
  end
  
  function groupStruct(group,ignoreclass,name,hints)
    return  "struct "..name.." {"..eol..
            groupParameters( group, ignoreclass,
            "  $qualifier $typename $varname;",hints)..
            "};"..eol
  end
  
  function groupDefine(group,ignoreclass,access)
    return groupParameters( group, ignoreclass,
            "#define $varname "..access.."$varname")
  end
  
  function groupUndefine(group,ignoreclass,variable)
    return groupParameters( group, ignoreclass,
            "#undef $varname")
  end
  
  function perLight(pattern)
    local str = ""
    for i,light in ipairs(fxlights.effects) do
      str = str..(pattern:gsub("$LIGHT",   light.name):gsub("$MAXLIGHTS",fxlights.max[i]))
    end
    return str
  end
 
  function resolveLightLoops(str,env)
    str = str:gsub('SYS_LIGHT_LOOP%s*%(%s*"([%w_%s]+)"%s*%)%s*(%b{})',
      function(codekey,ctx)
        assert(env.lights[codekey], "Light loop definition for: "..codekey.." not found")
        
        local out = ""
        local lights = env.lights[codekey].lights
        for i,light in ipairs(lights) do
              out = out..
                    "for (int sys_Light = 0; sys_Light < sys_num_lights_"..light.name .."; sys_Light++)"..
                    ctx:gsub("SYS_LIGHT%s*%(","light_"..light.name.."(sys_Light, ")
        end
        
        return out
      end
    )
    return str
  end
  
  -- specialized uniform generator for lights
  -- instanced groups are treated differently
  --   only accessor defines are generated, no uniforms
  function exportLights(genclass,genlight,outlights,genuniforms, prefix)
    local function genlightuniforms(obj,code,effect,env,groups)
      local prefix = prefix or ""
      
      local unis      = ""
      local defs      = ""
      local undefs    = ""
      
      for i,group in ipairs(groups or effect.group) do
        if (group.mode == "instanced") then
          local access = prefix.."sys_lights_"..effect.name.."[sys_Light]."
          defs    = defs..
                    groupDefine(group,nil, access)
          undefs  = undefs..
                    groupUndefine(group,nil)
        else
          -- fall back to regular uniform generator
          local default = genuniforms(obj,code,effect,env,{group})
          unis    = unis..default.unis
          defs    = defs..default.defs
          undefs  = undefs..default.undefs
        end
      end

      return { unis = unis, defs = defs, undefs = undefs }
    end
    
    out = "/* LIGHT CODE "..genlight.technique.." "..genlight.code.." BEGIN */"..eol
          -- code 
          for i,light in ipairs(fxlights.effects) do
            local tech = light.technique[genlight.technique]
            if (tech and tech.code[genlight.code]) then
              table.insert(outlights,light)
              
              out = out..
                (genclass:MakeCode(tech.code[genlight.code],light,env,genlightuniforms))..eol
            end
          end
    out = out..
          "/* LIGHT CODE "..genlight.technique.." "..genlight.code.." END */"
    
    return out
  end
  
  function exportEnums()
        out = "    /* ENUMS BEGIN */"..eol
    for i,enum in ipairs(fxuserenums.enums) do
        out = out..
              "    /* "..enum.name.." */"..eol
      for n,v in ipairs(enum.content) do
        out = out..
              "      #define "..v.name.." "..v.value..eol
      end
    end
        out = out..
              "    /* ENUMS END */"..eol
    
    return out
  end

  function codeDomain(code)
    local domains = {
      VertexShader = "_VERTEX_",
      FragmentShader = "_FRAGMENT_",
      GeometryShader = "_GEOMETRY_",
      TessEvalShader = "_TESS_EVAL_",
      TessControlShader = "_TESS_CONTROL_",
    }
    
    return domains[code.name] or "_UNKNOWN_DOMAIN_"
  end
  
  
  -----------------------------------------
  -- generator baseclass
  
  local generator = newGenerator()
  
  function generator:genstring(obj,code,effect,env)
    return obj.content
  end
  
  function generator:genfile(obj,code,effect,env)
    local f = io.open(obj.filename,"rb")
    assert(f, "file not found:"..obj.filename)
    local tx = f:read("*a")
    f:close()
    f = nil
    return "  /* FILE "..obj.filename.." */"..eol..tx
  end
  
  function generator:genparameterhints(obj,code,effect,env)
    env.hints = obj.hints
  
    return ""
  end
  
  function generator:MakeCode(code,effect,env,genuniforms)
    local env   = env or { uniforms = {}, }
    local out   = "/* "..effect.class..  " "..effect.name.." */"..eol..
                  "/* "..code.host.name.." "..  code.name.." */"..eol..
                  "  /* "..self.name.." */"..eol
    
    local uniforms
    for i,genobj in ipairs(code.content) do
      local genstr = self[genobj.class](self,genobj,code,effect,env)
      if (genstr) then
        
        if (genobj.uniforms and not uniforms) then
          uniforms = genuniforms and genuniforms(genobj, code, effect, env) or self:genuniforms(genobj, code, effect, env)
          out = out..uniforms.unis..eol..uniforms.defs..eol
        end
        
        if (env.lights) then
          genstr = resolveLightLoops(genstr,env)
        end
        
          out = out.. 
                  "  /* CODE "..genobj.class.." BEGIN */"..eol..
                  "  /* SRC  "..genobj.info.." */"..eol..
                  genstr..eol..
                  "  /* CODE "..genobj.class.." END */"..eol..eol
      end
    end
    
    if (uniforms) then
      out = out..uniforms.undefs..eol 
    end
    
    return out
  end
  
  return generator
end 

