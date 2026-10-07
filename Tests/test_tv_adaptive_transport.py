"""Exercise the production adaptive controller and serialized request coordinator together."""
from pathlib import Path
import subprocess,tempfile
s=(Path(__file__).resolve().parents[1]/'Selene/ViewControllers/TVStreamExperience.swift').read_text()
session=s.split('@objcMembers final class SeleneTVSession: NSObject {')[1].split('    @objc(showMenuFrom:)')[0]
policy=s.split('// Pure adaptive policy:')[1].split('// End pure adaptive policy.')[0];policy=policy[policy.index('struct TVAdaptiveSample'):]
runtime='final class TVAdaptiveController {'+s.split('final class TVAdaptiveController {')[1].split('final class TVAdaptiveSettingsController')[0]
prefix='''
import Foundation
var clock = 0.0
func CACurrentMediaTime()->Double { clock }
extension String { var localized:String { self } }
final class Config { var bitRate:Int32=200000 }
final class Host { var status=200; var requested=0; func request(forBitrate:Int)->Int { status }; func updateRequestedBitrate(_ value:Int32) { requested=Int(value) } }
final class StreamFrameViewController { let streamConfig=Config(); var mainFrameViewcontroller:Host?=Host(); var metrics:[String:Any]=[:]; func tvStreamMeasurements()->[String:Any] { metrics } }
final class Settings { var bitrate:NSNumber=200000 }
final class DataManager { static let settings=Settings(); func getSettings()->Settings? { Self.settings }; func retrieveSettings()->Settings? { Self.settings }; func saveData() {} }
final class KeyboardSupport { static func releaseAllKeys() {} }
final class LocalizationHelper { static func localizedString(forKey:String,_ status:Int,_ bitrate:Double)->String { "rejected" } }
'''
checks='''
func pump(_ condition:()->Bool) { let deadline=Date().addingTimeInterval(2); while !condition() && Date()<deadline { RunLoop.main.run(until:Date().addingTimeInterval(0.001)) }; assert(condition()) }
let defaults=UserDefaults.standard
for key in ["enabled","lower","upper"] { defaults.removeObject(forKey:"Selene.abr."+key) }
let session=SeleneTVSession();let stream=StreamFrameViewController();session.begin(stream)
assert(!session.adaptive.enabled && !session.adaptive.active)
session.adaptive.enabled=true
func sample(loss:Double=0) { clock += 1;stream.metrics=["windowEnd":clock,"frames":100,"receivedFrames":98,"networkDroppedFrames":loss*100,"rttMS":10];session.adaptive.sample() }
stream.mainFrameViewcontroller?.status=404
sample(loss:0.02);sample(loss:0.02);pump { !session.pending }
assert(session.adaptive.unsupported && !session.adaptive.active && session.targetKbps==200000)
session.adaptive.enabled=true; stream.mainFrameViewcontroller?.status = -1001
for _ in 0..<3 {
 sample(loss:0.02);sample(loss:0.02);pump { !session.pending }
 if session.adaptive.active { for _ in 0..<5 { sample() } }
}
assert(session.adaptive.paused && !session.adaptive.active && session.targetKbps==200000)
session.adaptive.enabled=true; stream.mainFrameViewcontroller?.status=200
sample(loss:0.02);sample(loss:0.02);pump { !session.pending }
assert(session.targetKbps==160000 && DataManager.settings.bitrate.intValue==200000)
var done=false
session.requestManual(160000) { ok,_,_ in assert(ok);done=true }
assert(done && !session.adaptive.active && !session.adaptive.enabled && DataManager.settings.bitrate.intValue==160000)
session.end()
for key in ["enabled","lower","upper"] { defaults.removeObject(forKey:"Selene.abr."+key) }
print("PASS: unsupported host stops automation, three timeout failures pause, accepted automatic target preserves manual storage, same-target manual override persists and session shutdown")
'''
with tempfile.TemporaryDirectory() as d:
 p=Path(d)/'runtime.swift';p.write_text(prefix+'final class SeleneTVSession:NSObject {'+session+'}\n'+policy+runtime+checks)
 subprocess.run(['/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift',str(p)],check=True)
