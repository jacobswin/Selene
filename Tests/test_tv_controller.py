"""Test the radial mapping used in the production controller sender."""
from pathlib import Path
import subprocess, tempfile
s=(Path(__file__).resolve().parents[1]/'Selene/Input/ControllerSupport.m').read_text()
function='static void SeleneTVRadialDeadzone'+s.split('static void SeleneTVRadialDeadzone')[1].split('static const double MOUSE_SPEED_DIVISOR')[0]
program='#include <math.h>\n#include <assert.h>\n#include <stdio.h>\n'+function+'\nint main(void) {\n float x=.1f,y=.2f; SeleneTVRadialDeadzone(&x,&y,0);assert(x==.1f && y==.2f);\n x=.05f;y=.05f;SeleneTVRadialDeadzone(&x,&y,10);assert(x==0 && y==0);\n x=.1f;y=0;SeleneTVRadialDeadzone(&x,&y,10);assert(x==0 && y==0);\n x=.55f;y=0;SeleneTVRadialDeadzone(&x,&y,10);assert(fabsf(x-.5f)<.0001f && y==0);\n x=.70710678f;y=.70710678f;SeleneTVRadialDeadzone(&x,&y,30);assert(fabsf(hypotf(x,y)-1)<.0001f && fabsf(x-y)<.0001f);\n x=-1;y=0;SeleneTVRadialDeadzone(&x,&y,30);assert(x==-1 && y==0);\n x=NAN;y=0;SeleneTVRadialDeadzone(&x,&y,10);assert(x==0 && y==0);\n for(int d=1;d<=30;d++) for(int i=-100;i<=100;i++) {x=i/100.f;y=.3f;SeleneTVRadialDeadzone(&x,&y,d);assert(isfinite(x)&&isfinite(y)&&hypotf(x,y)<=1.0001f);}\n puts("PASS: zero compatibility, radial boundary, remaining-range remap, angle, clamps and invalid input");\n}\n'
with tempfile.TemporaryDirectory() as directory:
 p=Path(directory)/'controller.c';p.write_text(program);binary=Path(directory)/'controller'
 subprocess.run(['/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang',str(p),'-o',str(binary)],check=True)
 subprocess.run([str(binary)],check=True)
