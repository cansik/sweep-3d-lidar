uniform mat4 projection;
uniform mat4 modelview;

attribute vec4 position;
attribute vec4 color;
attribute vec2 offset;

varying vec4 vertColor;

uniform float cloudScale;
uniform vec4 pointColor;

uniform vec2 res;

void main() {
	vec3 luminanceVector = vec3(0.2125, 0.7154, 0.0721);

	vec4 pt = position;

	// lerp z by luminance
	pt /= cloudScale;

	// calculate luminance
	float luminance = dot(luminanceVector, color.xyz);
	vec4 c = vec4(pointColor.xyz, luminance);

	// apply view matrix
	vec4 pos = modelview * pt;
	vec4 clip = projection * pos;
	vec4 clipped = clip + projection * vec4(offset, 0, 0);

	gl_Position = clipped;
	vertColor = c;
}