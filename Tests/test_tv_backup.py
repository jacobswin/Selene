"""Exercise the exact production versioned backup schema before any writes."""
from pathlib import Path
import subprocess,tempfile
s=(Path(__file__).resolve().parents[1]/'Selene/ViewControllers/TVStreamExperience.swift').read_text()
core='struct TVBackupDocument: Codable, Equatable {'+s.split('struct TVBackupDocument: Codable, Equatable {')[1].split('// End settings-backup schema.')[0]
program='import Foundation\n'+core+r'''
var document=TVBackupDocument(version:1,video:["width":3840,"height":2160,"framerate":60,"bitrate":800000,"preferredCodec":2,"audioConfig":8,"framePacingMode":2,"frameQueueSize":5,"renderingBackend":0],flags:["enableHdr":true,"fullColorRange":false,"asyncFrameDequeue":false],client:["compactCovers":1,"lockOnDisconnect":0,"askReconnectOnReturn":0,"leftDeadzone":30,"rightDeadzone":0,"language":2],shortcuts:Dictionary(uniqueKeysWithValues:TVBackupDocument.shortcutIDs.map {($0,true)}),layout:["stretch":0,"alignment":4,"x":-50,"y":50])
let code=try document.code();assert(code.count<2200)
let roundTrip=try TVBackupDocument.decode(" "+code+"\n");assert(roundTrip==document)
for value in ["", "SELENE2:"+String(code.dropFirst(8)),"SELENE1:not-base64",String(repeating:"a",count:4097)] {
 do {_=try TVBackupDocument.decode(value);fatalError("accepted corrupt code")}catch {}
}
func reject(_ edit:(inout TVBackupDocument)->Void) {var bad=document;edit(&bad);do {try bad.validate();fatalError("accepted invalid payload")}catch {}}
reject {$0.version=2};reject {$0.video["width"]=3841};reject {$0.video["bitrate"]=800001};reject {$0.video["bitrate"]=499};reject {$0.video["audioConfig"]=3}
reject {$0.video.removeValue(forKey:"height")};reject {$0.video["serverCert"]=1};reject {$0.client["account"]=1};reject {$0.client["leftDeadzone"]=31};reject {$0.flags["pairing"]=true}
reject {$0.layout["x"]=51};reject {$0.layout["alignment"]=1.5};reject {$0.layout["y"]=Double.nan};reject {$0.shortcuts["privateKey"]=true}
do {_=try TVBackupDocument.decode(code,supportsHEVC:false);fatalError("accepted oversized device resolution")}catch {}
document.video["width"]=1920;document.video["height"]=1080;try document.validate(supportsHEVC:false)
for bitrate in [150000,160000,200000,300000,800000] {document.video["bitrate"]=bitrate;let sampleCode=try document.code();let sample=try TVBackupDocument.decode(sampleCode);assert(sample.video["bitrate"]==bitrate)}
let json=String(data:try JSONEncoder().encode(document),encoding:.utf8)!
for secret in ["serverCert","pairing","host","address","password","account"] {assert(!json.contains(secret))}
print("PASS: backup round trip, QR capacity, versions, corruption, bounds, allowlist, no secrets and device limits")
'''
with tempfile.TemporaryDirectory() as directory:
 p=Path(directory)/'backup.swift';p.write_text(program)
 subprocess.run(['/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift',str(p)],check=True)
