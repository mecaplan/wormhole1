precision highp float;

@import ./common;

uniform vec3 uCameraPosition;

uniform float uRadiusSquared;
uniform float uThroatLength;

uniform sampler2D uIntegrationBuffer;
uniform samplerCube uSkybox1;
uniform samplerCube uSkybox2;

uniform vec2 uAngleRange;

varying vec3 vRayDir;

struct State3D {
  vec3 position;
  vec3 direction;
  float distance;
};

/**
 *  Util
 */

void sphericalToCartesian(vec2 position, vec2 direction, out vec3 outPos, out vec3 outDir) {
  float sinY = sin(position.y),
        cosY = cos(position.y),
        sinX = sin(position.x),
        cosX = cos(position.x);

  outPos = vec3(sinY * cosX, -cosY, sinY * sinX);
  outDir = vec3(
    -sinY * sinX * direction.x + cosY * cosX * direction.y,
     sinY * direction.y,
     sinY * cosX * direction.x + cosY * sinX * direction.y
  );
}

// Integrate!
void integrate3D(inout State3D ray, out vec3 cubeCoord) {
  // We integrate in a 2D plane so we don't have to deal with the poles of spherical coordinates, where
  // integration might go out of hand.

  // Determine the X- and Y-axes in this plane
  vec3 pos3D, dir3D, axisX, axisY, axisZ;
  sphericalToCartesian(ray.position.zy, ray.direction.zy, pos3D, dir3D);

  axisX = normalize(pos3D);
  axisZ = cross(axisX, normalize(dir3D));
  axisY = cross(axisZ, axisX);

  float theta = acos(ray.direction.x);
  float x = (theta - uAngleRange.x) / (uAngleRange.y - uAngleRange.x);
  vec4 finalIntegrationState = texture2D(uIntegrationBuffer, vec2(x, 0.5));

  #if !RENDER_TO_FLOAT_TEXTURE
    finalIntegrationState.xy = finalIntegrationState.xy * 2.0 - 1.0;
    finalIntegrationState.z -= 0.5;
    finalIntegrationState.w *= 1000.0;
  #endif

  // Compute the end-direction in cartesian space
  cubeCoord = axisX * finalIntegrationState.x + axisY * finalIntegrationState.y;

  // Transform the 2D position and direction back into 3D
  // Though only position.x is used, we don't transform the other ray attributes
  ray.position.x = finalIntegrationState.z;
  ray.distance = finalIntegrationState.w;
}

// Transform a direction given in flat spacetime coordinates to one of the same angle
// in wormhole spacetime coordinates.
void adjustDirection(inout State3D ray) {
  float distanceToWormhole = max(0.0, abs(ray.position.x) - uThroatLength);

  float r = sqrt(distanceToWormhole * distanceToWormhole + uRadiusSquared);
  ray.direction.y /= r;
  ray.direction.z /= r * sin(ray.position.y);
}

// Get the final color given a position and direction.
vec4 getColor(State3D ray, vec3 cubeCoord) {
  vec3 skybox1Color = textureCube(uSkybox1, cubeCoord).rgb;
  vec3 skybox2Color = textureCube(uSkybox2, cubeCoord).rgb;

  float merge = 0.5 - clamp(ray.position.x, -0.5, 0.5);
  vec3 color = mix(skybox1Color, skybox2Color, merge);

  // Prettify the thing where everything becomes infinite
  const float cutoffStart = 150.0;
  const float cutoffEnd = 800.0;

  float blackFade = clamp((ray.distance - cutoffStart) / (cutoffEnd - cutoffStart), 0.0, 1.0);

  return vec4(mix(color, vec3(0.0), blackFade), 1.0);
}

void main()
{
  State3D ray;
  ray.position = uCameraPosition;
  ray.direction = normalize(vRayDir);

  adjustDirection(ray);

  vec3 cubeCoord;

  // Integrate in wormhole space coordinates
  integrate3D(ray, cubeCoord);

  gl_FragColor = getColor(ray, cubeCoord);
}
