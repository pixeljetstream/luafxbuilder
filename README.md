````
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

````

## What is luafxbuilder?

* luafxbuilder is a proof of concept test to use __lua as effect file format for managing real-time shaders__, without making it too obvious that the file is
in fact lua code. This would save the cost of creating a specialized parser and one would get many features from a
programming language for free (e.g. variable referencing, generating content...).

* Another goal was to organize parameters in groups and __generate the access code for how the parameters are stored__.
Currently multiple code generators for GLSL exist leveraging: classic uniforms, GL_ARB_uniform_buffer_object, GL_ARB_shader_storage_buffer_object and GL_NV_shader_buffer_load
(bindless pointers) as well as GL_ARB/NV_bindless_texture.
  * Some of the parameter generators were designed to used indexed parameter reads, because passing the storage index
of a parameter group can be done fast between drawcalls and allows leveraging GL_ARB_multi_draw_indirect.

  * These techniques are useful to overcome CPU-boundedness when rendering ten thousands of objects with different parameter sets.
However such indexing also comes with a certain cost for the GPU, hence this project allows to __switch between different kinds 
of storage without having to rewrite the shaders__ manually.


* Furthermore different light types are supported and a special "macro" is used within the GLSL code to handle the
iteration over different light types in forward rendering.

* __The file format itself is language agnostic__ and could manage any other shading language, mostly the code
generators would have to be modified for this.

-----------------------------------------------------------------
## What is it not?
* It is not managing any native graphics resources (GLSL shaders, programs...), but providing strings and high-level
information. Managing shader and parameter changes is best done within a renderer to avoid the overhead that most
effect frameworks (setting/cleaning state...) bring with them.
* not supporting multi-pass effects (shader A, change blend state, render with shader B), given todays hw capabilities.
* not feature-complete in terms of OpenGL's parameter set
* not production code, the library is not thread-safe as accessing the LuaState isn't and it's not a drop-in solution, it requires customization to the renderer.

-----------------------------------------------------------------
## How does it look like
* The main effect classes are
  * __Global__ : mostly to make data globally available to all effects
  * __Geometry__ : takes care of the object's transformation, displacement... (vertex, tesselation, geometry-shaders)
  * __Light__ : allows definition of different light types
  * __Material__ : defines how the surface is shaded (fragment/pixel shaders).
    * Assumes certain inputs (e.g. position, normal...) from the Geometry stage, which should be defined as GeometryTechnique option.

* Each effect can contain
  * __Group__ : parameters are stored in groups. They can be
    * "instanced", meaning they change frequently during rendering (e.g. object or material parameters)
    * "shared", not as frequent changes (e.g. view parameters)
  * __GobalGroup__ : a reference to a Group stored in a Global effect
  * __Technique__ : allows to implement various approaches under the same effect (could be HLSL/GLSL...)
    * __Options__ : the user can define any options they want, they can later be queried.
    * __Code__ : the actual program code definition is made of multiple commands, that are passed to the source code generator
      * _HEADER_ : it's up to the generator to interpret this
      * _LIGHTS_ : what kind of light sources should be available to the code
      * _STRING_ : program code provided as inlined string
      * _FILE_ : the content of the referenced file
      * _PARAMETERHINTS_ : can contain special type qualifiers (e.g. "layout(r32ui) coherent") for certain parameters

![Example](https://github.com/pixeljetstream/luafxbuilder/raw/master/misc/luafx_example.png)

-----------------------------------------------------------------
## File organization
* __include/src__ is the C++ wrapper of the effect library and code generator, so that it can be used within a C++ project
* __lua__ contains the core logic of the effect library and the code generators
* __test__ rudimentary tests on the lua or C++ part
* __misc__ currently a syntax highlighter file for the [Estrela Editor](http://www.luxinia.de/index.php/Estrela) / [ZeroBrane Studio](http://studio.zerobrane.com/) IDE is provided

-----------------------------------------------------------------
## Building luafxbuilder
* Lua 5.1 compatible lua library is required
* Currently only Visual Studio 2008 build files are provided, however the code is supposed to be platform-independent and
is only a single C++ file meant to be statically linked.
  * The visual studio solution assumes LUA_INCLUDE, LUA_LIB_X64 and LUA_LIB_X86 environment variables set to the appropriate paths.
  * Copy the lua51.dll to the binary output directoy if you intend to run the luafxbuildertest.exe
  
-----------------------------------------------------------------
## Possible future
* The intention is to further remove "specialization" (Material..) and make the core system always generic, so it can be used for particle system, compositing... and similar systems
* Generating the actual asset code based on a tree representation as seen in node-based shader/particle editors. The nodes would be defined via Lua and custom code snippets.

However, the project is currently not actively maintained, so there is no target dates for the availability of such features.

-----------------------------------------------------------------

Feel free to direct questions to ckubisch@nvidia.com (Christoph Kubisch)


