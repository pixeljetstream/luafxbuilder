/*
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
*/

#define FXBUILDER_USEVECTORCHECK 1

#include <luafxbuilder/luafxbuilder.h>

#if FXBUILDER_USEVECTORCHECK
#include <vector>
#endif

#include <lua.hpp>
#include <assert.h>
#include <string.h>
#include <stdlib.h>

namespace luafxbuilder
{
  #define TOSTRING(x) case x: return #x

  enum DataConvert {
    DATACONVERT_UNKNOWN = 0,
    DATACONVERT_FLOAT,
    DATACONVERT_DOUBLE,
    DATACONVERT_INTEGER,
    DATACONVERT_BOOLEAN,
    DATACONVERT_STRING,
    NUM_DATACONVERTS,
  };

  static const size_t dataConvertSize[NUM_DATACONVERTS] = {
    0,
    sizeof(float),
    sizeof(double),
    sizeof(int),
    sizeof(int),
    sizeof(char),
  };

  const char* DataConvert_toString(DataConvert type)
  {
    switch(type)
    {
    case DATACONVERT_UNKNOWN:   return "unknown";
    case DATACONVERT_FLOAT:     return "float";
    case DATACONVERT_DOUBLE:    return "double";
    case DATACONVERT_INTEGER:   return "integer";
    case DATACONVERT_BOOLEAN:   return "boolean";
    case DATACONVERT_STRING:    return "string";
    }
    assert(!"illegal DataConvert");
    return NULL;
  }

  const char* GroupType_toString(GroupType type)
  {
    switch(type)
    {
    case GROUP_SHARED:        return "shared";
    case GROUP_INSTANCED:     return "instanced";
    }
    assert(!"illegal GroupType");
    return NULL;
  }

  const char* StorageType_toString(StorageType type)
  {
    switch(type)
    {
    case STORAGE_NONE:                  return "none";
    case STORAGE_UNIFORM:               return "uniform";
    case STORAGE_UNIFORMBUFFER:         return "uniformbuffer";
    case STORAGE_UNIFORMBUFFER_INDEXED: return "uniformbuffer_indexed";
    case STORAGE_STORAGEBUFFER_INDEXED: return "storagebuffer_indexed";
    case STORAGE_NVLOADBUFFER:          return "nvloadbuffer";
    case STORAGE_NVLOADBUFFER_INDEXED:  return "nvloadbuffer_indexed";
    }
    assert(!"illegal StorageType");
    return NULL;
  }

  const char* EffectType_toString(EffectType type)
  {
    switch(type)
    {
    case EFFECT_GLOBAL:   return "global";
    case EFFECT_GEOMETRY: return "geometry";
    case EFFECT_LIGHT:    return "light";
    case EFFECT_MATERIAL: return "material";
    }
    assert(!"illegal EffectType");
    return NULL;
  }

  const char* ParameterType_toString(ParameterType type)
  {
    switch(type)
    {
      case PARAMETER_NONE:                return "none";
      case PARAMETER_BOOL:                return "bool";
      case PARAMETER_BVEC2:               return "bvec2";
      case PARAMETER_BVEC3:               return "bvec3";
      case PARAMETER_BVEC4:               return "bvec4";
      case PARAMETER_INT:                 return "int";
      case PARAMETER_IVEC2:               return "ivec2";
      case PARAMETER_IVEC3:               return "ivec3";
      case PARAMETER_IVEC4:               return "ivec4";
      case PARAMETER_UINT:                return "uint";
      case PARAMETER_UVEC2:               return "uvec2";
      case PARAMETER_UVEC3:               return "uvec3";
      case PARAMETER_UVEC4:               return "uvec4";
      case PARAMETER_FLOAT:               return "float";
      case PARAMETER_VEC2:                return "vec2";
      case PARAMETER_VEC3:                return "vec3";
      case PARAMETER_VEC4:                return "vec4";
      case PARAMETER_MAT2X2:              return "mat2x2";
      case PARAMETER_MAT2X3:              return "mat2x3";
      case PARAMETER_MAT2X4:              return "mat2x4";
      case PARAMETER_MAT3X2:              return "mat3x2";
      case PARAMETER_MAT3X3:              return "mat3x3";
      case PARAMETER_MAT3X4:              return "mat3x4";
      case PARAMETER_MAT4X2:              return "mat4x2";
      case PARAMETER_MAT4X3:              return "mat4x3";
      case PARAMETER_MAT4X4:              return "mat4x4";
      case PARAMETER_SAMPLER_1D:          return "sampler1D";
      case PARAMETER_SAMPLER_2D:          return "sampler2D";
      case PARAMETER_SAMPLER_2DRECT:      return "sampler2DRect";
      case PARAMETER_SAMPLER_3D:          return "sampler3D";
      case PARAMETER_SAMPLER_CUBE:        return "samplerCube";
      case PARAMETER_SAMPLER_1D_ARRAY:    return "sampler1DArray";
      case PARAMETER_SAMPLER_2D_ARRAY:    return "sampler2DArray";
      case PARAMETER_SAMPLER_CUBE_ARRAY:  return "samplerCubeArray";
      case PARAMETER_SAMPLER_2DMS:        return "sampler2DMS";
      case PARAMETER_SAMPLER_2DMS_ARRAY:  return "sampler2DMSArray";
      case PARAMETER_SAMPLER_BUFFER:      return "samplerBuffer";
      case PARAMETER_IMAGE_1D:            return "image1D";
      case PARAMETER_IMAGE_2D:            return "image2D";
      case PARAMETER_IMAGE_2DRECT:        return "image2DRect";
      case PARAMETER_IMAGE_3D:            return "image3D";
      case PARAMETER_IMAGE_CUBE:          return "imageCube";
      case PARAMETER_IMAGE_1D_ARRAY:      return "image1DArray";
      case PARAMETER_IMAGE_2D_ARRAY:      return "image2DArray";
      case PARAMETER_IMAGE_CUBE_ARRAY:    return "imageCubeArray";
      case PARAMETER_IMAGE_2DMS:          return "image2DMS";
      case PARAMETER_IMAGE_2DMS_ARRAY:    return "image2DMSArray";
      case PARAMETER_IMAGE_BUFFER:        return "imageBuffer";
      //case PARAMETER_ATOMIC_BUFFER:       return "atomic_uint";
      case PARAMETER_ENUM:                return "enum";
    }
    assert(!"illegal ParameterType");
    return NULL;
  }

  const char* GeneratorType_toString(GeneratorType type)
  {
    switch(type)
    {
    case GENERATOR_GLSL_UNIFORM:      return "GLSL::uniform";
    case GENERATOR_GLSL_UBO:          return "GLSL::ubo";
    case GENERATOR_GLSL_NVLOAD:       return "GLSL::nvload";
    case GENERATOR_GLSL_NVLOADTEX:    return "GLSL::nvloadtex";
    case GENERATOR_GLSL_UBOSSBOTEX:   return "GLSL::ubossbotex";
    }
    assert(!"illegal GeneratorType");
    return NULL;
  }

  enum FixedStackPos {
    FXENUMS = 1,        // must start at 1!
    FXBUILDER,
    FXIDS,
    FXERROR,
    FXLIGHTS,
    FXUSERENUMS,
    FXLAST,
    FXTOP = FXLAST - 1,
  };

  // purely for debugging purposes
  // insert wherever there were problems

#ifdef _DEBUG

#if FXBUILDER_USEVECTORCHECK
  enum LuaType {
    LUATYPE_NONE=           LUA_TNONE,
    LUATYPE_NIL=            LUA_TNIL,
    LUATYPE_BOOLEAN=        LUA_TBOOLEAN,
    LUATYPE_LIGHTUSERDATA=  LUA_TLIGHTUSERDATA,
    LUATYPE_NUMBER=         LUA_TNUMBER,
    LUATYPE_STRING=         LUA_TSTRING,
    LUATYPE_TABLE=          LUA_TTABLE,
    LUATYPE_FUNCTION=       LUA_TFUNCTION,
    LUATYPE_USERDATA=       LUA_TUSERDATA,
    LUATYPE_THREAD=         LUA_TTHREAD,
  }; 

  struct LuaStackEntry {
    LuaType     type;
    const void* pointer;
    const char* string;
    LUA_NUMBER  number;
    bool        boolean;

    LuaStackEntry() : type(LUATYPE_NONE), string(NULL), number(0), pointer(NULL), boolean(false) {

    }
  };
  static void LuaStateCheck(LuaState L, const char*what=NULL){
    int level = lua_gettop(L);
    std::vector<LuaStackEntry>  stack;
    while(level > 0){
      int type = lua_type(L,-level);
      LuaStackEntry entry;
      entry.type = (LuaType)type;

      switch(type){
        case LUA_TBOOLEAN:
          entry.boolean = lua_toboolean(L,-level) ? true : false;
          break;
        case LUA_TSTRING:
          entry.string  = lua_tostring(L,level);
          break;
        case LUA_TNUMBER:
          entry.number  = lua_tonumber(L,level);
          break;
        default:
          entry.pointer = lua_topointer(L,level);
          break;
      }

      stack.push_back(entry);

      level--;
    }
    stack;
  }
#else
  static void LuaStateCheck(LuaState L, const char*what=NULL){
    int level = lua_gettop(L);
    printf("LuaStack: %s\n",what ? what : "");
    while(level > 0){
      int type = lua_type(L,level);
      const char* current = lua_typename(L,type);

      switch(type){
      case LUA_TNIL:
        printf("%d:\t%s\n",level,current);
        break;
      case LUA_TBOOLEAN:
        printf("%d:\t%s\t%s\n",level,current,lua_toboolean(L,level) ? "true" : "false");
        break;
      case LUA_TSTRING:
        printf("%d:\t%s\t%s\n",level,current,lua_tostring(L,level));
        break;
      case LUA_TNUMBER:
        printf("%d:\t%s\t%f\n",level,current,lua_tonumber(L,level));
        break;
      default:
        printf("%d:\t%s\t%p\n",level,current,lua_topointer(L,level));
        break;
      }

      level--;
    }
    printf("\n");
  }
#endif
#else
  static void LuaStateCheck(LuaState L, const char*what=NULL)
  {

  }
#endif

  class LuaStatePreserve 
  {
  private:
    LuaState  m_state;
    int       m_top;

  public:
    inline LuaStatePreserve(LuaState state) {
      m_state = state;
      m_top = lua_gettop(state);
    }

    inline ~LuaStatePreserve(){
      lua_settop(m_state,m_top);
    }

    inline LuaState getState(){
      return m_state;
    }
  };

  class LuaStateObjOperation 
  {
  private:
    LuaStatePreserve    m_preserve;
  public:
    inline LuaStateObjOperation(LuaState L, size_t id) : m_preserve(L) {
      lua_rawgeti(L,FXIDS,(int)id);
      assert(lua_istable(L,-1));
    }

  };

  extern "C" {
    int LuaStatePanicHandler(LuaState L){
      // when this happens typically everything is too late
      // and too messy to recover (albeit possible through
      // use of longjump)
      // the lua threads stack will be fully cleared
      // only leftover is the error message
      const char* error = lua_tostring(L,-1);
      assert(0 && error);
      return 0;
    }
  }



  static inline size_t outputString(const char* data, size_t datasize, char* buffer, size_t buffersize)
  {
    if (buffer) {
      size_t written = buffersize > datasize ? datasize : buffersize;
      memcpy(buffer,data,written);
      return written;
    }
    else{
      return datasize;
    }
  }

  size_t System::getLastErrorString(char* buffer, size_t buffersize)
  {
    return outputString(m_lastError, m_lastErrorSize, buffer, buffersize);
  }

  std::string System::getLastErrorString()
  {
    return std::string(m_lastError);
  }

  void System::updateError()
  {
    LuaState L = m_luaState;
    const char* errormsg = lua_tolstring(L,-1,&m_lastErrorSize);
    assert(errormsg);

    m_lastError = (char*) realloc(m_lastError,m_lastErrorSize);
    memcpy(m_lastError,errormsg,m_lastErrorSize);

    lua_pop(L,1);
  }

  static inline void registerEnum(LuaState L, const char* name, int enumvalue )
  {
    // tab[name]=value
    lua_pushstring  (L,name);
    lua_pushinteger (L,enumvalue);
    lua_rawset      (L,-3);

    // tab[value]=name
    lua_pushinteger (L,enumvalue);
    lua_pushstring  (L,name);
    lua_rawset      (L,-3);
  }

  error System::init(const char* processorFile)
  {
    m_lastError = NULL;
    m_lastErrorSize = 0;

    LuaState L = luaL_newstate();
    m_luaState = L;
    lua_atpanic(L,LuaStatePanicHandler);

#ifdef _DEBUG
    /* more verbose error messages, including full stack info */
    lua_pushboolean(L,1);
    lua_setglobal(L,"fxdebug");
#endif

    luaL_openlibs(L);
    if (luaL_dofile(L, processorFile)){
      updateError();
      return true;
    }
    // prepare the stack for fast access to frequent tables
    lua_getglobal(L,"fxenums");
    assert(lua_type(L,-1) == LUA_TTABLE);
    assert(lua_gettop(L)  == FXENUMS);
    lua_getglobal(L,"fxlib");
    assert(lua_type(L,-1) == LUA_TTABLE);
    assert(lua_gettop(L)  == FXBUILDER);
    lua_getglobal(L,"fxids");
    assert(lua_type(L,-1) == LUA_TTABLE);
    assert(lua_gettop(L)  == FXIDS);
    lua_getglobal(L,"fxerror");
    assert(lua_type(L,-1) == LUA_TFUNCTION);
    assert(lua_gettop(L)  == FXERROR);
    lua_getglobal(L,"fxlights");
    assert(lua_type(L,-1) == LUA_TTABLE);
    assert(lua_gettop(L)  == FXLIGHTS);
    lua_getglobal(L,"fxuserenums");
    assert(lua_type(L,-1) == LUA_TTABLE);
    assert(lua_gettop(L)  == FXUSERENUMS);
    

    // initialize enum table
    lua_getfield(L,FXENUMS,"effect");
    for (int i = 0; i < NUM_EFFECTS; i++){
      registerEnum(L,EffectType_toString((EffectType)i),i);
    }
    lua_pop(L,1);

    lua_getfield(L,FXENUMS,"parameter");
    for (int i = 0; i < NUM_PARAMETERS; i++){
      registerEnum(L,ParameterType_toString((ParameterType)i),i);
    }
    lua_pop(L,1);

    lua_getfield(L,FXENUMS,"generator");
    for (int i = 0; i < NUM_GENERERATORS; i++){
      registerEnum(L,GeneratorType_toString((GeneratorType)i),i);
    }
    lua_pop(L,1);

    lua_getfield(L,FXENUMS,"dataconvert");
    for (int i = 0; i < NUM_DATACONVERTS; i++){
      registerEnum(L,DataConvert_toString((DataConvert)i),i);
    }
    lua_pop(L,1);

    lua_getfield(L,FXENUMS,"group");
    for (int i = 0; i < NUM_GROUPS; i++){
      registerEnum(L,GroupType_toString((GroupType)i),i);
    }
    lua_pop(L,1);

    lua_getfield(L,FXENUMS,"storage");
    for (int i = 0; i < NUM_STORAGES; i++){
      registerEnum(L,StorageType_toString((StorageType)i),i);
    }
    lua_pop(L,1);

    // make effectlib enum indexable
    for (int i = 0; i < NUM_EFFECTS; i++){
      lua_getfield(L,FXBUILDER, EffectType_toString((EffectType)i) );
      assert(lua_type(L,-1) == LUA_TTABLE);
      lua_rawseti (L,FXBUILDER, i );
    }

    // make generatorlib enum indexable
    lua_getglobal(L,"fxgenerators");
    assert(lua_type(L,-1) == LUA_TTABLE);
    for (int i = 0; i < NUM_GENERERATORS; i++){
      lua_getfield(L,-1, GeneratorType_toString((GeneratorType)i) );
      assert(lua_type(L,-1) == LUA_TTABLE);
      lua_rawseti (L,-2, i );
    }
    lua_pop(L,1);

    return false;
  }

  void System::deinit()
  {
    lua_close(m_luaState);
    m_luaState = NULL;
  }

  error System::addLibrary(const char* funcname, const char* buffer, size_t buffersize)
  {
    LuaState L = m_luaState;
    LuaStatePreserve preserve(L);
    lua_getglobal(L,funcname);
    lua_pushlstring(L,buffer,buffersize);
    if (lua_pcall(L,1,0,FXERROR)){
      updateError();
      return true;
    }
    return false;
  }

  error System::addLibraryFile( const char* filename )
  {
    return addLibrary("fxfile",filename,strlen(filename));
  }

  error System::addLibraryString( const char* buffer, size_t buffersize )
  {
    return addLibrary("fxstring",buffer, buffersize);
  }

  int System::getEffectCount( EffectType effecttype )
  {
    LuaState L = m_luaState;
    LuaStatePreserve preserve(L);
    lua_rawgeti(L,FXBUILDER, effecttype);
    lua_getfield(L,-1,"count");
    int count = (int)lua_tointeger(L,-1);
    return count;
  }

  inline size_t System::getID()
  {
    LuaState L = m_luaState;    // 0 obj
    lua_gettable(L,FXIDS);      // 0 id = fxids[obj]
    int id = (int)lua_tointeger(L,-1);
    return id;
  }

  EffectID System::getEffect( EffectType effecttype, int i )
  {
    LuaState L = m_luaState;
    LuaStatePreserve preserve(L);
    lua_rawgeti (L,FXBUILDER, effecttype);
    lua_getfield(L,-1,"effects");
    lua_rawgeti (L,-1,i + 1);

    assert(lua_istable(L,-1) && "illegal index");

    EffectID id = (EffectID)getID();

    return id;
  }

  EffectID System::getEffect( EffectType effecttype, const char* name )
  {
    LuaState L = m_luaState;
    LuaStatePreserve preserve(L);
    lua_rawgeti (L,FXBUILDER, effecttype );
    lua_getfield(L,-1,"effects");
    lua_getfield(L,-1,name);

    if (!lua_istable(L,-1)){
      return 0;
    }

    EffectID id = (EffectID)getID();

    return id;
  }


  inline int System::idGetCount(size_t id, const char* what)
  {
    LuaState L = m_luaState;
    LuaStateObjOperation idop(L,id);
    lua_getfield(L,-1,what);
    assert(lua_isnumber(L,-1));
    int cnt = (int)lua_tointeger(L,-1);
    return cnt;
  }

  int System::effectGetGroupCount( EffectID effect )
  {
    return idGetCount((size_t)effect,"groupCount");
  }
  int System::effectGetTechniqueCount( EffectID effect )
  {
    return idGetCount((size_t)effect,"techniqueCount");
  }

  int System::techniqueGetCodeCount( TechID tech )
  {
    return idGetCount((size_t)tech,"codeCount");
  }

  int System::groupGetParameterCount( GroupID group )
  {
    return idGetCount((size_t)group,"parameterCount");
  }

  inline size_t System::idGetName(size_t id, char* buffer, size_t buffersize)
  {
    LuaState L = m_luaState;
    LuaStateObjOperation idop(L,id);
    lua_getfield(L,-1,"name");
    assert(lua_isstring(L,-1));

    size_t sz;
    const char* str = lua_tolstring(L,-1,&sz);
    sz = outputString(str,sz,buffer,buffersize);

    return sz;
  }

  size_t System::effectGetName( EffectID effect, char* buffer, size_t buffersize )
  {
    return idGetName((size_t)effect,buffer,buffersize);
  }

  size_t System::groupGetName( GroupID group, char* buffer, size_t buffersize )
  {
    return idGetName((size_t)group,buffer,buffersize);
  }

  size_t System::techniqueGetName( TechID tech, char* buffer, size_t buffersize )
  {
    return idGetName((size_t)tech,buffer,buffersize);
  }

  size_t System::enumGetName( EnumID enumtype, char* buffer, size_t buffersize )
  {
    return idGetName((size_t)enumtype,buffer,buffersize);
  }

#if LUAFXBUILDER_USESTRING
  inline std::string System::idGetName(size_t id)
  {
    LuaState L = m_luaState;
    LuaStateObjOperation idop(L,id);
    lua_getfield(L,-1,"name");
    assert(lua_isstring(L,-1));

    size_t sz;
    const char* str = lua_tolstring(L,-1,&sz);

    return std::string(str,sz);
  }

  std::string System::effectGetName( EffectID effect )
  {
    return idGetName((size_t)effect);
  }

  std::string System::groupGetName( GroupID group )
  {
    return idGetName((size_t)group);
  }

  std::string System::techniqueGetName( TechID tech )
  {
    return idGetName((size_t)tech);
  }

  std::string System::enumGetName( EnumID enumtype )
  {
    return idGetName((size_t)enumtype);
  }
#endif

  inline size_t System::idGetSubID(size_t id, const char* what, int i)
  {
    LuaState L = m_luaState;
    LuaStateObjOperation idop(L,id);
    lua_getfield(L,-1,what);
    lua_rawgeti (L,-1,i + 1);
    assert(lua_istable(L,-1));
    return getID();
  }

  GroupID System::effectGetGroup( EffectID effect, int i )
  {
    return (GroupID)idGetSubID((size_t)effect,"group",i);
  }
  TechID System::effectGetTechnique( EffectID effect, int i )
  {
    return (TechID)idGetSubID((size_t)effect,"technique",i);
  }

  inline size_t System::idGetSubID(size_t id, const char* what, const char* name)
  {
    LuaState L = m_luaState;
    LuaStateObjOperation idop(L,id);
    lua_getfield(L,-1,what);
    lua_getfield(L,-1,name);
    if (lua_istable(L,-1))
    {
      return getID();
    }
    else
    {
      return 0;
    }
  }

  GroupID System::effectGetGroup( EffectID effect, const char* name )
  {
    return (GroupID)idGetSubID((size_t)effect,"group", name);
  }

  TechID System::effectGetTechnique( EffectID effect, const char* name )
  {
    return (TechID)idGetSubID((size_t)effect,"technique", name);
  }

  inline size_t System::idGetSubID(size_t id, const char* what)
  {
    LuaState L = m_luaState;
    LuaStateObjOperation idop(L,id);
    lua_getfield(L,-1,what);
    if (lua_istable(L,-1))
    {
      return getID();
    }
    else
    {
      return 0;
    }
  }

  EffectID System::groupGetEffect( GroupID group )
  {
    return (EffectID)idGetSubID((size_t)group,"host");
  }

  EffectID System::techniqueGetEffect( TechID tech )
  {
    return (EffectID)idGetSubID((size_t)tech,"host");
  }

  //////////////////////////////////////////////////////////////////////////

  inline int System::idGetSubIdx( size_t id, const char* what, const char *name )
  {
    LuaState L = m_luaState;
    LuaStateObjOperation idop(L,id);
    lua_getfield(L,-1,what);
    lua_getfield(L,-1,name);
    if (lua_isnumber(L,-1)){
      return (int)lua_tointeger(L,-1) - 1;
    }
    return -1;
  }


  int System::effectGetGroupIndex( EffectID effect, const char* name )
  {
    return idGetSubIdx((size_t)effect,"groupidx",name);
  }

  int System::effectGetTechniqueIndex( EffectID effect, const char* name )
  {
    return idGetSubIdx((size_t)effect,"techniqueidx",name);
  }

  int System::techniqueGetCodeIndex( TechID tech, const char* name )
  {
    return idGetSubIdx((size_t)tech,"codeidx",name);
  }

  int System::groupGetParameterIndex( GroupID group, const char* name )
  {
    return idGetSubIdx((size_t)group,"parameteridx",name);
  }

  //////////////////////////////////////////////////////////////////////////

  inline size_t System::idGetSubName( size_t id, const char* what, int i, char* buffer, size_t buffersize )
  {
    LuaState L = m_luaState;
    LuaStateObjOperation idop(L,id);
    lua_getfield(L,-1,what);
    lua_rawgeti (L,-1, i + 1);
    assert(lua_istable(L,-1));
    lua_getfield(L,-1,"name");

    size_t sz;
    const char* str = lua_tolstring(L,-1,&sz);
    sz = outputString(str,sz,buffer,buffersize);

    return sz;
  }

  size_t System::techniqueGetCodeName( TechID tech, int i, char* buffer, size_t buffersize )
  {
    return idGetSubName((size_t)tech, "code", i, buffer, buffersize);
  }

  size_t System::groupGetParameterName( GroupID group, int i, char* buffer, size_t buffersize )
  {
    return idGetSubName((size_t)group, "parameter", i, buffer, buffersize);
  }

  size_t System::enumGetValueName( EnumID enumtype, int i, char* buffer, size_t buffersize )
  {
    return idGetSubName((size_t)enumtype, "parameter", i, buffer, buffersize);;
  }

#if LUAFXBUILDER_USESTRING

  inline std::string System::idGetSubName( size_t id, const char* what, int i )
  {
    LuaState L = m_luaState;
    LuaStateObjOperation idop(L,id);
    lua_getfield(L,-1,what);
    lua_rawgeti (L,-1, i + 1);
    assert(lua_istable(L,-1));
    lua_getfield(L,-1,"name");

    size_t sz;
    const char* str = lua_tolstring(L,-1,&sz);

    return std::string(str,sz);
  }

  std::string System::techniqueGetCodeName( TechID tech, int i )
  {
    return idGetSubName((size_t)tech, "code", i );
  }

  std::string System::groupGetParameterName( GroupID group, int i )
  {
    return idGetSubName((size_t)group, "parameter", i );
  }

  std::string System::enumGetValueName( EnumID enumtype, int i )
  {
    return idGetSubName((size_t)enumtype, "content", i );
  }


#endif

  //////////////////////////////////////////////////////////////////////////
  

  EffectType System::effectGetType( EffectID effect )
  {
    LuaState L = m_luaState;
    LuaStateObjOperation idop(L,(size_t)effect);
    lua_getfield(L, -1, "classenum");
    assert( lua_isnumber(L,-1) );
    return (EffectType)lua_tointeger(L,-1);
  }

  //////////////////////////////////////////////////////////////////////////
  
  error System::techniqueGenerateCode( TechID tech, GeneratorType gentype, int i, char* buffer, size_t buffersize, size_t* outsize )
  {
    LuaState L = m_luaState;
    LuaStateObjOperation idop(L,(size_t)tech);
    lua_getglobal   (L,    "fxcodegen");
    lua_pushvalue   (L, -2);      // tech
    lua_pushinteger (L,i + 1);    // codeidx
    lua_pushinteger (L, gentype); // gentype
    if ( lua_pcall  (L,3,1,FXERROR) ){
      updateError();
      return true;
    }
    assert(lua_isstring(L,-1));

    size_t sz;
    const char* str = lua_tolstring(L,-1,&sz);
    sz = outputString(str,sz,buffer,buffersize);
    *outsize = sz;

    return false;
  }

#if LUAFXBUILDER_USESTRING
  error System::techniqueGenerateCode( TechID tech, GeneratorType gentype, int i, std::string& buffer )
  {
    LuaState L = m_luaState;
    LuaStateObjOperation idop(L,(size_t)tech);
    lua_getglobal   (L,    "fxcodegen");
    lua_pushvalue   (L, -2);      // tech
    lua_pushinteger (L,i + 1);    // codeidx
    lua_pushinteger (L, gentype); // gentype
    if ( lua_pcall  (L,3,1,FXERROR) ){
      updateError();
      return true;
    }
    assert(lua_isstring(L,-1));

    size_t sz;
    const char* str = lua_tolstring(L,-1,&sz);
    buffer = std::string(str,sz);

    return false;
  }
#endif

  bool System::techniqueHasLighting( TechID tech )
  {
    LuaState L = m_luaState;
    LuaStateObjOperation idop(L,(size_t)tech);
    lua_getfield(L, -1, "lighting");
    return lua_toboolean(L,-1) ? true : false;
  }

  bool System::techniqueHasOption( TechID tech, const char* name )
  {
    LuaState L = m_luaState;
    LuaStateObjOperation idop(L,(size_t)tech);
    lua_getfield(L,-1, "option");
    lua_getfield(L,-1, name);
    return lua_isnil(L,-1) ? false : true;
  }

  static inline void getOption(LuaState L, const char* name, int type){
    lua_getfield(L,-1, "option");
    lua_getfield(L,-1, name);
    assert(lua_type(L,-1) == type);
  }

  size_t System::techniqueGetOptionString( TechID tech, const char* name, char* buffer, size_t buffersize )
  {
    LuaState L = m_luaState;
    LuaStateObjOperation idop(L,(size_t)tech);
    getOption(L,name,LUA_TSTRING);

    size_t sz;
    const char* str = lua_tolstring(L,-1,&sz);
    sz = outputString(str,sz,buffer,buffersize);

    return sz;
  }

#if LUAFXBUILDER_USESTRING

  std::string System::techniqueGetOptionString( TechID tech, const char* name )
  {
    LuaState L = m_luaState;
    LuaStateObjOperation idop(L,(size_t)tech);
    getOption(L,name,LUA_TSTRING);

    size_t sz;
    const char* str = lua_tolstring(L,-1,&sz);

    return std::string(str,sz);
  }

#endif

  bool System::techniqueGetOptionBool( TechID tech, const char* name )
  {
    LuaState L = m_luaState;
    LuaStateObjOperation idop(L,(size_t)tech);
    getOption(L,name,LUA_TBOOLEAN);
    return lua_toboolean(L,-1) ? true : false;
  }

  int System::techniqueGetOptionInteger( TechID tech, const char* name )
  {
    LuaState L = m_luaState;
    LuaStateObjOperation idop(L,(size_t)tech);
    getOption(L,name,LUA_TNUMBER);
    return (int)lua_tointeger(L,-1);
  }

  float System::techniqueGetOptionFloat( TechID tech, const char* name )
  {
    LuaState L = m_luaState;
    LuaStateObjOperation idop(L,(size_t)tech);
    getOption(L,name,LUA_TNUMBER);
    return (float)lua_tonumber(L,-1);
  }

  //////////////////////////////////////////////////////////////////////////


  void System::groupGetParameterInfo( GroupID group, int i, ParameterInfo *info )
  {
    LuaState L = m_luaState;
    LuaStateObjOperation idop(L,(size_t)group);
    lua_getfield(L,-1,"parameter");
    lua_rawgeti (L,-1, i + 1);
    assert(!lua_isnil(L,-1));
    lua_getfield(L,-1, "arraysize");
    info->arraySize = (int)lua_tointeger(L,-1);
    lua_getfield(L,-2, "defaultcnt");
    info->defaultSize = (int)lua_tointeger(L,-1);
    lua_getfield(L,-3, "typeenum");
    info->type = (ParameterType)lua_tointeger(L,-1);
    lua_getfield(L,-4, "reference");
    info->reference  = lua_isnil(L,-1) ? 0 : getID();
    lua_getfield(L,-5, "defaultconv");
    int       convtype = (int)lua_tointeger(L,-1);
    assert(convtype >= 0 && convtype < NUM_DATACONVERTS);
    size_t    elemsize = dataConvertSize[convtype % NUM_DATACONVERTS];
    info->defaultSize *= elemsize;
  }

  size_t System::groupGetParameterValue( GroupID group, int i, size_t buffersize, void* buffer )
  {
    LuaState L = m_luaState;
    LuaStateObjOperation idop(L,(size_t)group);
    lua_getfield(L,-1,"parameter");
    lua_rawgeti (L,-1, i + 1);
    assert(!lua_isnil(L,-1));
    lua_getfield(L,-1, "defaultcnt");
    int       elements = (int)lua_tointeger(L,-1);
    lua_getfield(L,-2, "defaultconv");
    DataConvert conv   = (DataConvert)lua_tointeger(L,-1);
    lua_getfield(L,-3, "defaultvalue");
    assert(conv >= 0 && conv < NUM_DATACONVERTS);
    size_t    elemsize = dataConvertSize[conv];
    size_t writtensize = elemsize*elements;
    assert(buffersize >= writtensize);

    switch (conv)
    {
    case DATACONVERT_FLOAT:
      {
        float* data = (float*)buffer;
        for (int i = 0; i < elements; i++) {
          lua_rawgeti(L, -1, i + 1);
          data[i] = (float)lua_tonumber(L,-1);
          lua_pop(L,1);
        }
        return writtensize;
      }
    case DATACONVERT_DOUBLE:
      {
        double* data = (double*)buffer;
        for (int i = 0; i < elements; i++) {
          lua_rawgeti(L, -1, i + 1);
          data[i] = (double)lua_tonumber(L,-1);
          lua_pop(L,1);
        }
        return writtensize;
      }
    case DATACONVERT_INTEGER:
      {
        int* data = (int*)buffer;
        size_t writtensize = elemsize*elements;
        assert(buffersize >= writtensize);
        for (int i = 0; i < elements; i++) {
          lua_rawgeti(L, -1, i + 1);
          data[i] = (int)lua_tointeger(L,-1);
          lua_pop(L,1);
        }
        return writtensize;
      }
    case DATACONVERT_BOOLEAN:
      {
        int* data = (int*)buffer;

        for (int i = 0; i < elements; i++) {
          lua_rawgeti(L, -1, i + 1);
          data[i] = lua_toboolean(L,-1);
          lua_pop(L,1);
        }
        return writtensize;
      }
    case DATACONVERT_STRING:
      {
        lua_rawgeti(L, -1, 1);
        size_t sz;
        memcpy(buffer,lua_tolstring(L,-1,&sz),writtensize);
        assert(sz == writtensize);
        return writtensize;
      }
    }

    return 0;
  }

  StorageType System::groupGenerateStorage( GroupID group, GeneratorType gentype, int bufferelements, ParameterStorage* buffer )
  {
    LuaState L = m_luaState;
    LuaStateObjOperation idop(L,(size_t)group);
    lua_getglobal   (L,    "fxgroupstore");
    lua_pushvalue   (L,-2);
    lua_pushinteger (L, gentype);
    if ( lua_pcall  (L,2,3,FXERROR) ){
      updateError();
      assert(0 && "storage computation failed");
      return STORAGE_NONE;
    }
    if (!(lua_isnumber(L,-3) &&
          lua_isnumber(L,-2) &&
          lua_istable (L,-1))){
      return STORAGE_NONE;
    }
    int elements = (int)lua_tointeger(L,-2);
    for (int i = 0; i < elements && i < bufferelements; i++){
      lua_rawgeti (L, -1, i + 1);

      lua_getfield(L, -1, "size");
      assert(lua_isnumber(L,-1));
      buffer[i].size    = lua_tointeger(L,-1);

      lua_getfield(L, -2, "offset");
      assert(lua_isnumber(L,-1));
      buffer[i].offset = lua_tointeger(L,-1);

      lua_getfield(L, -3, "stride");
      assert(lua_isnumber(L,-1));
      buffer[i].stride = lua_tointeger(L,-1);

      lua_getfield(L, -4, "element");
      assert(lua_isnumber(L,-1));
      buffer[i].element = lua_tointeger(L,-1);

      lua_getfield(L, -5, "align");
      assert(lua_isnumber(L,-1));
      buffer[i].align = lua_tointeger(L,-1);

      lua_pop(L,6);
    }

    return (StorageType)lua_tointeger(L,-3);
  }

  size_t System::groupGenerateStorageName( GroupID group, GeneratorType gentype, char* buffer, size_t buffersize )
  {
    LuaState L = m_luaState;
    LuaStateObjOperation idop(L,(size_t)group);
    lua_getglobal   (L,    "fxgroupstorename");
    lua_pushvalue   (L,-2);
    lua_pushinteger (L, gentype);
    if ( lua_pcall  (L,2,1,FXERROR) ){
      assert(0 && "storage computation failed");
      updateError();
      return 0;
    }
    if (!lua_isstring(L,-1)){
        return 0;
    }
    size_t sz;
    const char* str = lua_tolstring(L,-1,&sz);
    return outputString(str,sz,buffer,buffersize);
  }

#if LUAFXBUILDER_USESTRING
  std::string System::groupGenerateStorageName( GroupID group, GeneratorType gentype )
  {
    LuaState L = m_luaState;
    LuaStateObjOperation idop(L,(size_t)group);
    lua_getglobal   (L, "fxgroupstorename");
    lua_pushvalue   (L,-2);
    lua_pushinteger (L, gentype);
    if ( lua_pcall  (L,2,1,FXERROR) ){
      assert(0 && "storage computation failed");
      updateError();
      return 0;
    }
    if (!lua_isstring(L,-1)){
      return 0;
    }
    size_t sz;
    const char* str = lua_tolstring(L,-1,&sz);

    return std::string(str,sz);
  }
#endif

  GroupType System::groupGetType( GroupID group )
  {
    LuaState L = m_luaState;
    LuaStateObjOperation idop(L,(size_t)group);
    lua_getfield(L,-1,"modetype");
    return  ((GroupType) lua_tointeger(L,-1));
  }


  error System::setGeneratorLights( int numLights, EffectID* lights, int* lightsMax  )
  {
    for (int i = 0; i < numLights; i++){
      if (  effectGetType(lights[i]) != EFFECT_LIGHT ){
        assert(0 && "illegal effectid, lights required");
        return false;
      }
    }
    
    LuaState L = m_luaState;
    lua_newtable(L); // 1 effects {}
    lua_newtable(L); // 2 max     {}
    for (int i = 0; i < numLights; i++){
      LuaStateObjOperation idop(L,(size_t)lights[i]);
                                            // 3 effect
      lua_rawseti     (L,-3,i+1);           // 2  fxlights.effects[i] = effect
      lua_pushinteger (L,  lightsMax[i]);   // 3 max
      lua_rawseti     (L,-2,i+1);           // 2  fxlights.max[i] = max
    }
    lua_setfield  (L,FXLIGHTS,"max");       // 1  fxlights.max = 2
    lua_setfield  (L,FXLIGHTS,"effects");   // 0  fxlights.effects = 1

    return false;
  }

  int System::getEnumCount()
  {
    LuaState L = m_luaState;
    LuaStatePreserve preserve(L);
    lua_getfield(L,FXUSERENUMS,"count");
    assert( lua_isnumber(L,-1) );
    return (int)lua_tointeger(L,-1);
  }

  EnumID System::getEnum( const char* name )
  {
    LuaState L = m_luaState;
    LuaStatePreserve preserve(L);
    lua_getfield(L,FXUSERENUMS,"enums");
    lua_getfield(L,-1,name);

    if (!lua_istable(L,-1)){
      return 0;
    }

    EnumID id = (EnumID)getID();

    return id;
  }

  EnumID System::getEnum( int i )
  {
    LuaState L = m_luaState;
    LuaStatePreserve preserve(L);
    lua_getfield(L,FXUSERENUMS,"enums");
    lua_rawgeti(L,-1,i+1);

    if (!lua_istable(L,-1)){
      return 0;
    }

    LuaStateCheck(L);

    EnumID id = (EnumID)getID();

    return id;
  }

  EnumID System::getEnumFromValueName( const char* name )
  {
    LuaState L = m_luaState;
    LuaStatePreserve preserve(L);
    lua_getfield(L,FXUSERENUMS,"values");
    lua_getfield(L,-1,name);

    if (!lua_istable(L,-1)){
      return 0;
    }
    
    lua_getfield(L,-1,"enum");

    EnumID id = (EnumID)getID();

    return id;
  }

  int System::enumGetValueCount( EnumID enumtype )
  {
    LuaState L = m_luaState;
    LuaStateObjOperation op(L,(size_t)enumtype);
    lua_getfield(L,-1,"count");
    assert( lua_isnumber (L,-1) );
    return  (int)lua_tointeger(L,-1);
  }

  int System::enumGetValueIndex( EnumID enumtype, const char* valuename )
  {
    LuaState L = m_luaState;
    LuaStateObjOperation op(L,(size_t)enumtype);
    lua_getfield(L,-1,"content");
    lua_getfield(L,-1, valuename);
    if (lua_isnil(L,-1)){
      return -1;
    }
    lua_getfield(L,-1,"idx");
    return (int)lua_tointeger(L,-1)-1;
  }

  int System::enumGetValue( EnumID enumtype, int i )
  {
    LuaState L = m_luaState;
    LuaStateObjOperation op(L,(size_t)enumtype);
    lua_getfield(L,-1,"content");
    lua_rawgeti (L,-1, i+1);
    assert (lua_istable(L,-1));
    lua_getfield(L,-1,"value");
    assert (lua_isnumber(L,-1));
    return (int)lua_tointeger(L,-1);
  }

}



