"""Test the production bitrate policy without UIKit or application defaults."""
from pathlib import Path
import re
import subprocess
import tempfile
source = (Path(__file__).resolve().parents[1] / 'Selene/ViewControllers/SettingsSwiftUI.swift').read_text()
policy = source.split('private enum TVBitratePolicy {')[1].split('\nprivate extension SettingsSession')[0]
program = 'import Foundation\nprivate enum TVBitratePolicy {' + policy
program += '''
for mbps in [150, 160, 200, 300, 800] {
    let kbps = TVBitratePolicy.parseMbps(String(mbps))!
    assert(kbps == Double(mbps * 1000))
    let saved = try! JSONEncoder().encode(kbps)
    let restored = try! JSONDecoder().decode(Double.self, from: saved)
    assert(TVBitratePolicy.clamp(restored) == kbps)
}
for (current, next, previous) in [(150000.0,160000.0,140000.0), (190000,200000,180000), (200000,210000,190000), (210000,235000,185000), (300000,325000,275000), (155125,165125,145125)] {
    assert(TVBitratePolicy.step(current, forward: true) == next)
    assert(TVBitratePolicy.step(current, forward: false) == previous)
}
assert(TVBitratePolicy.step(500, forward: false) == 500)
assert(TVBitratePolicy.step(800000, forward: true) == 800000)
assert(TVBitratePolicy.step(790000, forward: true) == 800000)
assert(TVBitratePolicy.parseMbps("155.125") == 155125)
assert(TVBitratePolicy.parseMbps("0,5") == 500)
for input in ["", "nan", "inf", "-1", "0.49", "800.001", "hello"] {
    assert(TVBitratePolicy.parseMbps(input) == nil, input)
}
assert(TVBitratePolicy.clamp(.nan) == 500)
assert(TVBitratePolicy.clamp(900000) == 800000)
print("PASS: 150/160/200/300/800 Mbps, 10/25 Mbps steps at 200 Mbps boundary, exact values, range and non-finite validation")
'''
with tempfile.TemporaryDirectory() as directory:
    path = Path(directory) / 'bitrate.swift'
    path.write_text(program)
    subprocess.run(['/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift', str(path)], check=True)
