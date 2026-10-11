"""Exercise production calibration rejection, overlay placement and diagnostic privacy."""
from pathlib import Path
import subprocess,tempfile
s=(Path(__file__).resolve().parents[1]/'Selene/ViewControllers/TVStreamExperience.swift').read_text()
def extract(start,end):return start+s.split(start)[1].split(end)[0]
core=extract('struct TVCalibrationPolicy {','// End calibration policy.')+extract('struct TVOverlayGeometry {','// End overlay geometry.')+extract('struct TVDiagnosticDocument:Encodable {','// End diagnostic schema.')
program='import Foundation\nimport CoreGraphics\n'+core+r'''
let stable=Array(repeating:[0.05,-0.02],count:40)
let center=TVCalibrationPolicy.center(stable)!
assert(abs(center[0]-0.05)<1e-8 && abs(center[1]+0.02)<1e-8)
assert(TVCalibrationPolicy.center(Array(stable.prefix(19))) == nil)
for bad in [[0.3,0.0],[Double.nan,0],[Double.infinity,0],[0,0,0]] {assert(TVCalibrationPolicy.center(Array(repeating:bad,count:40)) == nil)}
var moved=stable;moved[0]=[-0.1,0.0];assert(TVCalibrationPolicy.center(moved) == nil)
for offset in [-0.2,0.0,0.2] {
 assert(TVCalibrationPolicy.corrected(offset,center:offset)==0)
 assert(TVCalibrationPolicy.corrected(1,center:offset)==1)
 assert(TVCalibrationPolicy.corrected(-1,center:offset)==(-1))
 for step in -100...100 {assert(abs(TVCalibrationPolicy.corrected(Double(step)/100,center:offset))<=1)}
}
assert(TVCalibrationPolicy.corrected(Double.nan,center:0)==0)
let bounds=CGRect(x:60,y:30,width:1800,height:1000)
for position in 0...4 {
 let frame=TVOverlayGeometry.frame(bounds:bounds,size:CGSize(width:300,height:150),position:position)
 assert(bounds.contains(frame))
 if position==1 || position==3 {assert(frame.minX==bounds.minX)}
 if position==2 || position==4 {assert(frame.maxX==bounds.maxX)}
 if position>=3 {assert(frame.maxY==bounds.maxY)} else {assert(frame.minY==bounds.minY)}
}
assert(TVOverlayGeometry.frame(bounds:bounds,size:CGSize(width:5000,height:4000),position:4)==bounds)
let privateValues=["address":10.10,"pairingKey":123.0,"networkDroppedFrames":42.0,"rttMS":12.0,"receivedFPS":59.94,"decodeMS":Double.nan,"audioChannels":-1.0,"width":Double.infinity]
let document=TVDiagnosticDocument(active:true,measurements:privateValues,codec:"personal-host-name",hdr:true)
assert(document.measurements.count==3 && document.codec=="Unknown")
let text=try document.text();assert(text.count<2200)
for secret in ["address","pairingKey","personal-host-name","NaN"] {assert(!text.contains(secret))}
let inactive=TVDiagnosticDocument(active:false,measurements:privateValues,codec:"HEVC",hdr:true)
assert(inactive.measurements.isEmpty && inactive.codec=="Unknown" && inactive.hdr=="NotStarted")
assert(TVDiagnosticDocument(active:true,measurements:[:],codec:"HEVC",hdr:nil).codec=="HEVC")
assert(TVDiagnosticDocument(active:true,measurements:[:],codec:"HEVC Main 10 HDR",hdr:true).codec=="HEVC Main 10 HDR")
print("PASS: stable calibration, movement/disconnect-data rejection, range remap, five safe placements, diagnostic allowlist and inactive privacy")
'''
with tempfile.TemporaryDirectory() as directory:
 p=Path(directory)/'features.swift';p.write_text(program)
 subprocess.run(['/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift',str(p)],check=True)
