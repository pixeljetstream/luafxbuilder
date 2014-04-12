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

#ifndef LUAFXBUILDER_H_
#define LUAFXBUILDER_H_


#ifndef LUAFXBUILDER_USESTRING
#define LUAFXBUILDER_USESTRING 1
#endif

#if LUAFXBUILDER_USESTRING
#include <string>
#endif

extern "C" {
  typedef struct lua_State* LuaState;
};


namespace luafxbuilder
{

  enum EffectType {
    EFFECT_GLOBAL,
    EFFECT_GEOMETRY,
    EFFECT_LIGHT,
    EFFECT_MATERIAL,
    NUM_EFFECTS,
  };

  enum ParameterType {
    PARAMETER_NONE,
    PARAMETER_BOOL,
    PARAMETER_BVEC2,
    PARAMETER_BVEC3,
    PARAMETER_BVEC4,
    PARAMETER_INT,
    PARAMETER_IVEC2,
    PARAMETER_IVEC3,
    PARAMETER_IVEC4,
    PARAMETER_UINT,
    PARAMETER_UVEC2,
    PARAMETER_UVEC3,
    PARAMETER_UVEC4,
    PARAMETER_FLOAT,
    PARAMETER_VEC2,
    PARAMETER_VEC3,
    PARAMETER_VEC4,
    PARAMETER_MAT2X2,
    PARAMETER_MAT2X3,
    PARAMETER_MAT2X4,
    PARAMETER_MAT3X2,
    PARAMETER_MAT3X3,
    PARAMETER_MAT3X4,
    PARAMETER_MAT4X2,
    PARAMETER_MAT4X3,
    PARAMETER_MAT4X4,
    PARAMETER_SAMPLER_1D,
    PARAMETER_SAMPLER_2D,
    PARAMETER_SAMPLER_2DRECT,
    PARAMETER_SAMPLER_3D,
    PARAMETER_SAMPLER_CUBE,
    PARAMETER_SAMPLER_1D_ARRAY,
    PARAMETER_SAMPLER_2D_ARRAY,
    PARAMETER_SAMPLER_CUBE_ARRAY,
    PARAMETER_SAMPLER_2DMS,
    PARAMETER_SAMPLER_2DMS_ARRAY,
    PARAMETER_SAMPLER_BUFFER,
    PARAMETER_IMAGE_1D,
    PARAMETER_IMAGE_2D,
    PARAMETER_IMAGE_2DRECT,
    PARAMETER_IMAGE_3D,
    PARAMETER_IMAGE_CUBE,
    PARAMETER_IMAGE_1D_ARRAY,
    PARAMETER_IMAGE_2D_ARRAY,
    PARAMETER_IMAGE_CUBE_ARRAY,
    PARAMETER_IMAGE_2DMS,
    PARAMETER_IMAGE_2DMS_ARRAY,
    PARAMETER_IMAGE_BUFFER,
    //PARAMETER_ATOMIC_BUFFER,  // disabled for now
    PARAMETER_ENUM,             // uniform int var;         -> integer conversion
    NUM_PARAMETERS,
  };

  enum GroupType {
    GROUP_SHARED,
    GROUP_INSTANCED,
    NUM_GROUPS,
  };

  enum StorageType {
    STORAGE_NONE,
    STORAGE_UNIFORM,
    STORAGE_UNIFORMBUFFER,
    STORAGE_UNIFORMBUFFER_INDEXED,
    STORAGE_STORAGEBUFFER_INDEXED,
    STORAGE_NVLOADBUFFER,
    STORAGE_NVLOADBUFFER_INDEXED,
    NUM_STORAGES,
  };

  enum GeneratorType {
    GENERATOR_GLSL_UNIFORM,
    GENERATOR_GLSL_UBO,
    GENERATOR_GLSL_NVLOAD,
    GENERATOR_GLSL_NVLOADTEX,
    GENERATOR_GLSL_UBOSSBOTEX,
    NUM_GENERERATORS,
  };

  //typedef int GeneratorType;
  //typedef int StorageType;

  const char* EffectType_toString(EffectType type);
  const char* ParameterType_toString(ParameterType type);
  const char* GeneratorType_toString(GeneratorType type);

  typedef struct Effect_*   EffectID;
  typedef struct Group_*    GroupID;
  typedef struct Tech_*     TechID;
  typedef struct Enum_*     EnumID;
  typedef bool              error;

  struct ParameterStorage {
    size_t  size;           // size within struct
    size_t  offset;         // offset into struct
    size_t  stride;         // stride for array elements, e.g in std140, float array[2] is actually stored as vec4 array[2];
    size_t  element;        // single element size, cant use memcpy if element != stride
    size_t  align;
  };

  struct ParameterInfo {
    ParameterType   type;
    int             arraySize;
    size_t          defaultSize;
    union {
      size_t        reference;
      GroupID       pointerGroup;
      EnumID        enumDef;
    };
  };

  class System {
  private:
    LuaState      m_luaState;
    char*         m_lastError;
    size_t        m_lastErrorSize;

  public:
    size_t        getLastErrorString(char* buffer, size_t buffersize);
#if LUAFXBUILDER_USESTRING
    std::string   getLastErrorString();
#endif
    error         init(const char* processorFile);
    void          deinit();

    error         addLibraryFile    (const char* filename); // returns true on error
    error         addLibraryString  (const char* buffer, size_t buffersize);  // returns true on error

    //error       registerGenerator   (GeneratorType type, const char* filename, const char* name );
    //error       registerStorageType (StorageType type, const char* name);

    int           getEnumCount();
    EnumID        getEnum     (const char*  name);
    EnumID        getEnum     (int i);
    EnumID        getEnumFromValueName(const char*  name);

    size_t        enumGetName       (EnumID enumtype, char* buffer, size_t buffersize);
    size_t        enumGetValueName  (EnumID enumtype, int i, char* buffer, size_t buffersize);
#if LUAFXBUILDER_USESTRING
    std::string   enumGetName       (EnumID enumtype);
    std::string   enumGetValueName  (EnumID enumtype, int i);
#endif
    int           enumGetValueCount (EnumID enumtype);
    int           enumGetValueIndex (EnumID enumtype, const char* valuename);
    int           enumGetValue      (EnumID enumtype, int i);

    int           getEffectCount  (EffectType effecttype);
    EffectID      getEffect       (EffectType effecttype, int i);
    EffectID      getEffect       (EffectType effecttype, const char* name);

    EffectType    effectGetType      (EffectID effect);
    size_t        effectGetName      (EffectID effect, char* buffer, size_t buffersize);
#if LUAFXBUILDER_USESTRING
    std::string   effectGetName      (EffectID effect);
#endif

    int           effectGetGroupCount     (EffectID effect);
    GroupID       effectGetGroup          (EffectID effect, int i);
    GroupID       effectGetGroup          (EffectID effect, const char* name);
    int           effectGetGroupIndex     (EffectID effect, const char* name);

    int           effectGetTechniqueCount (EffectID effect);
    TechID        effectGetTechnique      (EffectID effect, int i);
    TechID        effectGetTechnique      (EffectID effect, const char* name);
    int           effectGetTechniqueIndex (EffectID effect, const char* name);

    size_t        groupGetName            (GroupID group, char* buffer, size_t buffersize);
#if LUAFXBUILDER_USESTRING
    std::string   groupGetName            (GroupID group);
#endif
    GroupType     groupGetType            (GroupID group);
    EffectID      groupGetEffect          (GroupID group);
    int           groupGetParameterIndex  (GroupID group, const char* name);
    int           groupGetParameterCount  (GroupID group);
    size_t        groupGetParameterName   (GroupID group, int i, char* buffer, size_t buffersize);
#if LUAFXBUILDER_USESTRING
    std::string   groupGetParameterName   (GroupID group, int i);
#endif
    void          groupGetParameterInfo   (GroupID group, int i, ParameterInfo *info);
    size_t        groupGetParameterValue  (GroupID group, int i, size_t buffersize, void* buffer);

    size_t        techniqueGetName          (TechID tech, char* buffer, size_t buffersize);
#if LUAFXBUILDER_USESTRING
    std::string   techniqueGetName          (TechID tech);
#endif
    EffectID      techniqueGetEffect        (TechID tech);
    bool          techniqueHasLighting      (TechID tech);
    bool          techniqueHasOption        (TechID tech, const char* name);
    size_t        techniqueGetOptionString  (TechID tech, const char* name, char* buffer, size_t buffersize);
#if LUAFXBUILDER_USESTRING
    std::string   techniqueGetOptionString  (TechID tech, const char* name);
#endif
    bool          techniqueGetOptionBool    (TechID tech, const char* name);
    int           techniqueGetOptionInteger (TechID tech, const char* name);
    float         techniqueGetOptionFloat   (TechID tech, const char* name);
    int           techniqueGetCodeCount     (TechID tech);
    int           techniqueGetCodeIndex     (TechID tech, const char* name);
    size_t        techniqueGetCodeName      (TechID tech, int codeidx, char* buffer, size_t buffersize);
#if LUAFXBUILDER_USESTRING
    std::string   techniqueGetCodeName      (TechID tech, int codeidx);
#endif
    // code generation related
    //////////////////////////
    error         setGeneratorLights        (int numLights, EffectID* lights, int *lightsMax);

      // returns true on error
    error         techniqueGenerateCode (TechID tech, GeneratorType gentype, int codeidx, char* buffer, size_t buffersize, size_t* outsize); 
#if LUAFXBUILDER_USESTRING                             
    error         techniqueGenerateCode (TechID tech, GeneratorType gentype, int codeidx, std::string& buffer); 
#endif
    // must hold parameters+1 storage entries, last is for entire struct
    StorageType   groupGenerateStorage    (GroupID group, GeneratorType gentype, int bufferelements, ParameterStorage* buffer);
    size_t        groupGenerateStorageName(GroupID group, GeneratorType gentype, char* buffer, size_t buffersize);
#if LUAFXBUILDER_USESTRING
    std::string   groupGenerateStorageName(GroupID group, GeneratorType gentyp);
#endif

  private:
    bool        addLibrary(const char* funcname, const char* buffer, size_t buffersize);
    void        updateError();

    size_t      getID();
    int         idGetCount  (size_t id, const char* what);
    size_t      idGetName   (size_t id, char* buffer, size_t buffersize);
#if LUAFXBUILDER_USESTRING
    std::string idGetName   (size_t id);
#endif
    void        idSetUser   (size_t id, void* user);
    bool        idGetUser   (size_t id, void** user);
    size_t      idGetSubID  (size_t id, const char* what);
    size_t      idGetSubID  (size_t id, const char* what, int i);
    size_t      idGetSubID  (size_t id, const char* what, const char *name);
    int         idGetSubIdx (size_t id, const char* what, const char *name);
    size_t      idGetSubName(size_t id, const char* what, int i, char* buffer, size_t buffersize );
#if LUAFXBUILDER_USESTRING
    std::string idGetSubName(size_t id, const char* what, int i);
#endif
  };
}

#endif


