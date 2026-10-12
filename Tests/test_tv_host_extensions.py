"""Exercise strict host scaling responses and bounded 48kHz/20ms microphone framing."""
from pathlib import Path
import subprocess,tempfile
root=Path(__file__).resolve().parents[1]
s=(root/'Selene/ViewControllers/TVStreamExperience.swift').read_text()
scale='struct TVDisplayScalePolicy {'+s.split('struct TVDisplayScalePolicy {')[1].split('// End display scale policy.')[0]
frames='struct TVMicrophoneFrames {'+s.split('struct TVMicrophoneFrames {')[1].split('// End microphone frame policy.')[0]
program='import Foundation\n'+scale+frames+r'''
let valid:[String:Any] = ["status_code":200,"scale_set_supported":true,"supported_scale_percents":[150,100,150],"current_scale_percent":150]
let policy=TVDisplayScalePolicy(valid,status:200)!
assert(policy.options==[100,150] && policy.current==150)
for status in [-1,2000,404,501,500] {assert(TVDisplayScalePolicy(valid,status:status)==nil)}
for change in [["status_code":400],["scale_set_supported":false],["supported_scale_percents":[]],["supported_scale_percents":[100,999]],["supported_scale_percents":[100.5]],["supported_scale_percents":[true]],["supported_scale_percents":Array(repeating:100,count:33)]] as [[String:Any]] {
 var invalid=valid;invalid.merge(change) {_,new in new};assert(TVDisplayScalePolicy(invalid,status:200)==nil)
}
var unknown=valid;unknown["current_scale_percent"]=NSNull();assert(TVDisplayScalePolicy(unknown,status:200)?.current==nil)
unknown["current_scale_percent"]=150.5;assert(TVDisplayScalePolicy(unknown,status:200)?.current==nil)
var framing=TVMicrophoneFrames()
assert(framing.append(Array(repeating:0.1,count:959)).isEmpty)
let first=framing.append([0.2]);assert(first.count==1 && first[0].count==960 && first[0].last==0.2)
assert(framing.pending.isEmpty)
assert(framing.append(Array(repeating:0,count:10000)).count==5 && framing.pending.isEmpty)
assert(framing.append([Float.nan]).isEmpty && framing.pending.isEmpty)
assert(framing.append([Float.infinity]).isEmpty)
assert(framing.append(Array(repeating:0,count:2000)).count==2 && framing.pending.count==80)
print("PASS: host status/schema/range validation, advertised scale deduplication, unknown read-back, 20ms packet boundaries, nonfinite rejection and bounded microphone buffering")
'''
with tempfile.TemporaryDirectory() as d:
 p=Path(d)/'extensions.swift';p.write_text(program)
 subprocess.run(['/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift',str(p)],check=True)
