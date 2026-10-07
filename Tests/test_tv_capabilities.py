"""Exercise the production capability formatter's missing-data contracts."""
from pathlib import Path
import subprocess,tempfile
s=(Path(__file__).resolve().parents[1]/'Selene/ViewControllers/TVStreamExperience.swift').read_text()
core=s.split('struct TVCapabilityValue {')[1].split('/// A snapshot')[0]
program='import Foundation\nstruct TVCapabilityValue {'+core+'''
assert(TVCapabilityValue.numeric(nil, format:"%.1f Mbps",active:true,unknown:"unknown",notStarted:"not started") == "unknown")
assert(TVCapabilityValue.numeric(nil, format:"%.1f Mbps",active:false,unknown:"unknown",notStarted:"not started") == "not started")
for value in [Double.nan, Double.infinity, -1] {
 assert(TVCapabilityValue.numeric(value,format:"%.1f",active:true,unknown:"unknown",notStarted:"not started") == "unknown")
}
assert(TVCapabilityValue.numeric(0,format:"%.0f",active:true,unknown:"unknown",notStarted:"not started") == "0")
assert(TVCapabilityValue.numeric(59.94,format:"%.2f FPS",active:true,unknown:"unknown",notStarted:"not started") == "59.94 FPS")
print("PASS: unavailable data, no-session state, non-finite measurements, zero values and observed FPS formatting")
'''
with tempfile.TemporaryDirectory() as directory:
 p=Path(directory)/'cap.swift';p.write_text(program)
 subprocess.run(['/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift',str(p)],check=True)
