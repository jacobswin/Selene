"""Exercise the production gate used by duplicate UIKit Back routes."""
from pathlib import Path
import subprocess, tempfile
source = (Path(__file__).resolve().parents[1] / 'Selene/ViewControllers/TVStreamExperience.swift').read_text()
policy = source.split('struct TVBackGate {')[1].split('/// One owner')[0]
program = 'import Foundation\nstruct TVBackGate {' + policy + '\nvar gate = TVBackGate()\nassert(gate.accept(1))\nassert(!gate.accept(1))\nassert(!gate.accept(1.1))\nassert(gate.accept(1.31))\ngate.block(2)\nassert(!gate.accept(2.1))\nassert(gate.accept(2.31))\nfor n in 0..<20 { assert(gate.accept(3 + Double(n))); assert(!gate.accept(3 + Double(n))) }\nprint("PASS: duplicate Back delivery, dismissal bounce and 20 independent presses")\n'
with tempfile.TemporaryDirectory() as directory:
    path = Path(directory) / 'back.swift'
    path.write_text(program)
    subprocess.run(['/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift', str(path)], check=True)
