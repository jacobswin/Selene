"""Exercise the production tvOS audio preference compatibility policy."""
from pathlib import Path
import re
import subprocess
import tempfile
root = Path(__file__).resolve().parents[1]
source = (root / 'Selene/ViewControllers/SettingsSwiftUI.swift').read_text()
header = (root / 'Selene/Database/DataManager.h').read_text()
names = {'stereo': 'Stereo', 'stereoSDL': 'StereoSDL', 'SDL51': 'SDL51', 'SDL71': 'SDL71'}
values = {name: int(re.search(r'AudioConfig' + cname + r'\s*=\s*(\d+)', header).group(1)) for name, cname in names.items()}
policy = source.split('private func settingsAudioConfigValuesForCurrentOS()')[1].split('private func settingsMaximumMicVolumeForCurrentDevice()')[0]
# Execute the tvOS branch on the development Mac, without UIKit or a TV runtime.
policy = policy.replace('#if os(tvOS)', '').replace('#endif', '')
program = 'import Foundation\nenum AudioConfig: Int {\n' + ''.join(f'case {name} = {value}\n' for name, value in values.items()) + '}\nprivate func settingsAudioConfigValuesForCurrentOS()' + policy + '''
assert(settingsSanitizedAudioConfig(AudioConfig.stereo.rawValue) == AudioConfig.stereo.rawValue)
assert(settingsSanitizedAudioConfig(AudioConfig.stereoSDL.rawValue) == AudioConfig.stereo.rawValue)
for value in [AudioConfig.SDL51.rawValue, AudioConfig.SDL71.rawValue] {
    assert(settingsSanitizedAudioConfig(value) == value)
}
for value in [-21, -512, -714, 0, 12, Int.max] {
    assert(settingsSanitizedAudioConfig(value) == AudioConfig.stereo.rawValue)
}
print("PASS: both legacy stereo values resolve to one choice, 5.1/7.1 survive and invalid layouts fall back safely")
'''
with tempfile.TemporaryDirectory() as directory:
    path = Path(directory) / 'audio.swift'
    path.write_text(program)
    subprocess.run(['/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift', str(path)], check=True)
