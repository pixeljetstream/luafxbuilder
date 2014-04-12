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

#include <luafxbuilder/luafxbuilder.h>


using namespace luafxbuilder;



void printGroup(System &effectlib, GroupID group)
{
  printf("  Group: %s\n", effectlib.groupGetName(group).c_str());
  int pcnt       = effectlib.groupGetParameterCount(group);
  for (int p = 0; p < pcnt; p++){
    ParameterInfo info;
    effectlib.groupGetParameterInfo(group,p,&info);
    printf("   Parameter: %s %s %d %d\n", effectlib.groupGetParameterName(group,p).c_str(),
        ParameterType_toString(info.type), (int)info.arraySize, (int)info.defaultSize);
  }
}

void printTechique(System &effectlib, TechID tech)
{
  printf("  Tech: %s\n", effectlib.techniqueGetName(tech).c_str());
  int cnt = effectlib.techniqueGetCodeCount(tech);
  for (int i = 0; i < cnt; i++){
    printf("   Code: %s\n", effectlib.techniqueGetCodeName(tech,i).c_str());
    for (int g = 0; g < NUM_GENERERATORS; g++){
      GeneratorType gtype = (GeneratorType)g;
      printf("    Generator: %s\n",GeneratorType_toString(gtype));
      std::string codegen;
      
      if (effectlib.techniqueGenerateCode(tech,gtype,i,codegen)){
        printf("ERROR: %s\n", effectlib.getLastErrorString().c_str());
      }
      else{
        printf("%s\n",codegen.c_str());
      }
    }
  }
}

void printEffect(System &effectlib, EffectID effect)
{
  int gcnt         = effectlib.effectGetGroupCount(effect);
  for ( int g = 0; g < gcnt; g++){
    GroupID  group = effectlib.effectGetGroup(effect,g);
    printGroup(effectlib, group);
  }

  int tcnt         = effectlib.effectGetTechniqueCount(effect);
  for ( int t = 0; t < tcnt; t++){
    TechID  tech = effectlib.effectGetTechnique(effect,t);
    printTechique(effectlib, tech);
  }
}

void testLib(System &effectlib)
{
  const char* inmemory = ""
    "Global 'test' {\n"
    "  Code 'wrongscope' {\n"
    "  }\n"
    "}\n";

  if (effectlib.addLibraryString(inmemory,strlen(inmemory)))
  {
    std::string error = effectlib.getLastErrorString();
    printf("expected error:%s\n",error.c_str());
  }

  if (1){
    printf("ITERATE ALL\n");
    printf("-----------\n");
    for (int t = 0; t < NUM_EFFECTS; t++){
      printf("EffectType: %s\n",EffectType_toString((EffectType)t));
      int ecnt = effectlib.getEffectCount((EffectType)t);
      for (int e = 0; e < ecnt; e++){
        EffectID effect  = effectlib.getEffect((EffectType)t,e);
        printEffect(effectlib,effect);
      }
    }
  }
}

int main(int argc, char **argv)
{

  System effectLib;

  if (effectLib.init("../lua/fxlibprocessor.lua"))
  {
    std::string error = effectLib.getLastErrorString();
    printf("error:%s\n",error.c_str());
    return EXIT_FAILURE;
  }

  if (effectLib.addLibraryFile("../test/testfx.luafx"))
  {
    std::string error = effectLib.getLastErrorString();
    printf("error:%s\n",error.c_str());
    return EXIT_FAILURE;
  }

  testLib(effectLib);

  return EXIT_SUCCESS;
}

