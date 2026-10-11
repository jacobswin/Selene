from pathlib import Path
import subprocess,tempfile
s=(Path(__file__).resolve().parents[1]/'Selene/ViewControllers/TVStreamExperience.swift').read_text()
core='struct TVConnectionRequest: Equatable {'+s.split('struct TVConnectionRequest: Equatable {')[1].split('// End connection request policy.')[0]
evidence='enum TVHostExtensionEvidence: Equatable {'+s.split('enum TVHostExtensionEvidence: Equatable {')[1].split('// End host extension evidence.')[0]
program='import Foundation\n'+core+evidence+r'''
let original=TVConnectionRequest(width:3840,height:2160,fps:60,codec:2,hdr:true,fullRange:false)
assert(original.changes(from:original).isEmpty)
assert(original.changes(from:TVConnectionRequest(width:2560,height:1440,fps:60,codec:2,hdr:true,fullRange:false))==["Resolution"])
assert(original.changes(from:TVConnectionRequest(width:3840,height:2160,fps:120,codec:3,hdr:false,fullRange:true))==["Frame Rate","Preferred Codec","HDR","Full Color Range"])
assert(TVHostExtensionEvidence.bitrate(nil) == .unverified)
assert(TVHostExtensionEvidence.bitrate(200) == .accepted)
for status in [404,501] {assert(TVHostExtensionEvidence.bitrate(status) == .unavailable)}
for status in [400,500,-1001] {assert(TVHostExtensionEvidence.bitrate(status) == .failed(status))}
print("PASS: connection-change/revert detection and evidence-based extension status")
'''
with tempfile.TemporaryDirectory() as directory:
 p=Path(directory)/'reconnect.swift';p.write_text(program)
 subprocess.run(['/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift',str(p)],check=True)
