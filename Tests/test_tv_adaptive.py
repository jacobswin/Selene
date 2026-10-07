from pathlib import Path
import subprocess,tempfile
s=(Path(__file__).resolve().parents[1]/'Selene/ViewControllers/TVStreamExperience.swift').read_text()
core=s.split('// Pure adaptive policy:')[1].split('// End pure adaptive policy.')[0]
core=core[core.index('struct TVAdaptiveSample'):]
checks='''
func sample(_ time:Double, _ loss:Double=0,_ rtt:Double=10,received:Double=60)->TVAdaptiveSample { TVAdaptiveSample(window:time,time:time,frames:100,received:received,dropped:loss*100,rtt:rtt) }
var p=TVAdaptivePolicy()
assert(p.evaluate(sample(1),target:200000,lower:50000,upper:300000) == nil)
assert(p.evaluate(sample(2,0.02),target:200000,lower:50000,upper:300000) == nil)
assert(p.evaluate(sample(3,0.02),target:200000,lower:50000,upper:300000)?.0 == 160000)
for t in 4...7 { assert(p.evaluate(sample(Double(t),0.2),target:160000,lower:50000,upper:300000) == nil) }
assert(p.evaluate(sample(8,0.2),target:160000,lower:50000,upper:300000) == nil)
assert(p.evaluate(sample(9,0.2),target:160000,lower:50000,upper:300000)?.0 == 128000)
p=TVAdaptivePolicy()
_ = p.evaluate(sample(1),target:200000,lower:50000,upper:300000)
for t in 2...3 { assert(p.evaluate(sample(Double(t),0,40),target:200000,lower:50000,upper:300000) == nil) }
assert(p.evaluate(sample(4,0,40),target:200000,lower:50000,upper:300000)?.0 == 160000)
p=TVAdaptivePolicy()
for t in 1...15 { assert(p.evaluate(sample(Double(t)),target:200000,lower:50000,upper:300000) == nil) }
assert(p.evaluate(sample(16),target:200000,lower:50000,upper:300000)?.0 == 210000)
p=TVAdaptivePolicy()
_ = p.evaluate(sample(1,0.5),target:500,lower:500,upper:800000)
assert(p.evaluate(sample(2,0.5),target:500,lower:500,upper:800000) == nil)
p=TVAdaptivePolicy()
_ = p.evaluate(sample(1,0.5),target:800000,lower:500,upper:800000)
assert(p.evaluate(sample(1,0.5),target:800000,lower:500,upper:800000) == nil)
assert(p.evaluate(nil,target:800000,lower:500,upper:800000) == nil)
assert(p.evaluate(sample(2,0.5,received:0),target:800000,lower:500,upper:800000) == nil)
assert(p.evaluate(sample(3,0.5),target:800000,lower:500,upper:800000) == nil)
assert(p.evaluate(sample(0),target:800000,lower:500,upper:800000) == nil)
assert(p.evaluate(sample(1,0.5),target:800000,lower:500,upper:800000) == nil)
assert(p.evaluate(sample(9,0.5),target:800000,lower:500,upper:800000) == nil)
print("PASS: loss/RTT streaks, healthy recovery, five-second cooldown, bounds, duplicate/reset windows, gaps, missing statistics and no-video gating")
'''
with tempfile.TemporaryDirectory() as d:
 p=Path(d)/'adaptive.swift';p.write_text('import Foundation\n'+core+checks)
 subprocess.run(['/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift',str(p)],check=True)
