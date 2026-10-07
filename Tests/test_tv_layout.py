from pathlib import Path
import subprocess,tempfile
s=(Path(__file__).resolve().parents[1]/'Selene/ViewControllers/TVStreamExperience.swift').read_text()
core=s.split('// Pure geometry')[1].split('// End pure geometry.')[0]
core=core[core.index('struct TVStreamGeometry'):]
checks='''
let c = CGSize(width:1920,height:1080), v = CGSize(width:3840,height:1080)
let fit = TVStreamGeometry.frame(container:c,video:v,stretch:false,alignment:4,x:0,y:0)
assert(fit == CGRect(x:0,y:270,width:1920,height:540))
assert(TVStreamGeometry.inverse(point:CGPoint(x:50,y:50),frame:fit,video:v,container:c) == nil)
assert(TVStreamGeometry.inverse(point:CGPoint(x:960,y:540),frame:fit,video:v,container:c) == CGPoint(x:1920,y:540))
let stretch = TVStreamGeometry.frame(container:c,video:v,stretch:true,alignment:4,x:0,y:0)
assert(stretch == CGRect(origin:.zero,size:c))
assert(TVStreamGeometry.inverse(point:CGPoint(x:480,y:270),frame:stretch,video:v,container:c) == CGPoint(x:960,y:270))
for anchor in 0..<9 {
 let f = TVStreamGeometry.frame(container:c,video:CGSize(width:1080,height:1080),stretch:false,alignment:anchor,x:0,y:0)
 assert(f.minX == CGFloat(anchor%3)*420)
}
let offset = TVStreamGeometry.frame(container:c,video:v,stretch:true,alignment:4,x:100,y:-100)
assert(offset.origin == CGPoint(x:960,y:-540))
assert(TVStreamGeometry.frame(container:.zero,video:v,stretch:false,alignment:4,x:0,y:0) == .zero)
print("PASS: wide black bars, stretched separate axes, nine anchors, clipped offsets, inverse coordinates and invalid dimensions")
'''
with tempfile.TemporaryDirectory() as d:
 p=Path(d)/'layout.swift';p.write_text('import Foundation\nimport CoreGraphics\n'+core+checks)
 subprocess.run(['/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift',str(p)],check=True)
