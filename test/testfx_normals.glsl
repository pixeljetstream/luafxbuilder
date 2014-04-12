in Interpolants {
  vec3 varWorldPos;
  vec3 varWorldNormal;
  vec2 varUV;
};

layout(location = 0, index = 0) out vec4 outColor;

void main() {
  vec3 wNormal = normalize(varWorldNormal);
  if ( debugActive )
  {
    outColor = vec4(1,1,1,1);
  }
  else
  {
    outColor = vec4(wNormal*0.5 + 0.5,1);
  }
}
