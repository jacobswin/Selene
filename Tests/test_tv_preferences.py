from pathlib import Path
import subprocess, tempfile
s=(Path(__file__).resolve().parents[1]/'Selene/ViewControllers/TVStreamExperience.swift').read_text()
body=s.split('@objcMembers final class TVClientPreferences: NSObject {')[1].split('\nfinal class TVClientSettingsController')[0]
program='import Foundation\nfinal class TVClientPreferences: NSObject {'+body+'\nlet defaults = UserDefaults.standard\nlet ids = ["altTab", "windows", "esc", "enter", "text", "capabilities"]\nfor id in ids { defaults.removeObject(forKey: "Selene.tv.shortcut." + id); assert(TVClientPreferences.shortcutVisible(id)); TVClientPreferences.setShortcutVisible(id, visible:false); assert(!TVClientPreferences.shortcutVisible(id)); TVClientPreferences.setShortcutVisible(id, visible:true); assert(TVClientPreferences.shortcutVisible(id)); defaults.removeObject(forKey:"Selene.tv.shortcut." + id) }\ndefaults.removeObject(forKey:"Selene.tv.compactCovers")\nassert(!TVClientPreferences.compactCovers)\nTVClientPreferences.compactCovers=true\nassert(defaults.bool(forKey:"Selene.tv.compactCovers"))\ndefaults.removeObject(forKey:"Selene.tv.compactCovers")\nprint("PASS: default cover size, all shortcut defaults and preference persistence")\n'
with tempfile.TemporaryDirectory() as directory:
 p=Path(directory)/'preferences.swift';p.write_text(program)
 subprocess.run(['/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift',str(p)],check=True)
