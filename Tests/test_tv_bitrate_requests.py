"""Run the production request coordinator against a controllable host transport."""
from pathlib import Path
import subprocess,tempfile
source=(Path(__file__).resolve().parents[1]/'Selene/ViewControllers/TVStreamExperience.swift').read_text()
core=source.split('@objcMembers final class SeleneTVSession: NSObject {')[1].split('    @objc(showMenuFrom:)')[0]
program=r'''
import Foundation
final class TVAdaptiveController { init(session:SeleneTVSession) {}; func start() {}; func stop() {}; func manualOverride() {} }
final class Config { var bitRate: Int32 = 150000 }
final class Host {
 var status = 200; var calls = 0; var requested = 0
 func request(forBitrate value: Int) -> Int { calls += 1; Thread.sleep(forTimeInterval: 0.04); return status }
 func updateRequestedBitrate(_ value: Int32) { requested = Int(value) }
}
final class StreamFrameViewController { let streamConfig=Config(); var mainFrameViewcontroller: Host?=Host() }
final class Settings { var bitrate: NSNumber? }
final class DataManager { static let settings=Settings(); func retrieveSettings()->Settings? { Self.settings }; func saveData() {} }
final class KeyboardSupport { static func releaseAllKeys() {} }
final class LocalizationHelper { static func localizedString(forKey: String, _ status: Int, _ bitrate: Double)->String { "rejected" } }
'''+ 'final class SeleneTVSession: NSObject {'+core+'}\n'+r'''
func pump(_ condition: ()->Bool) {
 let deadline=Date().addingTimeInterval(2)
 while !condition() && Date()<deadline { RunLoop.main.run(until:Date().addingTimeInterval(0.01)) }
 assert(condition())
}
let session=SeleneTVSession(); let stream=StreamFrameViewController()
session.begin(stream)
var done=false
session.requestManual(160000) { ok,value,status in assert(ok && value==160000 && status==200); done=true }
assert(session.pending)
session.requestManual(200000) { ok,value,status in assert(!ok && value==150000 && status == -1) }
pump { done }; assert(!session.pending && session.targetKbps==160000)
assert(DataManager.settings.bitrate?.intValue==160000 && stream.mainFrameViewcontroller?.calls==1)
stream.mainFrameViewcontroller?.status=400; done=false
session.requestManual(300000) { ok,value,status in assert(!ok && value==160000 && status==400); done=true }
pump { done }; assert(session.targetKbps==160000 && DataManager.settings.bitrate?.intValue==160000)
stream.mainFrameViewcontroller?.status=200; done=false
session.requestManual(800000) { _,_,_ in done=true }
session.end(); let next=StreamFrameViewController(); next.streamConfig.bitRate=200000; session.begin(next)
RunLoop.main.run(until:Date().addingTimeInterval(0.15))
assert(!done && session.targetKbps==200000 && !session.pending)
var autoDone=false
session.request(180000,saveManual:false) { ok,value,_ in assert(ok && value==180000); autoDone=true }
pump { autoDone }; assert(DataManager.settings.bitrate?.intValue==160000)
print("PASS: serialized mutation, host rejection rollback, saved manual target, stale callback isolation and transient automatic target")
'''
with tempfile.TemporaryDirectory() as directory:
 p=Path(directory)/'requests.swift';p.write_text(program)
 subprocess.run(['/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift',str(p)],check=True)
