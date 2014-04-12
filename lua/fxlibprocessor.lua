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

local print = fxdebug and print or (function() end)
local eol = [[

]]


print "fxlibprocessor: loading ..."
 
function fxrelfile(file,level)
  local function luafilename(level)
    level = level and level + 1 or 2
    local src
    while (true) do
      src = debug.getinfo(level)
      if (src == nil) then return nil,level end
      if (string.byte(src.source) == string.byte("@")) then
        return string.sub(src.source,2),level
      end
      level = level + 1
    end
  end

  local function luafilepath(level)
    local src,level = luafilename(level)
    if (src == nil) then return src,level end
    src = string.match(src,"(.*)[\\/]") or ""
    return src,level
  end
  
  local name,level = luafilepath(level or 3)
  return (file and name) and name.."/"..file or file or name
end

function fxerror(err)
  local msg = debug.traceback(err)
  if (fxdebug) then
    return msg
  end
  -- remove references to fxlibprocessor
  -- then find line with "in main chunk"
  local system = "../fxlibprocessor.lua:%d+:"
  local firstline = msg:match(".-[\r\n]")
        firstline = firstline:gsub(system,"")
  
  return firstline..(msg:match("%s*([^\r\n]+)in main chunk") or "")
end

---------------------------------------------------------
-- Helpers

local function namedTable(tab,key)
  for i,v in pairs(tab) do
    v.name = i
  end
  return tab
end

local function mergeTable(into,src)
  for i,v in pairs(src) do
    into[i] = v
  end
  return into
end

---------------------------------------------------------
-- Config


local effecttypes = namedTable {
  global    = { keyword = "Global",   instanced = 10000,},
  geometry  = { keyword = "Geometry", instanced = 4,},
  light     = { keyword = "Light",    instanced = 1,},
  material  = { keyword = "Material", instanced = 4,},
}
 
local datatypes
do
  local vector = {{2},{3},{4}}
  local glmatrix = {{2,2,suffix="2"},{2,3},{2,4},{3,2},{3,3,suffix="3"},{3,4},{4,2},{4,3},{4,4,suffix="4"}}
  
  datatypes = namedTable {
    float   = {class = "scalar", size = 4, conversion = "float",    },
    vec     = {class = "scalar", size = 4, conversion = "float",    dimension = vector,},
    mat     = {class = "scalar", size = 4, conversion = "float",    dimension = glmatrix,},
    double  = {class = "scalar", size = 8, conversion = "double",   },
    dvec    = {class = "scalar", size = 8, conversion = "double",   dimension = vector,},
    dmat    = {class = "scalar", size = 8, conversion = "double",   dimension = glmatrix,},
    int     = {class = "scalar", size = 4, conversion = "integer",  },
    ivec    = {class = "scalar", size = 4, conversion = "integer",  dimension = vector,},
    bool    = {class = "scalar", size = 4, conversion = "boolean",  },
    bvec    = {class = "scalar", size = 4, conversion = "boolean",  dimension = vector,},
    
    enum            = {class = "scalar", size = 4, conversion = "integer",  noparser = true,},
    pointer         = {class = "scalar", size = 8, conversion = "integer",  noparser = true,},
    imagepointer    = {class = "scalar", size = 8, conversion = "integer",  noparser = true,},
    samplerpointer  = {class = "scalar", size = 8, conversion = "integer",  noparser = true,},
    
    sampler1D         = {class = "sampler", size = 8, conversion = "string",},
    sampler2DRect     = {class = "sampler", size = 8, conversion = "string",},
    sampler2D         = {class = "sampler", size = 8, conversion = "string",},
    sampler3D         = {class = "sampler", size = 8, conversion = "string",},
    samplerCube       = {class = "sampler", size = 8, conversion = "string",},
    samplerBuffer     = {class = "sampler", size = 8, conversion = "string",},
    sampler1DArray    = {class = "sampler", size = 8, conversion = "string",},
    sampler2DArray    = {class = "sampler", size = 8, conversion = "string",},
    samplerCubeArray  = {class = "sampler", size = 8, conversion = "string",},
    sampler2DMS       = {class = "sampler", size = 8, conversion = "string",},
    sampler2DMSArray  = {class = "sampler", size = 8, conversion = "string",},
    
    image1D         = {class = "image", size = 8, conversion = "string",},
    image2D         = {class = "image", size = 8, conversion = "string",},
    image2DRect     = {class = "image", size = 8, conversion = "string",},
    image3D         = {class = "image", size = 8, conversion = "string",},
    imageCube       = {class = "image", size = 8, conversion = "string",},
    imageBuffer     = {class = "image", size = 8, conversion = "string",},
    image1DArray    = {class = "image", size = 8, conversion = "string",},
    image2DArray    = {class = "image", size = 8, conversion = "string",},
    imageCubeArray  = {class = "image", size = 8, conversion = "string",},
    image2DMS       = {class = "image", size = 8, conversion = "string",},
    image2DMSArray  = {class = "image", size = 8, conversion = "string",},
    
    -- doesn't work so well cannot be part of struct, would need too much fixup for now
    --atomic_uint     = {class = "atomic",size = 4, conversion = "integer",},
    
  }
  
  
end

---------------------------------------------------------
-- Main Classes

local function newLib(class)
  local lib = {
    effects = {}, -- indexable by unique idx and name
    count = 0,      
  }
  function lib:Register(name,effect)
    assert(not self.effects[name], "Effect already defined:"..class.." "..name)
    local idx   = self.count + 1
    self.count  = idx
    self.effects[name]  = effect
    self.effects[idx]   = effect
  end
  return lib
end

local function newEnumValue(obj)
  local default = {
    class           = "enumValue",
    
    name            = nil,
    value           = 0,
    enum            = nil,
    idx             = 0,
  }
  return mergeTable(default,obj)
end

local function newEnum(obj)
  local default = {
    class           = "enum",
    
    name            = nil,
    idx             = 1,
    content         = {},
    count           = 0,
  }
  return mergeTable(default,obj)
end

local function newEffect(obj)
  local default = {
    class           = nil,
    classenum       = nil, --fxenums.effect[class],
    
    name            = nil,
    group           = {},
    groupidx        = {},
    groupCount      = 0,
    technique       = {},
    techniqueidx    = {},
    techniqueCount  = 0,
  }
  return mergeTable(default,obj)
end

local function newGroup(obj)
  local default = {
    class           = "group",
    host            = nil,
    
    name            = nil,
    mode            = nil,
    parameter       = {},
    parameteridx    = {},
    parameterCount  = 0,
    
    Storage = function(self, generator, info)
      self.storage = self.storage or  {}
      self.storage[generator] = info
      
      return self
    end
  }
  return mergeTable(default,obj)
end

local function newParameter(obj)
  local default = {
    class       = "parameter",
    group       = nil,
    
    name        = nil,
    varname     = nil,
    arraycnt    = 0,
    
    typerow     = nil,
    typecol     = nil,
    typeclass   = nil,
    typename    = nil,
    typeenum    = nil,
    qualifier   = "",
    
    defaultconv  = 0,
    defaultcnt   = 0,
    defaultvalue = nil,
    
    reference    = nil,
  }
  return mergeTable(default,obj)
end

local function newTechnique(obj)
  local default = {
    class     = "technique",
    host      = nil,
    
    name      = nil,
    option    = nil,
    code      = {},
    codeidx   = {},
    codeCount = 0,
  }
  return mergeTable(default,obj)
end

local function newOption(obj)
  local default = {
    class   = "option",
    tech    = nil,
    content = nil,
  }
  return mergeTable(default,obj)
end

local function newCode(obj)
  local default = {
    class   = "code",
    host    = nil,
    name    = nil,
    content = nil,
  }
  return mergeTable(default,obj)
end

local function newCodeHeader(obj)
  local default = {
    class     = "genheader",
    info      = nil,
    namespace = nil,
  }
  return mergeTable(default,obj)
end

local function newCodeString(obj)
  local default = {
    class   = "genstring",
    info      = nil,
    content   = "",
    uniforms  = true,
  }
  return mergeTable(default,obj)
end

local function newCodeFile(obj)
  local default = {
    class   = "genfile",
    info      = nil,
    filename  = nil,
    uniforms  = true,
  }
  return mergeTable(default,obj)
end

local function newCodeLights(obj)
  local default = {
    class   = "genlights",
    info      = nil,
    technique = nil,
    code      = nil,
  }
  return mergeTable(default,obj)
end

local function newCodeParameterHints(obj)
  local default = {
    class   = "genparameterhints",
    info      = nil,
    hints     = {},
  }
  return mergeTable(default,obj)
end



---------------------------------------------------------
-- System Setup


do
  -- filled by C backend to allow storing enums as 
  -- numbers directly and vice versa
  -- tab[enum] = name
  -- tab[name] = enum
  fxenums = {
    effect      = {},
    generator   = {},
    parameter   = {},
    dataconvert = {},
    group       = {},
    storage     = {
      -- for debug purposes preset these
      custom                = "custom",
      uniform               = "uniform",
      uniformbuffer         = "uniformbuffer",
      uniformbuffer_indexed = "uniformbuffer_indexed",
      storagebuffer_indexed = "storagebuffer_indexed",
      nvloadbuffer          = "nvloadbuffer",
      nvloadbuffer_indexed  = "nvloadbuffer_indexed",
    },
  }
end


do
  -- the main registry for all effects
  -- also is made enum indexable by C backend
  fxlib = {}
  
  fxuserenums = {
    enums   = {},
    values  = {},
    count   = 0,
  }
 
  for class,v in pairs(effecttypes) do
    fxlib[class] = newLib(class)
  end
  
end

do
  -- generators
  fxgenerators = {}
  
  -- the lights used during code generation
  fxlights = {
    effects = {},
    max     = {},
  }
  
  local function newStorage()
    return {
      align   = 1,
      size    = 0,
      offset  = 0,
      stride  = 0,
      element = 0,
    }
  end

  local function newGenerator()
    local gen = {}
    function gen:MakeCode(code,effect,env,genuniforms)
      error("interface not complete, lacks implementation")
    end
    
    function gen:MakeStorage(group)
      error("interface not complete, lacks implementation")
    end
    
    function gen:MakeStorageName(group)
      error("interface not complete, lacks implementation")
    end
    
    return gen
  end
  
  function fxregistergenerator(str,what)
    local fnmake,err
    if (str:sub(-4,-1) == ".lua") then
      fnmake,err = loadfile(str)
    else
      fnmake,err = loadstring(str)
    end
    
    if not fnmake or err then
      error(err)
    end 
  
    local function import(name)
      local f,e = loadfile(name)
      if not f then error(e, 3) end
      setfenv(f, getfenv(3))
      return f
    end
 
    local env   = {}
    local envMT = { __index = getfenv() }
    setmetatable(env,envMT)
    env.newGenerator = newGenerator
    env.newStorage   = newStorage
    env.datatypes    = datatypes
    env.eol          = eol
    env.dofile       = function(str) return import(str)() end
    env.loadfile     = function(str) return import(str) end
    
    local generator = setfenv(fnmake,env)()
    generator.name = what
    fxgenerators[what] = generator
  end
  
  -- code generators
  fxregistergenerator( fxrelfile "fxlibgenerator_uniform.lua",  "GLSL::uniform" )
  fxregistergenerator( fxrelfile "fxlibgenerator_ubo.lua",      "GLSL::ubo")
  fxregistergenerator( fxrelfile "fxlibgenerator_nvload.lua",   "GLSL::nvload")
  fxregistergenerator( fxrelfile "fxlibgenerator_nvloadtex.lua","GLSL::nvloadtex")
  fxregistergenerator( fxrelfile "fxlibgenerator_ubossbotex.lua","GLSL::ubossbotex")
end 

do
  fxids = {} 
  -- the fxid registry
  -- indexable through object or unique index
  -- id  = fxids[obj]
  -- obj = fxids[id]

  local id = 0
  setmetatable(fxids,{
    __index = function(tab,key)
      local idindex = type(key) == "number"
      local v = rawget(tab,key)
      if idindex or v then 
        return v
      end
      
      -- generate new id
      id = id + 1
      rawset(fxids,key,id)
      rawset(fxids,id,key)
      
      return id
    end,
  })
end

 

---------------------------------------------------------
-- Parser 

local function newParser()

  -- scope checking 
  -- so we dont accidently allow wrong functions
  -- in unappropriate situations
  local scopeTest
  local scopeLeave
  local scopeEnter
  local scopeObject = {}
  local scopeReset

  do
    local scopes = {}
    local scopeIndex = 0
    scopeTest = function(level)
      return level == scopes[scopeIndex]
    end
    scopeEnter = function(level,obj)
      scopeIndex = scopeIndex + 1
      scopes[scopeIndex] = level
      scopeObject[level] = obj
    end
    scopeLeave = function(level)
      assert(scopes[scopeIndex] == level, "leaving wrong scope:"..scopes[scopeIndex])
      assert(scopeIndex > 1, "scope underflow")
      scopeIndex = scopeIndex - 1
      scopeLevel = scopes[scopeIndex]
      scopeObject[level] = nil
    end
    scopeReset = function()
      scopes = {}
      scopeObject = {}
      scopeIndex = 0
      scopeEnter("base")
    end
    
  end
  
  local dummyValue = {}
  local function addParameterParser(parserFuncs,basetype,typename,w,h,enum,pointer)
    local typeorig  = (basetype..(w or "")..(h and ("x"..h) or ""))
    local typename  = typename or typeorig
    local typeclass = datatypes[basetype]
    local convert = {
      boolean = "boolean",
      integer = "number",
      float   = "number",
      double  = "number",
      string  = "string",
    }
    local valuetype = convert[typeclass.conversion]

    local function parseParameter(varname)
      assert(scopeTest("group")or scopeTest("base"), "used inside wrong scope")
      local varname   = varname 
      local name      = varname:match("[^%[]+")
      local arraycnt = tonumber(varname:match("%[(%d+)%]") or 0) 
      local cnt      = ((w or 1) * (h or 1)) * math.max(arraycnt,1)
      
      local var = newParameter {
        name      = name,
        varname   = varname,
        arraysize = arraycnt,
        group     = scopeObject.group,
        typeclass = typeclass,
        typename  = typename,
        typeenum  = fxenums.parameter[typeorig],
        typerow   = h or w,
        typecol   = h and w,
        reference = enum or pointer,
      }
      
      local function parseDefault(value)
        if (value == dummyValue) then return var end
        assert(type(value) == "table", "no value provided")
        
        local vdim = h or w
        local flattened = {}
        
        local function flattenValue(v)
          assert(type(v) == valuetype,"value illegal type")
          table.insert(flattened,v)
        end
        
        local function flattenEnum(v)
          assert(type(v) == "string",  "value illegal type")
          local enumvalue = fxuserenums.values[v]
          assert(enumvalue,"enum string not found")
          assert(enumvalue.enum == enum, "enum class mismatch:"..enumvalue.enum.name.." required: "..enum.name)
          table.insert(flattened,enumvalue.value)
        end
        
        local function flattenVector(vec)
          assert(type(vec) == "table","no vector provided")
          local cnt = #vec
          if (cnt == 1) then
            for i=2,vdim do
              vec[i] = vec[1]
            end
            cnt = vdim
          end
          if (cnt == vdim) then
            for i=1,cnt do
              flattenValue(vec[i])
            end
            return vec
          else
            error("illegal vector dimension:"..cnt.." instead of "..vdim)
          end
        end
        
        local function flattenMatrix(mat)
          assert(type(mat) == "table","no matrix provided")
          local cnt = #mat 
          assert(cnt == w, "illegal matrix dimension:"..cnt.." instead of "..w)
          for i=1,cnt do
            flattenVector(mat[i])
          end
        end
        
        local flatten = enum and flattenEnum or h and flattenMatrix or (w and flattenVector) or flattenValue
        
        -- TODO proper sized initializers and type checks
        if (arraycnt > 0) then
          local dim = #value
          assert(dim == arraycnt or dim==1, "value array length wrong, must be 1 or arraycnt")
          
          if (dim == 1) then
            for i=2,arraycnt do
              value[i] = value[1]
            end
          end
          
          for i=1,arraycnt do
            flatten(value[i])
          end
        elseif (w or h) then
          flatten(value)
        else
          flatten(value[1])
        end
        assert( #flattened == cnt, "flattened size mismatch")
        var.defaultvalue = flattened
        var.defaultconv  = fxenums.dataconvert[typeclass.conversion]
        var.defaultcnt   = cnt
        return var
      end
      
      return parseDefault
    end

    -- register in parser
    parserFuncs[enum and enum.name or typename] = parseParameter
  end
  
  ---------------------------------------------------------
  -- EnumDef
  
  local enumParser = {}
  
  local function parseEnumDef(name)
    assert(scopeTest("base"), "used inside wrong scope")
    assert(type(name) == "string", "invalid name value")
    
    local enum = newEnum {
      name = name
    }
    
    local function parseContent(content)
      assert( type(content) == "table", "content missing")
      for i,v in ipairs(content) do
        assert( type(v) == "string", "string required")
        local enumvalue = fxuserenums.values[v]
        assert( enumvalue == nil, enumvalue and "value name:"..v.." already used by enum class:"..enumvalue.enum.name)
        
        local value = newEnumValue {
          name  = v, 
          value = i-1, 
          enum  = enum, 
          idx   = i,
        }
        enum.content[i] = value
        enum.content[v] = value
        enum.count = i
        
        fxuserenums.values[v] = value
      end
      
      fxuserenums.count = fxuserenums.count + 1
      enum.idx = fxuserenums.count
      
      fxuserenums.enums[enum.idx]  = enum
      fxuserenums.enums[enum.name] = enum
      
      addParameterParser(enumParser,"enum",nil,nil,nil,enum)

      scopeLeave("enum")
    end
    
    scopeEnter("enum",enum)
    
    return parseContent
  end
  
  

  ---------------------------------------------------------
  -- Group
  
  local pointerParser = {}

  local instancedValue = "instanced"
  local sharedValue = "shared"
  
  local function parseGroup(name)
    assert(scopeTest("effect"), "used inside wrong scope")
    assert(type(name) == "string", "invalid name value")
    
    local group = newGroup {
      host = scopeObject.effect,
      name = name,
    }
    
    local function parseContent(tab)
      assert(tab, "Group: no content defined")
      for i,v in ipairs(tab) do
        if (type(v) == "function") then
          -- resolve those without default value
          v = v(dummyValue)
        end
        assert(type(v) == "table" and v.class == "parameter", "invalid parameter at index: "..(i-1).." in group: "..name)
        group.parameter[i]      = v
        group.parameter[v.name] = v
        group.parameterCount    = i
        group.parameteridx[v.name] = i
      end
     
      scopeLeave("group")
      return group
    end

    local function parseMode(mode)
      assert(mode == instancedValue or mode == sharedValue, "invalid mode value")
      group.mode = mode
      group.modetype = fxenums.group[mode]
      
      scopeEnter("group",group)
      return parseContent
    end
    
    return parseMode
  end
  
  local function parseGlobalGroup(effectname)
    assert(scopeTest("effect"), "used inside wrong scope")
    assert(type(effectname) == "string", "invalid name value")
    local effect      = fxlib.global.effects[effectname]
    assert(effect, "global effect not found:"..effectname)
    
    local function parseGroupName(groupname)
      assert(type(groupname) == "string", "invalid name value")
      local group = effect.group[groupname]
      assert(group, "global group not found: "..effectname.." "..groupname)
      return group
    end
    
    return parseGroupName
  end

  ---------------------------------------------------------
  -- Technique

  local function parseOptions(content)
    assert(scopeTest("technique"), "used inside wrong scope")
    assert(type(content) == "table", "Options: no content defined")
    
    local option = newOption {
      tech    = scopeObject.technique,
      content = content,
    }
    
    return option
  end
  
  local function getFileLine()
    local info = debug.getinfo(3,"Sl")
    local file = info.source:gsub("\\","/"):sub(2)
    return file..":"..info.currentline,file
  end
  
  local function parseSTRING(content)
    assert(scopeTest("code")or scopeTest("base"), "used inside wrong scope")
    local tab = type(content)=="table" and content
    local content = tab and table.concat(tab,eol) or content
    assert(type(content) == "string", "invalid content value")
    
    local genstring = newCodeString {
      content = content,
      info = getFileLine(),
      uniforms = tab and tab.parameters,
    }
    
    
    return genstring
  end
  
  local function parseFILE(content)
    assert(scopeTest("code")or scopeTest("base"), "used inside wrong scope")
    local tab = type(content)=="table" and content
    local filename = tab and tab[1] or content
    assert(type(filename) == "string", "invalid filename value")
    
    local info,filepath = getFileLine()
    filepath = string.match(filepath,"(.*/)") or "/"
    
    local genfile = newCodeFile {
      filename = filepath..filename,
      info = info,
      uniforms = tab and tab.parameters,
    }
    
    return genfile
  end
  
  local function parseHEADER(namespace)
    assert(scopeTest("code") or scopeTest("base"), "used inside wrong scope")
    assert(type(namespace) == "string", "invalid namespace value")
    
    local genheader = newCodeHeader {
      namespace = namespace,
      info = getFileLine(),
    }
    
    return genheader
  end
  
  local function parseLIGHTS(technique)
    assert(scopeTest("code")or scopeTest("base"), "used inside wrong scope")
    assert( type(technique) == "string", "invalid technique value")
    
    local genlights = newCodeLights {
      technique = technique,
      info = getFileLine(),
    }
    
    local function parseCodeName(name)
      assert(type(name) == "string", "invalid code name")
      genlights.code = name
      
      return genlights
    end
    
    return parseCodeName
  end
  
  local function parsePARAMETERHINTS(hints)
    assert(type(hints) == "table", "table input required")
  
    local genparameterhints = newCodeParameterHints {
      info  = getFileLine(),
      hints = hints,
    }
    
    return genparameterhints
  end

  local function parseCode(name)
    assert(scopeTest("technique"), "used inside wrong scope")
    assert(type(name) == "string", "invalid name value")
    
    local code = newCode {
      host = scopeObject.technique,
      name = name,
    }
    
    local function parseContent(content)
      assert(content, "Code: no content defiend")
      for i,v in ipairs(content) do
        assert(
          ( type(v) == "table" and 
               type(v.class) == "string" and v.class:sub(1,3) == "gen"),
            "illegal content for code definition, only generator objects allowed")
      end
      
      code.content = content
      scopeLeave("code")
      return code
    end
    
    scopeEnter("code",code)
    return parseContent
  end

  local function parseTechnique(name)
    assert(scopeTest("effect"), "used inside wrong scope")
    assert(type(name) == "string", "invalid name value")
    
    local tech = newTechnique {
      host = scopeObject.effect,
      name = name,
    }
    
    local function parseContent(tab)
      assert(type(tab) == "table", "technique invalid argument")
      
      for i,v in ipairs(tab) do
        assert(type(v) == "table", "technique invalid content")
        if (v.class == "code") then
          tech.codeCount = tech.codeCount + 1
          local idx = tech.codeCount
          v.tech    = tech
          tech.code[v.name]     = v
          tech.code[idx]        = v
          tech.codeidx[v.name]  = idx
          for n,k in ipairs(v.content) do
            if (k.class == "genlights") then
              tech.lighting = true
            end
          end
        elseif (v.class == "option") then
          assert( not tech.option, "Technique: Option already defined")
          tech.option = v.content
        else
          error ("Technique: illegal content class")
        end
      end
      scopeLeave("technique")
      tech.option = tech.option or {}
      return tech
    end
    scopeEnter("technique",tech)
    return parseContent
  end

  ---------------------------------------------------------
  -- Effect

  local function addEffectParser(parserFuncs,class,keyword,maxinstanced)

    local function parseEffect(name)
      assert(scopeTest("base"), "used inside wrong scope")
      assert(type(name) == "string", "invalid name value")
      assert(name:match("::") == nil,":: not allowed in effect name")
      
      local effect = newEffect {
        class = class,
        classenum = fxenums.effect[class],
        name = name,
      }
      
      local function parseContent(tab)
        assert(type(tab) == "table", "no content defined")
        
        local instanced = 0
        
        -- make number indexable
        for i,v in ipairs(tab) do
          assert(type(v) == "table" and v.class and effect[v.class], "illegal content class")
          table.insert(effect[v.class],v)
          
          -- also update counters
          local cnt = v.class.."Count"
          effect[cnt] = effect[cnt] + 1
          effect[v.class.."idx"][v.name] = effect[cnt]
          
          -- check for maximums
          if (v.class == "group" and v.mode == instancedValue) then
            instanced = instanced + 1
            assert(instanced <= maxinstanced, "Too many instanced groups: "..v.name)
          end
          
        end
        -- make name indexable
        for i,v in ipairs(tab) do
          effect[v.class][v.name] = v
        end
        
        
        scopeLeave("effect")
        fxlib[class]:Register(name,effect)
      end
      
      scopeEnter("effect",effect)
      return parseContent
    end
    
    parserFuncs[keyword] = parseEffect
  end
  
  ---------------------------------------------------------
  -- loader
  
  local function import(name)
    local f,e = loadfile(name)
    if not f then error(e, 3) end
    setfenv(f, getfenv(3))
    return f
  end
  
  local parserEnv = {
    -- sandboxing
    unpack      = unpack,
    tonumber    = tonumber,
    tostring    = tostring,
    type        = type,
    next        = next,
    pairs       = pairs,
    ipairs      = ipairs,
    print       = print,
    select      = select,
    math        = mergeTable({},math),
    table       = mergeTable({},table),
    string      = mergeTable({},string),
    dofile      = function(str) return import(str)() end,
    loadfile    = function(str) return import(str) end,
    
    enum        = enumParser,
    instanced   = instancedValue,
    shared      = sharedValue,
    EnumDef     = parseEnumDef,
    GlobalGroup = parseGlobalGroup,
    Group       = parseGroup,
    Technique   = parseTechnique,
    Code        = parseCode,
    Options     = parseOptions,
    HEADER      = parseHEADER,
    LIGHTS      = parseLIGHTS,
    STRING      = parseSTRING,
    FILE        = parseFILE,
    PARAMETERHINTS = parsePARAMETERHINTS,
  }
 
  for i,v in pairs(effecttypes) do
    addEffectParser(parserEnv, v.name, v.keyword, v.instanced)
  end

  for i,v in pairs(datatypes) do
    if (not v.noparser) then
      local dim = v.dimension
      if (dim) then
        for n,d in ipairs(dim) do
            addParameterParser(parserEnv,v.name,nil,unpack(d))
          if (d.suffix) then
            addParameterParser(parserEnv,v.name,(v.name..d.suffix),unpack(d))
          end
        end
      else
        addParameterParser(parserEnv,v.name)
        if (v.class == "sampler" or v.class == "image") then
          addParameterParser(parserEnv,v.name,"u"..v.name)
          addParameterParser(parserEnv,v.name,"i"..v.name)
        end
      end
    end
  end

  local parserMT = {
    __index = parserEnv
  }
  
  local parser = {}
  function parser:Load(fn)
    scopeReset()
    local env = {}
    setmetatable(env,parserMT)
    setfenv(fn,env)()
  end
  
  return parser
end
local parser = newParser()

---------------------------------------------------------
-- Public API

function fxfile(filename)
  local fn,err = loadfile(filename)
  assert( not err, err)
  
  parser:Load(fn)
end

function fxstring(content)
  local fn,err = loadstring(content)
  assert( not err, err)
  
  parser:Load(fn)
end

function fxcodegen(tech,codeid,gen)
  local gen = type(gen) == "number" and fxenums.generator[gen] or gen
  local generator = fxgenerators[gen]
  local effect    = tech.host
  local code      = tech.code[codeid]
  assert(generator,"missing generator")
  assert(effect,"missing effect")
  assert(code,"missing code")
  return generator:MakeCode(code,effect)
end

function fxgroupstore(group,gen)
  local gen = type(gen) == "number" and fxenums.generator[gen] or gen
  local generator = fxgenerators[gen]
  assert(generator,"missing generator")
  assert(group,"missing group")
  return generator:MakeStorage(group)
end

function fxgroupstorename(group,gen)
  local gen = type(gen) == "number" and fxenums.generator[gen] or gen
  local generator = fxgenerators[gen]
  assert(generator,"missing generator")
  assert(group,"missing group")
  return generator:MakeStorageName(group)
end

print "fxlibprocessor: done"