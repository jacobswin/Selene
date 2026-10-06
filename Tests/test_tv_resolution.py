"""Validate the production tvOS resolution choices and custom input policy."""
from pathlib import Path
import subprocess
import tempfile
source = (Path(__file__).resolve().parents[1] / 'Selene/ViewControllers/SettingsSwiftUI.swift').read_text()
policy = source.split('private enum TVResolutionPolicy {')[1].split('\nprivate extension SettingsSession')[0]
program = 'import Foundation\nprivate enum TVResolutionPolicy {' + policy + r'''
for (value, w, h) in [(0,1280,720), (1,1920,1080), (6,2560,1440), (7,3200,1800), (2,3840,2160)] {
    let size = TVResolutionPolicy.preset(value)!
    assert(size.width == w && size.height == h)
    assert(TVResolutionPolicy.selection(width: w, height: h) == value)
}
assert(TVResolutionPolicy.preset(4) == nil)
assert(TVResolutionPolicy.selection(width: 2560, height: 1080) == 5)
assert(TVResolutionPolicy.parse(width: " 3200 ", height: "1800", supportsHEVC: true) != nil)
assert(TVResolutionPolicy.parse(width: "1920", height: "1080", supportsHEVC: false) != nil)
for (w, h) in [("2561","1440"), ("2560","1441"), ("3842","2160"), ("3840","2162"), ("0","720"), ("abc","720"), ("","720"), ("999999999999999999999","720")] {
    assert(TVResolutionPolicy.parse(width: w, height: h, supportsHEVC: true) == nil)
}
assert(TVResolutionPolicy.parse(width: "2560", height: "1440", supportsHEVC: false) == nil)
print("PASS: 720p/1080p/2K/3K/4K choices, custom dimensions, hardware limits and invalid input")
'''
with tempfile.TemporaryDirectory() as directory:
    path = Path(directory) / 'resolution.swift'
    path.write_text(program)
    subprocess.run(['/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift', str(path)], check=True)
