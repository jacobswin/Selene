"""Exercise production begin: settings reload must not restart an active session."""
from pathlib import Path
import subprocess,tempfile
s=(Path(__file__).resolve().parents[1]/'Selene/ViewControllers/TVStreamExperience.swift').read_text()
requestPolicy='struct TVConnectionRequest: Equatable {'+s.split('struct TVConnectionRequest: Equatable {')[1].split('// End connection request policy.')[0]
method='func begin'+s.split('func begin')[1].split('    func end()')[0]
program = 'import Foundation\nfinal class TVMicrophoneBridge { static func begin() {}; static func end() {} }\n'+requestPolicy+r'''
class Config { var width=1920,height=1080,frameRate=60;var enableHdr=false,fullColorRange=false,controlOnly=false; var bitRate = 200_000 }
class StreamFrameViewController: NSObject { let streamConfig=Config() }
class Settings {var width:NSNumber=1920,height:NSNumber=1080,framerate:NSNumber=60;var enableHdr=false,fullColorRange=false,controlOnly=false; var preferredCodec=2 }
let settings=Settings()
class DataManager { func getSettings()->Settings? {settings} }
class Adaptive { var starts=0;func start(){starts+=1} }
class Session { var initialRequest:TVConnectionRequest?;var observedBitrateStatus:Int?
 weak var stream:StreamFrameViewController?
 var requestedCodec=0,initialKbps=0,targetKbps=0
 var generation=UUID();var pending=false,lastMessage="",returningFromSettings=false,nextFocus="continue"
 let adaptive=Adaptive()
'''+method+r'''}
let a=StreamFrameViewController(),b=StreamFrameViewController(),session=Session()
session.begin(a);let token=session.generation
assert(session.initialKbps==200_000 && session.requestedCodec==2 && session.adaptive.starts==1)
session.targetKbps=160_000;session.returningFromSettings=true;session.pending=true
settings.preferredCodec=3;session.begin(a)
assert(session.generation==token && session.targetKbps==160_000 && session.requestedCodec==2)
assert(session.returningFromSettings && session.pending && session.adaptive.starts==1)
b.streamConfig.bitRate=300_000;session.begin(b)
assert(session.generation != token && session.initialKbps==300_000 && session.requestedCodec==3)
assert(!session.pending && !session.returningFromSettings && session.adaptive.starts==2)
print("PASS: settings reload preserves active target, initial codec, pending requests and adaptive session")
'''
with tempfile.TemporaryDirectory() as directory:
 p=Path(directory)/'session.swift';p.write_text(program)
 subprocess.run(['/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift',str(p)],check=True)
