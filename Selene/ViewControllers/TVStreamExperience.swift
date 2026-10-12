#if os(tvOS)
import UIKit
import Foundation
import AVFoundation
import VideoToolbox
import GameController
import CoreImage
import AVKit

// Navigation, responder and gesture fallbacks may see the same physical press.
struct TVBackGate {
    private var blockedUntil = -Double.infinity
    mutating func accept(_ now: Double) -> Bool {
        guard now >= blockedUntil else { return false }
        blockedUntil = now + 0.3
        return true
    }
    mutating func block(_ now: Double) { blockedUntil = now + 0.3 }
}

@objcMembers final class TVClientPreferences: NSObject {
    static var inputOnly: Bool {
        get { UserDefaults.standard.bool(forKey:"Selene.tv.inputOnly") }
        set { UserDefaults.standard.set(newValue,forKey:"Selene.tv.inputOnly") }
    }
    static var monitorMode: Int {
        get { min(4,max(-1,(UserDefaults.standard.object(forKey:"Selene.tv.monitorMode") as? NSNumber)?.intValue ?? -1)) }
        set { UserDefaults.standard.set(min(4,max(-1,newValue)),forKey:"Selene.tv.monitorMode") }
    }
    static var compactCovers: Bool {
        get { UserDefaults.standard.bool(forKey: "Selene.tv.compactCovers") }
        set {
            UserDefaults.standard.set(newValue, forKey: "Selene.tv.compactCovers")
            NotificationCenter.default.post(name: Notification.Name("SeleneTVAppearanceChanged"), object: nil)
        }
    }
    static var lockOnDisconnect: Bool {
        get { UserDefaults.standard.bool(forKey: "Selene.tv.lockOnDisconnect") }
        set { UserDefaults.standard.set(newValue, forKey: "Selene.tv.lockOnDisconnect") }
    }
    static var askReconnectOnReturn: Bool {
        get { UserDefaults.standard.bool(forKey:"Selene.tv.askReconnectOnReturn") }
        set { UserDefaults.standard.set(newValue,forKey:"Selene.tv.askReconnectOnReturn") }
    }
    static var qualityWarnings: Bool {
        get { (UserDefaults.standard.object(forKey:"Selene.tv.qualityWarnings") as? Bool) ?? true }
        set { UserDefaults.standard.set(newValue,forKey:"Selene.tv.qualityWarnings") }
    }
    static var statsPosition: Int {
        get { min(4,max(0,UserDefaults.standard.integer(forKey:"Selene.tv.statsPosition"))) }
        set { UserDefaults.standard.set(min(4,max(0,newValue)),forKey:"Selene.tv.statsPosition") }
    }
    static func mouseSpeed(_ scroll: Bool) -> Int {
        let key = scroll ? "Selene.tv.scrollSpeed" : "Selene.tv.mouseSpeed"
        return min(300,max(25,(UserDefaults.standard.object(forKey:key) as? NSNumber)?.intValue ?? 100))
    }
    static func setMouseSpeed(_ scroll: Bool, value: Int) {
        UserDefaults.standard.set(min(300,max(25,value)),forKey:scroll ? "Selene.tv.scrollSpeed" : "Selene.tv.mouseSpeed")
    }
    static var invertScroll: Bool {
        get { UserDefaults.standard.bool(forKey:"Selene.tv.invertScroll") }
        set { UserDefaults.standard.set(newValue,forKey:"Selene.tv.invertScroll") }
    }
    static func deadzone(_ side: String) -> Int { min(30, max(0, UserDefaults.standard.integer(forKey: "Selene.tv." + side + "Deadzone"))) }
    static func setDeadzone(_ side: String, value: Int) { UserDefaults.standard.set(min(30, max(0, value)), forKey: "Selene.tv." + side + "Deadzone") }
    static func shortcutVisible(_ id: String) -> Bool {
        (UserDefaults.standard.object(forKey: "Selene.tv.shortcut." + id) as? Bool) ?? true
    }
    static func setShortcutVisible(_ id: String, visible: Bool) {
        UserDefaults.standard.set(visible, forKey: "Selene.tv.shortcut." + id)
    }
}

class TVDarkTableController: UITableViewController {
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.textColor = .white
        header.contentView.backgroundColor = UIColor(white:0.04,alpha:1)
    }
}

final class TVClientSettingsController: TVDarkTableController {
    typealias Row = (title: String, value: () -> String, action: () -> Void)
    private var groups: [(String, [Row])] = []
    override func viewDidLoad() {
        super.viewDidLoad(); title = "TV experience".localized
        tableView.backgroundColor = UIColor(white: 0.04, alpha: 1)
        tableView.rowHeight = 90; tableView.remembersLastFocusedIndexPath = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done".localized, style: .done, target: self, action: #selector(close))
        makeRows()
    }
    private func makeRows() {
        let compact: Row = ("App cover size", { TVClientPreferences.compactCovers ? "Compact covers".localized : "Standard covers".localized }, { TVClientPreferences.compactCovers.toggle() })
        let shortcuts: [Row] = [("altTab", "Alt+Tab"), ("windows", "Windows"), ("esc", "Esc"), ("enter", "Enter"), ("text", "Text input"), ("capabilities", "Capability report")].map { id, title in
            (title, { TVClientPreferences.shortcutVisible(id) ? "On".localized : "Off".localized }, { TVClientPreferences.setShortcutVisible(id, visible: !TVClientPreferences.shortcutVisible(id)) })
        }
        let lock: Row = ("Lock PC on disconnect", { TVClientPreferences.lockOnDisconnect ? "On".localized : "Off".localized }, { TVClientPreferences.lockOnDisconnect.toggle() })
        let controller: [Row] = [
            ("Controller test", { "Buttons and sticks".localized }, { [weak self] in self?.present(UINavigationController(rootViewController: TVControllerTestController()), animated: true) }),
            ("Left stick deadzone", { "\(TVClientPreferences.deadzone("left"))%" }, { [weak self] in self?.chooseDeadzone("left") }),
            ("Right stick deadzone", { "\(TVClientPreferences.deadzone("right"))%" }, { [weak self] in self?.chooseDeadzone("right") }),
            ("Stick center calibration", { "This connection only".localized }, { [weak self] in self?.present(UINavigationController(rootViewController:TVCalibrationController()),animated:true) }),
            ("Controller mouse speed", { "\(TVClientPreferences.mouseSpeed(false))%" }, { [weak self] in self?.chooseMouseSpeed(false) }),
            ("Controller scroll speed", { "\(TVClientPreferences.mouseSpeed(true))%" }, { [weak self] in self?.chooseMouseSpeed(true) }),
            ("Invert controller scrolling", { TVClientPreferences.invertScroll ? "On".localized : "Off".localized }, { TVClientPreferences.invertScroll.toggle() })]
        let presentation: [Row] = [
            ("Statistics position", { ["Top center","Top left","Top right","Bottom left","Bottom right"][TVClientPreferences.statsPosition].localized }, { [weak self] in self?.chooseStatsPosition() }),
            ("Network quality reminders", { TVClientPreferences.qualityWarnings ? "On".localized : "Off".localized }, { TVClientPreferences.qualityWarnings.toggle();SeleneTVSession.shared.stream?.tvRefreshQualityWarning() })]
        groups = [("Host session", [
            ("Input-only session", { TVClientPreferences.inputOnly ? "On".localized : "Off".localized }, { [weak self] in
                if TVClientPreferences.inputOnly { TVClientPreferences.inputOnly=false;return }
                let alert=UIAlertController(title:"Input-only session".localized,message:"Requires Foundation Sunshine. No video or audio will be received. Reconnect to apply; use Back to open controls.".localized,preferredStyle:.alert)
                alert.addAction(UIAlertAction(title:"Cancel".localized,style:.cancel))
                alert.addAction(UIAlertAction(title:"Enable".localized,style:.default) { [weak self] _ in TVClientPreferences.inputOnly=true;self?.tableView.reloadData() })
                self?.present(alert,animated:true)
            }),
            ("Host monitor arrangement", { ["Follow host","Keep monitor arrangement","Ensure active","Ensure primary","Use only stream display","Ensure secondary"][TVClientPreferences.monitorMode+1].localized }, { [weak self] in self?.chooseMonitorMode() })]), ("Appearance", [compact] + presentation), ("Menu shortcuts", shortcuts), ("Disconnect behavior", [lock, ("Ask to reconnect after Home", { TVClientPreferences.askReconnectOnReturn ? "On".localized : "Off".localized }, { TVClientPreferences.askReconnectOnReturn.toggle() })]), ("Controller", controller), ("Help and diagnostics", [
            ("Help and diagnostics", { "Remote guide and stream status".localized }, { [weak self] in self?.present(UINavigationController(rootViewController: TVHelpController()), animated:true) })])]
    }
    private func chooseMonitorMode() {
        let alert=UIAlertController(title:"Host monitor arrangement".localized,message:"Requires Foundation Sunshine. Applied on reconnect; this requests display topology, not capture-monitor selection. Use only stream display may disable other monitors.".localized,preferredStyle:.actionSheet)
        for (index,title) in ["Follow host","Keep monitor arrangement","Ensure active","Ensure primary","Use only stream display","Ensure secondary"].enumerated() {
            alert.addAction(UIAlertAction(title:title.localized,style:.default) { [weak self] _ in TVClientPreferences.monitorMode=index-1;self?.tableView.reloadData() })
        }
        alert.addAction(UIAlertAction(title:"Cancel".localized,style:.cancel));present(alert,animated:true)
    }
    private func chooseMouseSpeed(_ scroll: Bool) {
        let alert=UIAlertController(title:(scroll ? "Controller scroll speed" : "Controller mouse speed").localized,message:"100% preserves the original speed. This affects controller mouse mode only.".localized,preferredStyle:.actionSheet)
        for value in stride(from:25,through:300,by:25) {
            alert.addAction(UIAlertAction(title:"\(value)%",style:.default) { [weak self] _ in TVClientPreferences.setMouseSpeed(scroll,value:value);self?.tableView.reloadData() })
        }
        alert.addAction(UIAlertAction(title:"Cancel".localized,style:.cancel));present(alert,animated:true)
    }
    private func chooseStatsPosition() {
        let alert=UIAlertController(title:"Statistics position".localized,message:"Statistics stay inside the TV safe area and do not move with the video.".localized,preferredStyle:.actionSheet)
        for (position,title) in ["Top center","Top left","Top right","Bottom left","Bottom right"].enumerated() {
            alert.addAction(UIAlertAction(title:title.localized,style:.default) { [weak self] _ in TVClientPreferences.statsPosition=position;SeleneTVSession.shared.stream?.view.setNeedsLayout();self?.tableView.reloadData() })
        }
        alert.addAction(UIAlertAction(title:"Cancel".localized,style:.cancel));present(alert,animated:true)
    }
    private func chooseDeadzone(_ side: String) {
        let alert = UIAlertController(title: (side == "left" ? "Left stick deadzone" : "Right stick deadzone").localized, message: "Select a radial deadzone. Zero preserves existing input behavior.".localized, preferredStyle: .actionSheet)
        for value in 0...30 {
            alert.addAction(UIAlertAction(title: "\(value)%" + (value == TVClientPreferences.deadzone(side) ? " ✓" : ""), style: .default) { [weak self] _ in
                TVClientPreferences.setDeadzone(side, value: value); self?.tableView.reloadData()
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel)); present(alert, animated: true)
    }
    override func numberOfSections(in tableView: UITableView) -> Int { groups.count }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { groups[section].1.count }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { groups[section].0.localized }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = groups[indexPath.section].1[indexPath.row]
        let cell = TVCapabilityCell(style: .value1, reuseIdentifier: nil)
        cell.backgroundColor = UIColor(white: 0.09, alpha: 1)
        cell.textLabel?.text = row.title.localized; cell.textLabel?.textColor = .white
        cell.detailTextLabel?.text = row.value(); cell.detailTextLabel?.textColor = .lightGray
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        groups[indexPath.section].1[indexPath.row].action()
        tableView.reloadRows(at: [indexPath], with: .none)
    }
    @objc private func close() { dismiss(animated: true) }
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.contains(where: { $0.type == .menu }) { return }; super.pressesBegan(presses, with: event)
    }
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.contains(where: { $0.type == .menu }) { close(); return }; super.pressesEnded(presses, with: event)
    }
}

final class TVControllerTestController: TVDarkTableController {
    private var timer: Timer?
    private weak var support: ControllerSupport?
    private var wasSuspended = true
    private var keyboardWasSuspended = true
    private var lines: [(String, String)] = []
    override func viewDidLoad() {
        super.viewDidLoad(); title = "Controller test".localized
        support = ControllerSupport.sharedInstance(); wasSuspended = support?.forwardingSuspended ?? true
        keyboardWasSuspended = KeyboardSupport.forwardingSuspended()
        support?.forwardingSuspended = true; KeyboardSupport.setForwardingSuspended(true)
        tableView.backgroundColor = UIColor(white: 0.04, alpha: 1); tableView.rowHeight = 125
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done".localized, style: .done, target: self, action: #selector(close))
        sample()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in self?.sample() }
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated); timer?.invalidate(); timer = nil
        support?.forwardingSuspended = wasSuspended
        KeyboardSupport.setForwardingSuspended(keyboardWasSuspended)
    }
    private func sample() {
        if let pad = GCController.controllers().compactMap({ $0.extendedGamepad }).first {
            let buttons: [(String, GCControllerButtonInput?)] = [("A",pad.buttonA),("B",pad.buttonB),("X",pad.buttonX),("Y",pad.buttonY),("L1",pad.leftShoulder),("R1",pad.rightShoulder),("L2",pad.leftTrigger),("R2",pad.rightTrigger),("Menu",pad.buttonMenu),("Options",pad.buttonOptions),("L3",pad.leftThumbstickButton),("R3",pad.rightThumbstickButton)]
            let pressed = buttons.filter { $0.1?.isPressed == true }.map { $0.0 }.joined(separator: " + ")
            lines = [("Controller", "Connected".localized), ("Left stick", String(format:"X %.3f · Y %.3f",pad.leftThumbstick.xAxis.value,pad.leftThumbstick.yAxis.value)), ("Right stick",String(format:"X %.3f · Y %.3f",pad.rightThumbstick.xAxis.value,pad.rightThumbstick.yAxis.value)), ("Pressed buttons",pressed.isEmpty ? "None".localized : pressed), ("D-pad",String(format:"X %.0f · Y %.0f",pad.dpad.xAxis.value,pad.dpad.yAxis.value))]
        } else {
            lines = [("Controller", "No compatible controller connected".localized), ("Left stick","Unavailable".localized), ("Right stick","Unavailable".localized), ("Pressed buttons","None".localized), ("D-pad","Unavailable".localized)]
        }
        for (index, line) in lines.enumerated() {
            let cell = tableView.cellForRow(at: IndexPath(row:index, section:0))
            cell?.textLabel?.text = line.0.localized; cell?.detailTextLabel?.text = line.1
        }
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { lines.count }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { "Test input stays on Apple TV and is not sent to your PC.".localized }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = TVCapabilityCell(style: .subtitle, reuseIdentifier: nil)
        cell.backgroundColor = UIColor(white:0.09, alpha:1); cell.textLabel?.textColor = .white; cell.detailTextLabel?.textColor = .lightGray
        cell.textLabel?.text = lines[indexPath.row].0.localized; cell.detailTextLabel?.text = lines[indexPath.row].1
        return cell
    }
    @objc private func close() { dismiss(animated:true) }
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.contains(where: { $0.type == .menu }) { return }; super.pressesBegan(presses, with:event)
    }
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.contains(where: { $0.type == .menu }) { close(); return }; super.pressesEnded(presses, with:event)
    }
}

// Pure calibration policy. A bad sample never replaces the previous center.
struct TVCalibrationPolicy {
    static func center(_ samples: [[Double]]) -> [Double]? {
        guard samples.count >= 20, samples.allSatisfy({ $0.count == 2 && $0.allSatisfy({ $0.isFinite && abs($0) <= 0.2 }) }) else { return nil }
        let mean=(0..<2).map { axis in samples.reduce(0) { $0+$1[axis] }/Double(samples.count) }
        guard samples.allSatisfy({ abs($0[0]-mean[0]) <= 0.03 && abs($0[1]-mean[1]) <= 0.03 }) else { return nil }
        return mean
    }
    static func corrected(_ value: Double, center: Double) -> Double {
        guard value.isFinite, center.isFinite, abs(center) <= 0.2 else { return 0 }
        let bounded=min(1,max(-1,value))
        return min(1,max(-1,(bounded-center)/(bounded >= center ? 1-center : 1+center)))
    }
}
// End calibration policy.

/// Controller-instance scope prevents calibrating one pad from affecting another.
@objcMembers final class TVControllerCalibration: NSObject {
    static let shared=TVControllerCalibration()
    private let centers=NSMapTable<GCController,NSArray>.weakToStrongObjects()
    private let lock=NSLock()
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self,selector:#selector(disconnected(_:)),name:.GCControllerDidDisconnect,object:nil)
    }
    @objc private func disconnected(_ notification:Notification) {
        guard let controller=notification.object as? GCController else { return }
        reset(controller)
    }
    func corrected(_ controller:GCController?, value:Double, axis:Int) -> Double {
        guard let controller, (0..<4).contains(axis) else { return value }
        lock.lock();let center=(centers.object(forKey:controller)?[axis] as? NSNumber)?.doubleValue ?? 0;lock.unlock()
        return TVCalibrationPolicy.corrected(value,center:center)
    }
    @nonobjc func apply(_ values:[Double], controller:GCController, right:Bool) {
        lock.lock();defer {lock.unlock()}
        var previous=(centers.object(forKey:controller) as? [Double]) ?? [0,0,0,0]
        let offset=right ? 2:0;previous[offset]=values[0];previous[offset+1]=values[1]
        centers.setObject(previous as NSArray,forKey:controller)
    }
    func reset(_ controller:GCController) {lock.lock();centers.removeObject(forKey:controller);lock.unlock()}
}

final class TVCalibrationController:TVDarkTableController {
    private var timer:Timer?
    private weak var target:GCController?
    private var samples:[[Double]]=[]
    private var status="Leave the sticks untouched for two seconds. Calibration lasts until this controller disconnects.".localized
    private var wasSuspended=true, keyboardWasSuspended=true
    private weak var support:ControllerSupport?
    override func viewDidLoad() {
        super.viewDidLoad();title="Stick center calibration".localized
        support=ControllerSupport.sharedInstance();wasSuspended=support?.forwardingSuspended ?? true
        keyboardWasSuspended=KeyboardSupport.forwardingSuspended()
        support?.forwardingSuspended=true;KeyboardSupport.setForwardingSuspended(true)
        tableView.backgroundColor=UIColor(white:0.04,alpha:1);tableView.rowHeight=100
        navigationItem.rightBarButtonItem=UIBarButtonItem(title:"Done".localized,style:.done,target:self,action:#selector(close))
    }
    override func viewDidDisappear(_ animated:Bool) {
        super.viewDidDisappear(animated);timer?.invalidate();timer=nil
        support?.forwardingSuspended=wasSuspended;KeyboardSupport.setForwardingSuspended(keyboardWasSuspended)
    }
    override func tableView(_ tableView:UITableView,numberOfRowsInSection section:Int)->Int {3}
    override func tableView(_ tableView:UITableView,titleForHeaderInSection section:Int)->String? {status}
    override func tableView(_ tableView:UITableView,cellForRowAt path:IndexPath)->UITableViewCell {
        let cell=TVCapabilityCell(style:.default,reuseIdentifier:nil)
        cell.textLabel?.text=["Calibrate left stick","Calibrate right stick","Reset stick calibration"][path.row].localized
        cell.textLabel?.textColor = .white;cell.backgroundColor=UIColor(white:0.09,alpha:1);return cell
    }
    override func tableView(_ tableView:UITableView,didSelectRowAt path:IndexPath) {
        guard timer == nil else {return}
        guard let controller=GCController.controllers().first(where:{$0.extendedGamepad != nil}) else {status="No compatible controller connected".localized;tableView.reloadData();return}
        if path.row == 2 {TVControllerCalibration.shared.reset(controller);status="Stick calibration reset.".localized;tableView.reloadData();return}
        target=controller;samples=[];status="Sampling. Do not touch the sticks.".localized;tableView.reloadData()
        let right=path.row == 1
        timer=Timer.scheduledTimer(withTimeInterval:0.05,repeats:true) { [weak self,weak controller] _ in
            guard let self else {return}
            guard let controller, GCController.controllers().contains(where:{$0 === controller}), let pad=controller.extendedGamepad else {self.finish(nil,right:right);return}
            let stick=right ? pad.rightThumbstick:pad.leftThumbstick
            self.samples.append([Double(stick.xAxis.value),Double(stick.yAxis.value)])
            if self.samples.count >= 40 {self.finish(TVCalibrationPolicy.center(self.samples),right:right)}
        }
    }
    private func finish(_ center:[Double]?,right:Bool) {
        timer?.invalidate();timer=nil
        if let center, let target {TVControllerCalibration.shared.apply(center,controller:target,right:right);status="Center calibrated. Previous deadzone settings are unchanged.".localized}
        else {status="Calibration failed: controller disconnected, stick moved or drift was too large. Previous calibration was kept.".localized}
        tableView.reloadData()
    }
    @objc private func close() {dismiss(animated:true)}
    override func pressesBegan(_ presses:Set<UIPress>,with event:UIPressesEvent?) {if presses.contains(where:{$0.type == .menu}) {return};super.pressesBegan(presses,with:event)}
    override func pressesEnded(_ presses:Set<UIPress>,with event:UIPressesEvent?) {if presses.contains(where:{$0.type == .menu}) {close();return};super.pressesEnded(presses,with:event)}
}

struct TVOverlayGeometry {
    static func frame(bounds:CGRect,size:CGSize,position:Int)->CGRect {
        let width=min(max(0,size.width),max(0,bounds.width)), height=min(max(0,size.height),max(0,bounds.height))
        let x:CGFloat, y:CGFloat
        switch position {
        case 1,3:x=bounds.minX
        case 2,4:x=bounds.maxX-width
        default:x=bounds.midX-width/2
        }
        y=(position == 3 || position == 4) ? bounds.maxY-height:bounds.minY
        return CGRect(x:x,y:y,width:width,height:height)
    }
}
// End overlay geometry.
@objcMembers final class TVOverlayPlacement:NSObject {
    static func frame(_ bounds:CGRect,size:CGSize,position:Int)->CGRect {TVOverlayGeometry.frame(bounds:bounds,size:size,position:position)}
}

// Diagnostics use numeric allowlists and fixed codec names, never raw host strings.
struct TVDiagnosticDocument:Encodable {
    let version=1
    let active:Bool
    let measurements:[String:Double]
    let codec:String
    let hdr:String
    static let ranges:[String:ClosedRange<Double>]=["width":1...16384,"height":1...16384,"receivedFPS":0...1000,"decodeMS":0...100000,"renderDroppedFrames":0...1e12,"audioChannels":1...32,"receivedMbps":0...10000,"networkDroppedFrames":0...1e12,"rttMS":0...100000,"hardwareAcceleration":0...1]
    init(active:Bool,measurements:[String:Double],codec:String?,hdr:Bool?) {
        self.active=active
        self.measurements=active ? measurements.filter { key,value in Self.ranges[key]?.contains(value) == true && value.isFinite } : [:]
        self.codec=active && ["H.264","H.264 YUV444","HEVC","HEVC YUV444","HEVC Main 10 HDR","HEVC Main 10 SDR","HEVC Main 10 YUV444 HDR","HEVC Main 10 YUV444 SDR","AV1","AV1 YUV444","AV1 10-bit HDR","AV1 10-bit SDR","AV1 10-bit YUV444 HDR","AV1 10-bit YUV444 SDR"].contains(codec ?? "") ? codec! : "Unknown"
        self.hdr=active ? hdr.map {$0 ? "HDR10":"SDR"} ?? "Unknown" : "NotStarted"
    }
    func text() throws ->String {
        let encoder=JSONEncoder();encoder.outputFormatting=[.sortedKeys]
        return String(data:try encoder.encode(self),encoding:.utf8)!
    }
}
// End diagnostic schema.

struct TVConnectionRequest: Equatable {
    let width: Int, height: Int, fps: Int, codec: Int
    let hdr: Bool, fullRange: Bool
    func changes(from current: TVConnectionRequest) -> [String] {
        var changed: [String] = []
        if width != current.width || height != current.height { changed.append("Resolution") }
        if fps != current.fps { changed.append("Frame Rate") }
        if codec != current.codec { changed.append("Preferred Codec") }
        if hdr != current.hdr { changed.append("HDR") }
        if fullRange != current.fullRange { changed.append("Full Color Range") }
        return changed
    }
}

// End connection request policy.

@objcMembers final class TVLifecycle: NSObject {
    static let shared = TVLifecycle()
    private var lastApp: TemporaryApp?
    private weak var main: MainFrameViewController?
    @objc(backgroundFrom:) func background(from controller: StreamFrameViewController) {
        guard SeleneTVSession.shared.stream === controller else { return }
        main = controller.mainFrameViewcontroller
        lastApp = main?.sortedAppList.first { $0.id == controller.streamConfig.appID }
        controller.tvSetInputPaused(true)
        if let presented = controller.presentedViewController {
            presented.dismiss(animated:false) { controller.returnToMainFrame() }
        } else { controller.returnToMainFrame() }
    }
    func foreground() {
        guard let app = lastApp, let main else { return }; lastApp = nil
        guard TVClientPreferences.askReconnectOnReturn else { return }
        DispatchQueue.main.asyncAfter(deadline:.now()+0.4) { [weak main] in
            guard let main, UIApplication.shared.applicationState == .active,
                  main.viewIfLoaded?.window != nil, main.navigationController?.topViewController === main,
                  main.presentedViewController == nil, SeleneTVSession.shared.stream == nil else { return }
            let alert = UIAlertController(title:"Reconnect the last app?".localized,
                message:"The stream was disconnected in the background. Your PC app was left running.".localized,preferredStyle:.alert)
            alert.addAction(UIAlertAction(title:"Stay in app list".localized,style:.cancel))
            alert.addAction(UIAlertAction(title:"Reconnect".localized,style:.default) { _ in
                guard let current = main.sortedAppList.first(where: { $0.id == app.id && $0.host?.uuid == app.host?.uuid }), current.host?.state == .online else {
                    let error = UIAlertController(title:"PC unavailable".localized,message:"Select the PC again after it comes online.".localized,preferredStyle:.alert)
                    error.addAction(UIAlertAction(title:"OK".localized,style:.cancel));main.present(error,animated:true);return
                }
                main.launch(current)
            })
            main.present(alert,animated:true)
        }
    }
}

/// One owner for a stream's acknowledged bitrate and serialized host mutations.
@objcMembers final class SeleneTVSession: NSObject {
    static let shared = SeleneTVSession()
    private(set) weak var stream: StreamFrameViewController?
    private(set) var targetKbps = 0
    private(set) var requestedCodec = 0
    private(set) var initialKbps = 0
    @nonobjc private(set) var initialRequest: TVConnectionRequest?
    private(set) var pending = false
    private(set) var observedBitrateStatus: Int?
    fileprivate var generation = UUID()
    private let requests = DispatchQueue(label: "Selene.stream.bitrate")
    var returningFromSettings = false
    var nextFocus = "continue"
    @nonobjc private var backGate = TVBackGate()
    var lastMessage = ""
    var menuChanged: (() -> Void)?
    @nonobjc lazy var adaptive = TVAdaptiveController(session: self)

    func begin(_ controller: StreamFrameViewController) {
        guard stream !== controller else { return }
        requestedCodec = Int(DataManager().getSettings()?.preferredCodec ?? 0)
        initialKbps = Int(controller.streamConfig.bitRate)
        let saved=DataManager().getSettings()
        initialRequest = TVConnectionRequest(width:saved?.width.intValue ?? Int(controller.streamConfig.width),height:saved?.height.intValue ?? Int(controller.streamConfig.height),fps:saved?.framerate.intValue ?? Int(controller.streamConfig.frameRate),codec:requestedCodec,hdr:saved?.enableHdr ?? controller.streamConfig.enableHdr,fullRange:saved?.fullColorRange ?? controller.streamConfig.fullColorRange)
        observedBitrateStatus = nil
        TVMicrophoneBridge.begin()
        generation = UUID(); stream = controller
        targetKbps = Int(controller.streamConfig.bitRate)
        pending = false; lastMessage = ""; returningFromSettings = false; nextFocus = "continue"
        if !controller.streamConfig.controlOnly { adaptive.start() }
    }
    func end() {
        TVMicrophoneBridge.end()
        initialRequest = nil; observedBitrateStatus = nil
        adaptive.stop()
        generation = UUID(); pending = false; stream = nil
        returningFromSettings = false; menuChanged = nil
        KeyboardSupport.releaseAllKeys()
    }
    @nonobjc var reconnectChanges: [String] {
        guard let initialRequest, let saved = DataManager().getSettings() else { return [] }
        return initialRequest.changes(from:TVConnectionRequest(width:saved.width.intValue,height:saved.height.intValue,fps:saved.framerate.intValue,codec:Int(saved.preferredCodec),hdr:saved.enableHdr,fullRange:saved.fullColorRange))
    }
    @nonobjc var reconnectNotice: String {
        let changes = reconnectChanges
        return changes.isEmpty ? "" : LocalizationHelper.localizedString(forKey:"Reconnect to apply: %@. Disconnect keeps the PC app running.", changes.map { $0.localized }.joined(separator:", "))
    }
    func requestManual(_ kbps: Int, completion: @escaping (Bool, Int, Int) -> Void) {
        adaptive.manualOverride()
        request(kbps, saveManual: true, completion: completion)
    }
    func request(_ kbps: Int, saveManual: Bool, completion: @escaping (Bool, Int, Int) -> Void) {
        dispatchPrecondition(condition: .onQueue(.main))
        guard !pending, let controller = stream, !controller.streamConfig.controlOnly, let host = controller.mainFrameViewcontroller else {
            completion(false, targetKbps, -1); return
        }
        let requested = min(800_000, max(500, kbps))
        let previous = targetKbps
        if requested == previous {
            if saveManual { let data = DataManager(); data.retrieveSettings()?.bitrate = NSNumber(value:requested); data.saveData() }
            completion(true, previous, 200); return
        }
        pending = true; menuChanged?()
        let token = generation
        requests.async { [weak self, weak host] in
            let status = Int(host?.request(forBitrate: requested) ?? -1)
            DispatchQueue.main.async {
                guard let self, self.generation == token, self.stream != nil else { return }
                self.pending = false
                self.observedBitrateStatus = status
                if status == 200 {
                    self.targetKbps = requested
                    host?.updateRequestedBitrate(Int32(requested))
                    if saveManual {
                        let data = DataManager()
                        data.retrieveSettings()?.bitrate = NSNumber(value: requested)
                        data.saveData()
                    }
                    self.lastMessage = ""
                } else {
                    self.lastMessage = LocalizationHelper.localizedString(forKey: "Host rejected the request (status %d). Kept %.1f Mbps.", status, Double(previous) / 1000)
                }
                completion(status == 200, self.targetKbps, status)
                self.menuChanged?()
            }
        }
    }
    @objc(showMenuFrom:) func showMenu(from controller: StreamFrameViewController) {
        guard controller.presentedViewController == nil, controller.view.window != nil, acceptBack() else { return }
        if stream !== controller { begin(controller) }
        if !returningFromSettings && nextFocus != "settings" { nextFocus = "continue" }
        controller.tvSetInputPaused(true)
        let menu = TVStreamMenuController(session: self)
        controller.present(menu, animated: true)
    }
    func blockDuplicateBack() { backGate.block(ProcessInfo.processInfo.systemUptime) }
    func acceptBack() -> Bool { backGate.accept(ProcessInfo.processInfo.systemUptime) }
    func settingsDidClose() {
        guard returningFromSettings, let stream else { return }
        returningFromSettings = false; nextFocus = "settings"
        showMenu(from: stream)
    }
}

final class TVStreamButton: UIButton {
    private let action: () -> Void
    init(_ title: String, action: @escaping () -> Void) {
        self.action = action; super.init(frame: .zero)
        setTitle(title, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 25, weight: .medium)
        titleLabel?.adjustsFontSizeToFitWidth = true
        titleLabel?.minimumScaleFactor = 0.65
        layer.cornerRadius = 18
        heightAnchor.constraint(equalToConstant: 68).isActive = true
        addTarget(self, action: #selector(run), for: .primaryActionTriggered)
        paint()
    }
    required init?(coder: NSCoder) { fatalError() }
    @objc private func run() { action() }
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        coordinator.addCoordinatedAnimations({ self.paint() }, completion: nil)
    }
    private func paint() {
        backgroundColor = isFocused ? .white : UIColor(white: 0.17, alpha: 1)
        setTitleColor(isFocused ? .black : .white, for: .normal)
        transform = isFocused ? CGAffineTransform(scaleX: 1.03, y: 1.03) : .identity
        layer.shadowOpacity = isFocused ? 0.25 : 0
    }
}

func tvStreamLabel(_ text: String, size: CGFloat = 24) -> UILabel {
    let label = UILabel(); label.text = text; label.textColor = .white
    label.font = .systemFont(ofSize: size, weight: .medium); label.numberOfLines = 0
    return label
}

final class TVStreamMenuController: UIViewController {
    let session: SeleneTVSession
    private var buttons: [String: UIButton] = [:]
    private var bitrateButtons: [UIButton] = []
    private let status = tvStreamLabel("", size: 22)
    private let bitrate = tvStreamLabel("", size: 38)
    private let received = tvStreamLabel("", size: 22)
    private var timer: Timer?
    private var disconnecting = false
    private let left = UIStackView()
    private let right = UIStackView()
    init(session: SeleneTVSession) {
        self.session = session; super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }
    required init?(coder: NSCoder) { fatalError() }
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        buttons[session.nextFocus].map { [$0] } ?? buttons["continue"].map { [$0] } ?? super.preferredFocusEnvironments
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        let panel = UIView(); panel.backgroundColor = UIColor(white: 0.055, alpha: 0.98)
        panel.layer.cornerRadius = 32; panel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(panel)
        let heading = tvStreamLabel("Stream menu".localized, size: 40)
        let scrolls = [left,right].map { stack -> UIScrollView in
            let scroll=UIScrollView();scroll.clipsToBounds=true;scroll.contentInset=UIEdgeInsets(top:8,left:8,bottom:8,right:8)
            stack.translatesAutoresizingMaskIntoConstraints=false;scroll.addSubview(stack)
            NSLayoutConstraint.activate([
                stack.leadingAnchor.constraint(equalTo:scroll.contentLayoutGuide.leadingAnchor),
                stack.trailingAnchor.constraint(equalTo:scroll.contentLayoutGuide.trailingAnchor),
                stack.topAnchor.constraint(equalTo:scroll.contentLayoutGuide.topAnchor),
                stack.bottomAnchor.constraint(equalTo:scroll.contentLayoutGuide.bottomAnchor),
                stack.widthAnchor.constraint(equalTo:scroll.frameLayoutGuide.widthAnchor,constant:-16)
            ])
            return scroll
        }
        let columns = UIStackView(arrangedSubviews: scrolls); columns.axis = .horizontal
        columns.spacing = 65; columns.distribution = .fillEqually
        for stack in [left, right] { stack.axis = .vertical; stack.spacing = 18 }
        let content = UIStackView(arrangedSubviews: [heading, columns]); content.axis = .vertical
        content.spacing = 32; content.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(content)
        NSLayoutConstraint.activate([
            panel.centerXAnchor.constraint(equalTo: view.centerXAnchor), panel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            panel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.83),
            panel.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.88),
            content.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 45),
            content.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -45),
            content.topAnchor.constraint(equalTo: panel.topAnchor, constant: 38),
            content.bottomAnchor.constraint(equalTo: panel.bottomAnchor, constant: -38)
        ])
        add("continue", "Continue streaming") { [weak self] in self?.resume() }
        add("stats", "Performance statistics") { [weak self] in self?.chooseStats() }
        add("settings", "Stream settings") { [weak self] in
            guard let self else { return }; self.session.returningFromSettings = true
            self.dismiss(animated: true) { self.session.stream?.tvPresentSettings() }
        }
        if TVClientPreferences.shortcutVisible("capabilities") { add("capabilities", "Capability report") { [weak self] in
            guard let self else { return }; self.session.nextFocus = "capabilities"
            self.present(UINavigationController(rootViewController: TVStreamCapabilityController()), animated: true)
        }
        }
        add("hostDisplay", "Host controls") { [weak self] in self?.chooseHostControls() }
        add("keys", "Keyboard shortcuts") { [weak self] in self?.chooseKeys() }
        add("disconnect", "Disconnect stream") { [weak self] in self?.disconnect(closeApp: false) }
        add("quit", "Disconnect and close app") { [weak self] in self?.confirmQuit() }
        right.addArrangedSubview(tvStreamLabel("Bitrate".localized, size: 28))
        right.addArrangedSubview(bitrate); right.addArrangedSubview(received)
        let minus = TVStreamButton("−") { [weak self] in self?.step(-1) }
        let plus = TVStreamButton("+") { [weak self] in self?.step(1) }
        let row = UIStackView(arrangedSubviews: [minus, plus]); row.axis = .horizontal
        row.distribution = .fillEqually; row.spacing = 20
        right.addArrangedSubview(row)
        let exact = TVStreamButton("Enter exact bitrate".localized) { [weak self] in
            guard let self else { return }
            TVStreamEditors.presentBitrate(on: self, kbps: self.session.targetKbps) { [weak self] value in self?.apply(value) }
        }
        right.addArrangedSubview(exact); bitrateButtons = [minus, plus, exact]
        right.addArrangedSubview(TVStreamButton("Picture layout".localized) { [weak self] in self?.present(TVStreamLayoutController(),animated:true) })
        right.addArrangedSubview(TVStreamButton("Adaptive bitrate".localized) { [weak self] in self?.present(TVAdaptiveSettingsController(), animated:true) })
        let mouse = TVStreamButton("Controller mouse".localized) { [weak self] in
            guard let self, let support = ControllerSupport.sharedInstance() else { return }
            guard GCController.controllers().contains(where: { $0.extendedGamepad != nil }) else {
                let alert = UIAlertController(title: "Controller mouse".localized, message: "Connect a controller with two sticks to use mouse mode.".localized, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK".localized, style: .cancel)); self.present(alert, animated: true); return
            }
            support.tvMouseMode.toggle(); self.resume()
        }
        buttons["mouse"] = mouse; right.addArrangedSubview(mouse)
        right.addArrangedSubview(status); right.addArrangedSubview(UIView())
        left.addArrangedSubview(UIView())
        session.menuChanged = { [weak self] in self?.refresh() }
        refresh()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.refresh() }
        setNeedsFocusUpdate(); updateFocusIfNeeded()
    }
    override func viewDidDisappear(_ animated: Bool) { super.viewDidDisappear(animated); timer?.invalidate(); timer = nil }
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        if let id = buttons.first(where: { $0.value === context.nextFocusedView })?.key { session.nextFocus = id }
    }
    private func add(_ id: String, _ key: String, action: @escaping () -> Void) {
        let button = TVStreamButton(key.localized, action: action); buttons[id] = button; left.addArrangedSubview(button)
    }
    func refresh() {
        let mouseAvailable = GCController.controllers().contains { $0.extendedGamepad != nil }
        buttons["mouse"]?.setTitle("Controller mouse".localized + ": " + ((ControllerSupport.sharedInstance()?.tvMouseMode ?? false) ? "On".localized : "Off".localized), for: .normal)
        buttons["mouse"]?.isEnabled = mouseAvailable && !disconnecting
        buttons["mouse"]?.alpha = mouseAvailable ? 1 : 0.4
        let inputOnly = session.stream?.streamConfig.controlOnly == true
        bitrateButtons.forEach { $0.isEnabled = !inputOnly && !session.pending && !disconnecting }
        bitrate.text = String(format: "%.1f Mbps", Double(session.targetKbps) / 1000)
        received.text = LocalizationHelper.localizedString(forKey: "Received bitrate: %.1f Mbps", session.stream?.tvReceivedMbps() ?? 0)
        status.text = (session.pending ? "Applying bitrate…".localized : session.lastMessage) + "\n" + session.adaptive.statusText + "\n" + session.reconnectNotice
        if let dropped = session.stream?.tvStreamMeasurements()["renderDroppedFrames"] as? NSNumber, dropped.doubleValue > 0 {
            status.text = (status.text ?? "") + "\n" + "Render frame drops detected; automatic bitrate uses network measurements only.".localized
        }
        bitrateButtons.forEach { $0.isEnabled = !inputOnly && !session.pending && !disconnecting; $0.alpha = $0.isEnabled ? 1 : 0.4 }
    }
    func apply(_ kbps: Int) { session.requestManual(kbps) { [weak self] _, _, _ in self?.refresh() } }
    private func step(_ direction: Int) { apply(session.targetKbps + direction * (session.targetKbps <= 200_000 ? 10_000 : 25_000)) }
    private func closeMenu(_ completion: @escaping () -> Void) {
        if let child = presentedViewController {
            child.dismiss(animated: false) { self.closeMenu(completion) }
        } else { dismiss(animated: true, completion: completion) }
    }
    func resume() {
        guard !disconnecting else { return }
        session.blockDuplicateBack()
        KeyboardSupport.releaseAllKeys()
        session.nextFocus = "continue"
        closeMenu { self.session.stream?.tvSetInputPaused(false) }
    }
    private func disconnect(closeApp: Bool) {
        guard !disconnecting else { return }
        disconnecting = true
        buttons.values.forEach { $0.isEnabled = false }
        bitrateButtons.forEach { $0.isEnabled = false }
        guard !closeApp, TVClientPreferences.lockOnDisconnect, session.stream != nil else {
            closeMenu { self.session.stream?.tvDisconnectCloseApp(closeApp) }; return
        }
        let token = session.generation
        KeyboardSupport.performShortcut(withResult: [0x5B, 0x4C]) { [weak self] sent in
            guard let self, self.session.generation == token, self.session.stream != nil else { return }
            self.session.lastMessage = sent ? "Lock shortcut sent. The host does not confirm lock state.".localized : "Could not send the lock shortcut. Disconnecting without confirmed lock.".localized
            self.refresh()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                guard let self, self.session.generation == token else { return }
                self.closeMenu { self.session.stream?.tvDisconnectCloseApp(false) }
            }
        }
    }
    private var hostCommandPending=false
    private func chooseHostControls() {
        guard let stream=session.stream,let main=stream.mainFrameViewcontroller,let manager=main.tvHostHTTPManager() else {return}
        session.nextFocus="hostDisplay"
        let alert=UIAlertController(title:"Host controls".localized,message:TVMicrophoneBridge.status,preferredStyle:.actionSheet)
        alert.addAction(UIAlertAction(title:"Apply settings and reconnect".localized,style:.default) { [weak self] _ in self?.afterAlert { [weak self] in self?.confirmReconnect() } })
        alert.addAction(UIAlertAction(title:"Windows display scaling".localized,style:.default) { [weak self] _ in
            self?.afterAlert { [weak self] in self?.present(UINavigationController(rootViewController:TVDisplayScaleController(manager:manager)),animated:true) }
        })
        if #available(tvOS 17.0, *) {
            alert.addAction(UIAlertAction(title:"Select iPhone or iPad microphone".localized,style:.default) { [weak self] _ in self?.afterAlert { [weak self] in if let self {TVMicrophoneBridge.choose(on:self)} } })
            alert.addAction(UIAlertAction(title:"Mute / unmute microphone".localized,style:.default) { [weak self] _ in TVMicrophoneBridge.toggle();self?.session.lastMessage=TVMicrophoneBridge.status;self?.refresh() })
        }
        let commands=main.sortedAppList.first(where:{$0.id == stream.streamConfig.appID})?.hostCommands ?? []
        for command in commands {
            guard let name=command["name"],let id=command["id"] else {continue}
            alert.addAction(UIAlertAction(title:name,style:.default) { [weak self] _ in self?.afterAlert { [weak self] in self?.confirmHostCommand(manager,id:id,name:name) } })
        }
        if commands.isEmpty { alert.message=(alert.message ?? "")+"\n"+"No host-provided commands are advertised for this app.".localized }
        alert.addAction(UIAlertAction(title:"Cancel".localized,style:.cancel));present(alert,animated:true)
    }
    private func confirmHostCommand(_ manager:HttpManager,id:String,name:String) {
        let token=session.generation
        let alert=UIAlertController(title:name,message:"Run this host-provided command? The host confirms request acceptance, not completion.".localized,preferredStyle:.alert)
        alert.addAction(UIAlertAction(title:"Cancel".localized,style:.cancel))
        alert.addAction(UIAlertAction(title:"Run".localized,style:.default) { [weak self] _ in
            guard let self,self.session.generation==token,!self.session.pending,!self.hostCommandPending else {return}
            self.hostCommandPending=true
            self.session.lastMessage="Sending host command".localized;self.refresh()
            DispatchQueue.global(qos:.userInitiated).async { [weak self] in
                let status=manager.executeHostCommand(id)
                DispatchQueue.main.async { [weak self] in
                    guard let self,self.session.generation==token else {return}
                    self.hostCommandPending=false
                    self.session.lastMessage=status==200 ? "Host accepted the command request; completion is not confirmed.".localized : "Host command failed or timed out.".localized
                    self.refresh()
                }
            }
        });present(alert,animated:true)
    }
    private func confirmReconnect() {
        guard !disconnecting,!session.pending else { return }
        let alert=UIAlertController(title:"Apply settings and reconnect".localized,message:"The stream will briefly disconnect. Your PC app stays running; saved resolution, codec and HDR settings apply to the new connection.".localized,preferredStyle:.alert)
        alert.addAction(UIAlertAction(title:"Cancel".localized,style:.cancel))
        alert.addAction(UIAlertAction(title:"Reconnect".localized,style:.default) { [weak self] _ in
            guard let self,let stream=self.session.stream,let main=stream.mainFrameViewcontroller,
                  let app=main.sortedAppList.first(where:{$0.id == stream.streamConfig.appID}) else { return }
            self.disconnecting=true
            self.closeMenu {
                stream.returnToMainFrame()
                DispatchQueue.main.asyncAfter(deadline:.now()+0.7) { [weak main] in
                    guard let main,main.navigationController?.topViewController === main,main.presentedViewController == nil,UIApplication.shared.applicationState == .active,SeleneTVSession.shared.stream == nil else { return }
                    main.reloadStreamConfig();main.launch(app)
                }
            }
        })
        present(alert,animated:true)
    }
    private func sendShortcut(_ keys: [Int]) {
        closeMenu { [weak session] in
            guard let session, session.stream != nil else { return }
            let token = session.generation
            KeyboardSupport.performShortcut(keys.map { NSNumber(value: $0) }) { [weak session] in
                guard let session, session.generation == token else { return }
                session.stream?.tvSetInputPaused(false)
            }
        }
    }
    private func afterAlert(_ action: @escaping () -> Void) {
        if let alert = presentedViewController as? UIAlertController { alert.dismiss(animated:true, completion:action) }
        else { DispatchQueue.main.async(execute:action) }
    }
    private func chooseKeys() {
        session.nextFocus = "keys"
        let alert = UIAlertController(title: "Keyboard shortcuts".localized, message: nil, preferredStyle: .alert)
        for (id, title, keys) in [("altTab", "Alt+Tab", [0xA4,0x09]), ("windows", "Windows", [0x5B]), ("esc", "Esc", [0x1B]), ("enter", "Enter", [0x0D])] where TVClientPreferences.shortcutVisible(id) {
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in self?.sendShortcut(keys) })
        }
        if TVClientPreferences.shortcutVisible("text") { alert.addAction(UIAlertAction(title: "Text input".localized, style: .default) { [weak self] _ in
            guard let self else { return }
            self.afterAlert {
                let input = TVStreamTextInputController { [weak self] text in
                    guard let self, self.session.stream != nil else { return }
                    text.withCString { _ = LiSendUtf8TextEvent($0, UInt32(text.utf8.count)) }
                    self.resume()
                }
                self.present(input, animated: true)
            }
        })
        }
        alert.addAction(UIAlertAction(title: "Special keys".localized, style: .default) { [weak self] _ in
            guard let self else { return }; self.afterAlert { self.chooseSpecialKeys() }
        })
        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel)); present(alert, animated: true)
    }
    private func chooseSpecialKeys() {
        let alert = UIAlertController(title: "Special keys".localized, message: nil, preferredStyle: .alert)
        for (name, keys) in [("Ctrl+Alt+Delete",[0xA2,0xA4,0x2E]),("Win+L",[0x5B,0x4C]),("Tab",[0x09]),("Backspace",[0x08]),("F1",[0x70]),("F5",[0x74]),("F11",[0x7A]),("F12",[0x7B])] {
            alert.addAction(UIAlertAction(title: name, style: .default) { [weak self] _ in self?.sendShortcut(keys) })
        }
        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel)); present(alert, animated: true)
    }
    private func confirmQuit() {
        session.nextFocus = "quit"
        let alert = UIAlertController(title: "Close the app on your PC?".localized, message: "Unsaved progress may be lost.".localized, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel))
        alert.addAction(UIAlertAction(title: "Disconnect and close app".localized, style: .destructive) { [weak self] _ in self?.disconnect(closeApp: true) })
        present(alert, animated: true)
    }
    private func chooseStats() {
        session.nextFocus = "stats"
        let alert = UIAlertController(title: "Performance statistics".localized, message: nil, preferredStyle: .alert)
        for (value, key) in [(0, "Off"), (1, "Compact statistics"), (2, "Detailed statistics")] {
            alert.addAction(UIAlertAction(title: key.localized, style: .default) { [weak self] _ in self?.session.stream?.tvSetStats(value) })
        }
        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel)); present(alert, animated: true)
    }
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.contains(where: { $0.type == .menu }) { return }
        super.pressesBegan(presses, with: event)
    }
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.contains(where: { $0.type == .menu }) {
            if let child = presentedViewController { child.dismiss(animated: true); return }
            if session.acceptBack() { resume() }
            return
        }
        super.pressesEnded(presses, with: event)
    }
}
final class TVStreamTextInputController: UIViewController {
    private let input = UITextField()
    private let send: (String) -> Void
    init(send: @escaping (String) -> Void) {
        self.send = send; super.init(nibName: nil, bundle: nil); modalPresentationStyle = .fullScreen
    }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() {
        super.viewDidLoad(); view.backgroundColor = UIColor(white: 0.04, alpha: 1)
        input.placeholder = "Text input".localized; input.font = .systemFont(ofSize: 36)
        input.textColor = .white; input.backgroundColor = UIColor(white: 0.15, alpha: 1)
        input.heightAnchor.constraint(equalToConstant: 85).isActive = true
        input.autocorrectionType = .no; input.autocapitalizationType = .none
        let confirm = TVStreamButton("Send text".localized) { [weak self] in
            guard let self, let text = self.input.text, !text.isEmpty else { return }
            self.dismiss(animated: true) { self.send(text) }
        }
        let cancel = TVStreamButton("Cancel".localized) { [weak self] in self?.dismiss(animated: true) }
        let stack = UIStackView(arrangedSubviews: [tvStreamLabel("Text input".localized, size: 38), input, confirm, cancel])
        stack.axis = .vertical; stack.spacing = 30; stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([stack.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.55), stack.centerXAnchor.constraint(equalTo: view.centerXAnchor), stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)])
    }
    override var preferredFocusEnvironments: [UIFocusEnvironment] { [input] }
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.contains(where: { $0.type == .menu }) { return }; super.pressesBegan(presses, with: event)
    }
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.contains(where: { $0.type == .menu }) { dismiss(animated: true); return }; super.pressesEnded(presses, with: event)
    }
}
struct TVCapabilityValue {
    static func numeric(_ value: Double?, format: String, active: Bool, unknown: String, notStarted: String) -> String {
        guard active else { return notStarted }
        guard let value, value.isFinite, value >= 0 else { return unknown }
        return String(format: format, value)
    }
}

/// A snapshot preserves unknown values; device capability never substitutes for a stream result.
struct TVStreamCapabilitySnapshot {
    let sections: [(String, [(String, String)])]
    static func capture() -> TVStreamCapabilitySnapshot {
        let unknown = "Unknown".localized
        let notStarted = "Stream not started".localized
        let settings = DataManager().getSettings()
        let session = SeleneTVSession.shared
        let values = session.stream?.tvStreamMeasurements() as? [String: Any] ?? [:]
        func observed(_ key: String, format: String) -> String {
            TVCapabilityValue.numeric((values[key] as? NSNumber)?.doubleValue, format: format, active: session.stream != nil, unknown: unknown, notStarted: notStarted)
        }
        let mode = UIScreen.main.currentMode?.size
        let codecs = [("H.264", kCMVideoCodecType_H264), ("HEVC", kCMVideoCodecType_HEVC), ("AV1", kCMVideoCodecType_AV1)]
        let hardware = codecs.map { "\($0.0): " + (VTIsHardwareDecodeSupported($0.1) ? "Supported".localized : "Unavailable".localized) }.joined(separator: " · ")
        let display = mode.map { "\(Int($0.width)) × \(Int($0.height))" } ?? unknown
        let acceleration = (values["hardwareAcceleration"] as? NSNumber).map { $0.boolValue ? "Yes".localized : "No".localized } ?? (session.stream == nil ? notStarted : unknown)
        let hdr = (values["hdr"] as? NSNumber).map { $0.boolValue ? "HDR10" : "SDR" } ?? (session.stream == nil ? notStarted : unknown)
        let size: String
        if let w = values["width"] as? NSNumber, let h = values["height"] as? NSNumber, w.intValue > 0, h.intValue > 0 { size = "\(w.intValue) × \(h.intValue)" }
        else { size = session.stream == nil ? notStarted : unknown }
        let requestedWidth = session.stream.map { Int($0.streamConfig.width) } ?? settings?.width.intValue ?? 0
        let requestedHeight = session.stream.map { Int($0.streamConfig.height) } ?? settings?.height.intValue ?? 0
        let codec = ([0:"Automatic",1:"H.264",2:"HEVC",3:"AV1"][session.stream == nil ? Int(settings?.preferredCodec ?? 0) : session.requestedCodec] ?? "Unknown").localized
        let audio = AVAudioSession.sharedInstance()
        return TVStreamCapabilitySnapshot(sections: [
            ("Device capabilities".localized, [
                ("Display mode".localized, display),
                ("Maximum display refresh rate".localized, "\(UIScreen.main.maximumFramesPerSecond) Hz"),
                ("Current display HDR format".localized, unknown),
                ("Hardware decoder support".localized, hardware),
                ("HDR output capability".localized, Utils.hdrSupported() ? "Supported".localized : "Unavailable".localized),
                ("Audio session output channels".localized, audio.outputNumberOfChannels > 0 ? "\(audio.outputNumberOfChannels)" : unknown),
                ("Dolby Vision / Atmos".localized, "Not supported by this stream path".localized)]),
            ("Requested settings".localized, [
                ("Resolution".localized, "\(requestedWidth) × \(requestedHeight)"),
                ("Frame Rate".localized, "\(session.stream.map { Int($0.streamConfig.frameRate) } ?? settings?.framerate.intValue ?? 0) FPS"),
                ("Preferred Codec".localized, codec),
                ("HDR".localized, (session.stream?.streamConfig.enableHdr ?? settings?.enableHdr ?? false) ? "On".localized : "Off".localized),
                ("Initial requested bitrate".localized, String(format: "%.1f Mbps", Double(session.stream == nil ? settings?.bitrate.intValue ?? 0 : session.initialKbps)/1000)),
                ("Saved manual bitrate".localized, String(format:"%.1f Mbps",Double(settings?.bitrate.intValue ?? 0)/1000)),
                ("Current session target bitrate".localized, session.stream == nil ? notStarted : String(format:"%.1f Mbps",Double(session.targetKbps)/1000)),
                ("Pending connection changes".localized, session.stream == nil ? notStarted : session.reconnectChanges.isEmpty ? "None".localized : session.reconnectChanges.map { $0.localized }.joined(separator:", "))]),
            ("Negotiated stream".localized, [
                ("Input-only session".localized, session.stream == nil ? notStarted : session.stream?.streamConfig.controlOnly == true ? "On".localized : "Off".localized),
                ("Microphone forwarding".localized, TVMicrophoneBridge.status),
                ("Resolution".localized, size),
                ("Negotiated codec".localized, values["codec"] as? String ?? (session.stream == nil ? notStarted : unknown)),
                ("Video decode/output path".localized, session.stream == nil ? notStarted : values["decoder"] as? String ?? unknown),
                ("Hardware acceleration in use".localized, acceleration),
                ("HDR".localized, hdr),
                ("Received frame rate".localized, observed("receivedFPS", format:"%.2f FPS")),
                ("Decode time".localized, observed("decodeMS", format:"%.2f ms")),
                ("Generated interpolation frames".localized, observed("interpolatedFrames",format:"%.0f")),
                ("Interpolation processing time".localized, observed("interpolationMS",format:"%.2f ms")),
                ("Interpolation degraded for latency".localized, (values["interpolationDegraded"] as? NSNumber).map { $0.boolValue ? "Yes".localized : "No".localized } ?? (session.stream == nil ? notStarted : unknown)),
                ("Render frame drops".localized, observed("renderDroppedFrames", format:"%.0f")),
                ("Negotiated audio channels".localized, observed("audioChannels", format:"%.0f")),
                ("Received bitrate".localized, observed("receivedMbps", format:"%.1f Mbps")),
                ("Network frame drops".localized, observed("networkDroppedFrames", format:"%.0f")),
                ("Network RTT".localized, observed("rttMS", format:"%.1f ms"))])])
    }
}

private final class TVCapabilityCell: UITableViewCell {
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        coordinator.addCoordinatedAnimations {
            self.textLabel?.textColor = self.isFocused ? .black : .white
            self.detailTextLabel?.textColor = self.isFocused ? .darkGray : .lightGray
        }
    }
}

final class TVStreamCapabilityController: TVDarkTableController {
    private var snapshot = TVStreamCapabilitySnapshot.capture()
    private var refreshTimer: Timer?
    override func viewDidLoad() {
        super.viewDidLoad(); title = "Capability report".localized
        tableView.backgroundColor = UIColor(white: 0.04, alpha: 1)
        tableView.rowHeight = 95
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done".localized, style: .done, target:self, action:#selector(close))
    }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); snapshot = .capture(); tableView.reloadData() }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshTimer = Timer.scheduledTimer(withTimeInterval:1, repeats:true) { [weak self] _ in
            guard let self else { return }; self.snapshot = .capture()
            for path in self.tableView.indexPathsForVisibleRows ?? [] {
                self.tableView.cellForRow(at:path)?.detailTextLabel?.text = self.snapshot.sections[path.section].1[path.row].1
            }
        }
    }
    override func viewDidDisappear(_ animated: Bool) { super.viewDidDisappear(animated); refreshTimer?.invalidate(); refreshTimer = nil }

    override func numberOfSections(in tableView: UITableView) -> Int { snapshot.sections.count }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { snapshot.sections[section].1.count }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { snapshot.sections[section].0 }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = TVCapabilityCell(style:.subtitle, reuseIdentifier:nil)
        let row = snapshot.sections[indexPath.section].1[indexPath.row]
        cell.textLabel?.text = row.0; cell.detailTextLabel?.text = row.1
        cell.detailTextLabel?.numberOfLines = 2
        cell.textLabel?.font = .systemFont(ofSize:25); cell.detailTextLabel?.font = .systemFont(ofSize:21)
        cell.backgroundColor = UIColor(white:0.1, alpha:1); cell.textLabel?.textColor = .white; cell.detailTextLabel?.textColor = .lightGray
        return cell
    }
    @objc private func close() { navigationController?.dismiss(animated:true) }
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.contains(where:{$0.type == .menu}) { return }; super.pressesBegan(presses,with:event)
    }
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.contains(where:{$0.type == .menu}) { close(); return }; super.pressesEnded(presses,with:event)
    }
}


enum TVHostExtensionEvidence: Equatable {
    case unverified, accepted, unavailable, failed(Int)
    static func bitrate(_ status: Int?) -> TVHostExtensionEvidence {
        guard let status else {return .unverified}
        if status == 200 {return .accepted}
        if status == 404 || status == 501 {return .unavailable}
        return .failed(status)
    }
}
// End host extension evidence.

// Only host-advertised Windows scaling presets are selectable.
struct TVDisplayScalePolicy {
    let current: Int?
    let options: [Int]
    init?(_ json: [String: Any]?, status: Int) {
        guard status == 200, let json,
              let code = json["status_code"] as? NSNumber, code.intValue == 200,
              let supported = json["scale_set_supported"] as? Bool, supported,
              let values = json["supported_scale_percents"] as? [NSNumber], !values.isEmpty,
              values.count <= 32, values.allSatisfy({ $0.doubleValue.isFinite && $0.doubleValue == Double($0.intValue) && (50...500).contains($0.intValue) }) else { return nil }
        options = Array(Set(values.map(\.intValue))).sorted()
        if let value = json["current_scale_percent"] as? NSNumber, value.doubleValue == Double(value.intValue), options.contains(value.intValue) { current = value.intValue } else { current = nil }
    }
}
// End display scale policy.

final class TVDisplayScaleController: TVDarkTableController {
    private let manager: HttpManager
    private let sessionToken = SeleneTVSession.shared.generation
    private var policy: TVDisplayScalePolicy?
    private var busy = false
    private var message = "Reading host display scaling".localized
    init(manager: HttpManager) { self.manager = manager; super.init(style:.grouped) }
    required init?(coder:NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewDidLoad() {
        super.viewDidLoad(); title = "Windows display scaling".localized
        tableView.backgroundColor = UIColor(white:0.04,alpha:1);tableView.rowHeight=UITableView.automaticDimension;tableView.estimatedRowHeight=140
        navigationItem.rightBarButtonItem=UIBarButtonItem(title:"Done".localized,style:.done,target:self,action:#selector(close))
        read()
    }
    private func valid() -> Bool { SeleneTVSession.shared.generation == sessionToken && viewIfLoaded?.window != nil }
    private func read() {
        busy=true;tableView.reloadData()
        manager.requestDisplayScale(nil) { [weak self] json,status in
            guard let self, self.valid() else { return }
            self.busy=false;self.policy=TVDisplayScalePolicy(json as? [String:Any],status:Int(status))
            self.message = self.policy == nil ? "Display scaling is unavailable or the host response could not be verified.".localized : "Choose a host-supported scaling preset. This changes the PC display, not the stream resolution.".localized
            self.tableView.reloadData()
        }
    }
    override func tableView(_ tableView:UITableView,numberOfRowsInSection section:Int)->Int { (policy?.options.count ?? 0)+1 }
    override func tableView(_ tableView:UITableView,cellForRowAt path:IndexPath)->UITableViewCell {
        let cell=TVCapabilityCell(style:.subtitle,reuseIdentifier:nil);cell.backgroundColor=UIColor(white:0.09,alpha:1)
        cell.textLabel?.textColor = .white;cell.detailTextLabel?.textColor = .lightGray;cell.detailTextLabel?.numberOfLines=3
        if path.row == 0 { cell.textLabel?.text = message;cell.textLabel?.numberOfLines=0;cell.detailTextLabel?.text=policy?.current.map { "\($0)%" };cell.selectionStyle = .none }
        else if let policy { let value=policy.options[path.row-1];cell.textLabel?.text="\(value)%";cell.accessoryType=policy.current == value ? .checkmark : .none }
        cell.isUserInteractionEnabled = !busy && path.row > 0
        return cell
    }
    override func tableView(_ tableView:UITableView,didSelectRowAt path:IndexPath) {
        guard !busy, path.row>0,let policy else { return }
        let value=policy.options[path.row-1]
        let alert=UIAlertController(title:"Change PC display scaling?".localized,message:"This changes Windows display scaling and may require signing out. Selene does not change it automatically.".localized,preferredStyle:.alert)
        alert.addAction(UIAlertAction(title:"Cancel".localized,style:.cancel))
        alert.addAction(UIAlertAction(title:"Apply".localized,style:.default) { [weak self] _ in self?.apply(value) })
        present(alert,animated:true)
    }
    private func apply(_ value:Int) {
        guard valid(),!busy,policy?.options.contains(value) == true else { return }
        busy=true;message="Applying host display scaling".localized;tableView.reloadData()
        manager.requestDisplayScale(NSNumber(value:value)) { [weak self] json,status in
            guard let self,self.valid() else { return }
            self.busy=false
            let data=json as? [String:Any]
            let verified=Int(status)==200 && (data?["status_code"] as? NSNumber)?.intValue==200 && (data?["success"] as? Bool)==true
            if verified, let actual=data?["current_scale_percent"] as? NSNumber,actual.intValue==value {
                self.message=(data?["restart_required"] as? Bool)==true ? "Host accepted scaling. Windows sign-out may be required.".localized : "Host reports the requested display scaling.".localized
                self.policy=TVDisplayScalePolicy(data,status:200) ?? self.policy
                // Read-back is independent evidence; a POST acceptance alone is not output verification.
                self.busy=true
                self.manager.requestDisplayScale(nil) { [weak self] json,status in
                    guard let self,self.valid() else { return };self.busy=false
                    self.policy=TVDisplayScalePolicy(json as? [String:Any],status:Int(status))
                    if self.policy?.current != value { self.message="Scaling request accepted, but read-back does not confirm the requested value.".localized }
                    self.tableView.reloadData()
                }
            } else { self.message="Could not confirm display scaling. The previous selection was preserved.".localized }
            self.tableView.reloadData()
        }
    }
    @objc private func close() { dismiss(animated:true) }
}

// A 48 kHz mono packet is exactly 20 ms; queued capture is bounded to 100 ms.
struct TVMicrophoneFrames {
    private(set) var pending=[Float]()
    mutating func append(_ values:[Float]) -> [[Float]] {
        guard values.allSatisfy({$0.isFinite}) else {pending.removeAll();return []}
        if pending.count+values.count>4800 {pending.removeAll()}
        pending.append(contentsOf:values.suffix(4800))
        var result=[[Float]]()
        while pending.count>=960 {result.append(Array(pending.prefix(960)));pending.removeFirst(960)}
        return result
    }
}
// End microphone frame policy.

@objcMembers final class TVMicrophoneBridge: NSObject {
    static var shouldRequest: Bool {
        if #available(tvOS 17.0, *) { return TVContinuityMicrophone.shared.ready }; return false
    }
    static var status: String {
        if #available(tvOS 17.0, *) { return TVContinuityMicrophone.shared.message }; return "Unavailable on this device".localized
    }
    static func choose(on controller:UIViewController) {
        if #available(tvOS 17.0, *) { TVContinuityMicrophone.shared.choose(on:controller) }
    }
    static func begin() {
        if #available(tvOS 17.0, *) { TVContinuityMicrophone.shared.end() }
    }
    static func setNegotiated(_ accepted:Bool) {
        if #available(tvOS 17.0, *) { TVContinuityMicrophone.shared.established(accepted) }
    }
    static func toggle() {
        if #available(tvOS 17.0, *) { TVContinuityMicrophone.shared.toggle() }
    }
    static func quiesce() {
        if #available(tvOS 17.0, *) { TVContinuityMicrophone.shared.quiesce() }
    }
    static func end() {
        if #available(tvOS 17.0, *) { TVContinuityMicrophone.shared.end() }
    }
}

@available(tvOS 17.0, *)
private final class TVContinuityMicrophone: NSObject, AVContinuityDevicePickerViewControllerDelegate {
    static let shared=TVContinuityMicrophone()
    private var device:AVContinuityDevice?
    private var engine:AVAudioEngine?
    private var routeObserver:NSObjectProtocol?
    private var interruptionObserver:NSObjectProtocol?
    private let lock=NSLock()
    private var sending=false
    private var captureGeneration=UUID()
    private var encoder:OpaquePointer?
    private var frames=TVMicrophoneFrames()
    var negotiated=false
    private(set) var message="Microphone off".localized
    var ready:Bool { device?.isConnected == true && !(device?.audioSessionInputs.isEmpty ?? true) && AVCaptureDevice.authorizationStatus(for:.audio) == .authorized }
    func choose(on controller:UIViewController) {
        guard AVContinuityDevicePickerViewController.isSupported else {message="Unavailable on this device".localized;return}
        // The system picker and permission prompt require an explicit user action.
        AVCaptureDevice.requestAccess(for:.audio) { [weak self,weak controller] granted in
            DispatchQueue.main.async {
                guard let self,let controller else {return}
                guard granted else {self.message="Microphone permission denied".localized;return}
                let picker=AVContinuityDevicePickerViewController();picker.delegate=self;picker.modalPresentationStyle = .fullScreen
                controller.present(picker,animated:true)
            }
        }
    }
    func continuityDevicePicker(_ pickerViewController:AVContinuityDevicePickerViewController,didConnect device:AVContinuityDevice) {
        end();self.device=device
        message="Microphone selected. Reconnect; capture starts muted.".localized
        pickerViewController.dismiss(animated:true)
    }
    func continuityDevicePickerDidCancel(_ pickerViewController:AVContinuityDevicePickerViewController) {pickerViewController.dismiss(animated:true)}
    func established(_ accepted:Bool) {
        if !accepted {stop()}
        negotiated=accepted
        message=accepted ? "Microphone muted".localized : "Host did not establish microphone forwarding".localized
    }
    func toggle() {
        if engine != nil { stop();message="Microphone muted".localized;return }
        guard negotiated,ready else {message="Select an iPhone or iPad microphone and reconnect to negotiate forwarding.".localized;return}
        do {
            let audio=AVAudioSession.sharedInstance()
            try audio.setCategory(.playAndRecord,mode:.default,options:[])
            try audio.setActive(true)
            guard let port=device?.audioSessionInputs.first else {throw NSError(domain:"SeleneMicrophone",code:1)}
            try audio.setPreferredInput(port)
            let engine=AVAudioEngine();let input=engine.inputNode;let format=input.outputFormat(forBus:0)
            guard format.sampleRate>0,format.channelCount>0,
                  let output=AVAudioFormat(commonFormat:.pcmFormatFloat32,sampleRate:48000,channels:1,interleaved:false),
                  let converter=AVAudioConverter(from:format,to:output) else {throw NSError(domain:"SeleneMicrophone",code:2)}
            var error:Int32=0
            guard let encoder=opus_encoder_create(48000,1,OPUS_APPLICATION_VOIP,&error),error==OPUS_OK else {throw NSError(domain:"SeleneMicrophone",code:3)}
            opus_encoder_ctl_wrapper(encoder,Int32(OPUS_SET_BITRATE_REQUEST),64000)
            lock.lock();self.encoder=encoder;sending=true;frames=TVMicrophoneFrames();lock.unlock()
            let captureToken=captureGeneration
            input.installTap(onBus:0,bufferSize:960,format:format) { [weak self] buffer,_ in
                guard let self else {return}
                self.lock.lock();defer {self.lock.unlock()}
                guard self.sending,let encoder=self.encoder else {return}
                let capacity=AVAudioFrameCount(ceil(Double(buffer.frameLength)*48000/format.sampleRate)+32)
                guard capacity<=8192,let converted=AVAudioPCMBuffer(pcmFormat:output,frameCapacity:capacity) else {return}
                var used=false;var conversionError:NSError?
                let state=converter.convert(to:converted,error:&conversionError) { _,status in
                    if used {status.pointee = .noDataNow;return nil};used=true;status.pointee = .haveData;return buffer
                }
                guard state != .error,conversionError == nil,let channel=converted.floatChannelData?[0] else {return}
                let values=UnsafeBufferPointer(start:channel,count:Int(converted.frameLength))
                guard values.allSatisfy({$0.isFinite}) else {return}
                for frame in self.frames.append(Array(values)) {
                    var packet=[UInt8](repeating:0,count:1275)
                    let count=opus_encode_float(encoder,frame,960,&packet,Int32(packet.count))
                    if count <= 0 || sendMicrophoneOpusData(packet,count) < 0 {
                        self.sending=false
                        DispatchQueue.main.async { [weak self] in
                            guard let self,self.captureGeneration==captureToken else {return}
                            self.stop();self.message="Microphone transport failed; capture stopped".localized
                        }
                        break
                    }
                }
            }
            self.engine=engine
            try engine.start()
            routeObserver=NotificationCenter.default.addObserver(forName:AVAudioSession.routeChangeNotification,object:nil,queue:.main) { [weak self] _ in
                guard let self else {return}
                if !self.ready || AVAudioSession.sharedInstance().currentRoute.inputs.first?.uid != self.device?.audioSessionInputs.first?.uid {self.stop();self.message="Microphone disconnected or audio route changed".localized}
            }
            interruptionObserver=NotificationCenter.default.addObserver(forName:AVAudioSession.interruptionNotification,object:nil,queue:.main) { [weak self] _ in
                self?.stop();self?.message="Microphone muted".localized
            }
            message="Microphone forwarding active".localized
        } catch {stop();message="Microphone could not start on this audio route".localized}
    }
    func quiesce() {lock.lock();sending=false;lock.unlock()}
    private func stop() {
        captureGeneration=UUID()
        lock.lock();sending=false;lock.unlock()
        engine?.stop();engine?.inputNode.removeTap(onBus:0);engine=nil
        if let routeObserver {NotificationCenter.default.removeObserver(routeObserver)};routeObserver=nil
        if let interruptionObserver {NotificationCenter.default.removeObserver(interruptionObserver)};interruptionObserver=nil
        lock.lock();if let encoder {opus_encoder_destroy(encoder)};encoder=nil;frames=TVMicrophoneFrames();lock.unlock()
        // Keep the active stream's output route; avoid changing it behind the user's back.
    }
    func end() {stop();negotiated=false;message=ready ? "Microphone selected. Reconnect; capture starts muted.".localized : "Microphone off".localized}
}

final class TVHostExtensionsController: TVDarkTableController {
    private var rows: [(String,String)] = []
    override func viewDidLoad() {
        super.viewDidLoad();title="Host extension report".localized;tableView.backgroundColor=UIColor(white:0.04,alpha:1);tableView.rowHeight=140
        navigationItem.rightBarButtonItem=UIBarButtonItem(title:"Done".localized,style:.done,target:self,action:#selector(close))
    }
    override func viewWillAppear(_ animated:Bool) {
        super.viewWillAppear(animated)
        let bitrate:String
        switch TVHostExtensionEvidence.bitrate(SeleneTVSession.shared.observedBitrateStatus) {
        case .unverified:bitrate="Not verified in this session".localized
        case .accepted:bitrate="A request was accepted in this session; this does not establish actual throughput.".localized
        case .unavailable:bitrate="The bitrate endpoint was unavailable in this session.".localized
        case let .failed(status):bitrate=LocalizationHelper.localizedString(forKey:"Request failed (status %d); support is unconfirmed.",status)
        }
        rows=[("Live bitrate",bitrate),
            ("Live resolution / HDR","Live resolution and HDR are not exposed. Apply settings and reconnect preserves the PC app.".localized),
            ("Host touch keyboard / Windows DPI","Display scaling is queried from the host. Keyboard commands appear only if the host advertises them.".localized),
            ("Monitor / render scaling / input-only","Monitor topology and input-only requests require the Foundation extension. Render scaling and capture-monitor selection remain unavailable.".localized),
            ("Microphone forwarding",TVMicrophoneBridge.status),
            ("Native interpolation",FrameInterpolator.deviceSupportsInterpolation ? "Device support detected; physical playback validation is still pending.".localized : "Unavailable on this device".localized)]
        tableView.reloadData()
    }
    override func tableView(_ tableView:UITableView,numberOfRowsInSection section:Int)->Int {rows.count}
    override func tableView(_ tableView:UITableView,titleForHeaderInSection section:Int)->String? {"Client negotiation evidence, not a claim about all Sunshine capabilities.".localized}
    override func tableView(_ tableView:UITableView,cellForRowAt path:IndexPath)->UITableViewCell {
        let cell=TVCapabilityCell(style:.subtitle,reuseIdentifier:nil);cell.backgroundColor=UIColor(white:0.09,alpha:1)
        cell.textLabel?.text=rows[path.row].0.localized;cell.textLabel?.textColor = .white
        cell.detailTextLabel?.text=rows[path.row].1;cell.detailTextLabel?.textColor = .lightGray;cell.detailTextLabel?.numberOfLines=3;return cell
    }
    @objc private func close() {dismiss(animated:true)}
    override func pressesBegan(_ presses:Set<UIPress>,with event:UIPressesEvent?) {if presses.contains(where:{$0.type == .menu}) {return};super.pressesBegan(presses,with:event)}
    override func pressesEnded(_ presses:Set<UIPress>,with event:UIPressesEvent?) {if presses.contains(where:{$0.type == .menu}) {close();return};super.pressesEnded(presses,with:event)}
}

final class TVHelpController: TVDarkTableController {
    private let guides: [(String, [String])] = [
        ("Siri Remote", ["Select a PC to open its apps. Use the arrows or swipe to move focus, and Select to open the focused item.", "During streaming, Back opens the stream menu; Back again resumes. In an input dialog, Back returns one level. Disconnect keeps the PC app running; Disconnect and close app requires confirmation.", "Use Stream settings to adjust options. Resolution and HDR changes require reconnecting. Exact bitrate entry accepts 0.5–800 Mbps; host acceptance does not guarantee actual throughput."]),
        ("Controller", ["Pair your controller in Apple TV settings. App pages use native tvOS navigation. Controller test displays buttons, combinations and sticks without forwarding them to the PC.", "Controller mouse uses the right stick to move, A/B for left/right click and the left stick to scroll. Enable it in the stream menu; it starts off each session. Back/Menu opens the stream menu."]),
        ("Pairing", ["Install and start Sunshine on your PC. Keep Apple TV and the PC on a reachable network, select or add the PC in Selene, then enter the displayed PIN in Sunshine. Never publish pairing codes or keys."]),
        ("Troubleshooting", ["If a PC is offline, check its power, network and Sunshine service. For a black screen, reconnect with SDR and a supported codec; AV1 requires hardware decoding.", "For stutter, compare network frame drops and RTT with decode/render statistics. Reduce bitrate or resolution when appropriate. The 800 Mbps limit is configurable, not a stability promise.", "For missing sound, check Apple TV audio settings and the TV/receiver route. This stream path supports Stereo, 5.1 and 7.1 when available, not Dolby Atmos or height channels."])
    ]
    override func viewDidLoad() {
        super.viewDidLoad(); title = "Help and diagnostics".localized
        tableView.backgroundColor = UIColor(white:0.04, alpha:1)
        tableView.rowHeight = UITableView.automaticDimension; tableView.estimatedRowHeight = 180
        navigationItem.rightBarButtonItem = UIBarButtonItem(title:"Done".localized, style:.done, target:self, action:#selector(close))
    }
    override func numberOfSections(in tableView: UITableView) -> Int { guides.count + 1 }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { section < guides.count ? guides[section].1.count : 6 }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { section < guides.count ? guides[section].0.localized : "Diagnostics and references".localized }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = TVCapabilityCell(style:.subtitle,reuseIdentifier:nil)
        cell.backgroundColor = UIColor(white:0.09,alpha:1); cell.textLabel?.textColor = .white
        cell.textLabel?.font = .systemFont(ofSize:25); cell.textLabel?.numberOfLines = 0
        if indexPath.section < guides.count { cell.textLabel?.text = guides[indexPath.section].1[indexPath.row].localized }
        else { cell.textLabel?.text = ["Capability report", "Host extension report", "Diagnostic QR code", "Project on GitHub", "Issue reporting", "Open-source licenses"][indexPath.row].localized; cell.accessoryType = .disclosureIndicator }
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == guides.count else { return }
        if indexPath.row == 0 { present(UINavigationController(rootViewController: TVStreamCapabilityController()),animated:true); return }
        if indexPath.row == 1 {present(UINavigationController(rootViewController:TVHostExtensionsController()),animated:true);return}
        if indexPath.row == 2 {
            let values=SeleneTVSession.shared.stream?.tvStreamMeasurements() as? [String:Any] ?? [:]
            let numbers=values.compactMapValues { ($0 as? NSNumber)?.doubleValue }
            let document=TVDiagnosticDocument(active:SeleneTVSession.shared.stream != nil,measurements:numbers,codec:values["codec"] as? String,hdr:(values["hdr"] as? NSNumber)?.boolValue)
            guard let code=try? document.text() else { return }
            present(TVBackupCodeController(code:code,heading:"Diagnostic QR code".localized,explanation:"Scan to copy this diagnostic snapshot. It contains only allowlisted stream measurements, no PC addresses, names or pairing secrets. Nothing is uploaded automatically.".localized),animated:true);return
        }
        let entries = [
            ("Project on GitHub", "https://github.com/jacobswin/Selene", "Scan with your phone to open the project."),
            ("Issue reporting", "https://github.com/jacobswin/Selene/issues", "Include device and host versions, stream settings and reproduction steps. Remove private addresses, pairing codes and account details before sharing."),
            ("Open-source licenses", "https://github.com/jacobswin/Selene/blob/main/LICENSE.txt", "Selene is GPLv3. Upstream copyright notices and dependency licenses are retained in the repository. No diagnostics are uploaded automatically.")]
        let entry = entries[indexPath.row-3]
        present(TVReferenceController(title:entry.0.localized, url:entry.1, explanation:entry.2.localized),animated:true)
    }
    @objc private func close() { dismiss(animated:true) }
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.contains(where:{$0.type == .menu}) { return }; super.pressesBegan(presses,with:event)
    }
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.contains(where:{$0.type == .menu}) { close(); return }; super.pressesEnded(presses,with:event)
    }
}

final class TVReferenceController: UIViewController {
    private let referenceTitle: String, url: String, explanation: String
    init(title: String, url: String, explanation: String) {
        referenceTitle=title; self.url=url; self.explanation=explanation
        super.init(nibName:nil,bundle:nil)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() {
        super.viewDidLoad(); view.backgroundColor = UIColor(white:0.04,alpha:1)
        let image = UIImageView(); image.contentMode = .scaleAspectFit
        image.widthAnchor.constraint(equalToConstant:320).isActive=true
        image.heightAnchor.constraint(equalToConstant:320).isActive=true
        if let filter = CIFilter(name:"CIQRCodeGenerator") {
            filter.setValue(Data(url.utf8),forKey:"inputMessage")
            filter.setValue("M",forKey:"inputCorrectionLevel")
            if let output=filter.outputImage?.transformed(by:CGAffineTransform(scaleX:10,y:10)), let pixels=CIContext().createCGImage(output,from:output.extent) { image.image=UIImage(cgImage:pixels) }
        }
        image.backgroundColor = .white; image.layer.magnificationFilter = .nearest
        let close = TVStreamButton("Done".localized) { [weak self] in self?.dismiss(animated:true) }
        let stack=UIStackView(arrangedSubviews:[tvStreamLabel(referenceTitle,size:38),tvStreamLabel(explanation),image,tvStreamLabel(url,size:21),close]);stack.axis = .vertical; stack.spacing=25
        stack.translatesAutoresizingMaskIntoConstraints=false;view.addSubview(stack)
        NSLayoutConstraint.activate([stack.centerXAnchor.constraint(equalTo:view.centerXAnchor),stack.centerYAnchor.constraint(equalTo:view.centerYAnchor),stack.widthAnchor.constraint(equalTo:view.widthAnchor,multiplier:0.65)])
    }
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.contains(where:{$0.type == .menu}) { return }; super.pressesBegan(presses,with:event)
    }
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.contains(where:{$0.type == .menu}) { dismiss(animated:true); return }; super.pressesEnded(presses,with:event)
    }
}

// Pure settings-backup schema. No arbitrary defaults or host objects are accepted.
struct TVBackupDocument: Codable, Equatable {
    var version: Int
    var video: [String:Int]
    var flags: [String:Bool]
    var client: [String:Int]
    var shortcuts: [String:Bool]
    var layout: [String:Double]
    enum Failure: Error { case invalid }
    static let videoRanges: [String:ClosedRange<Int>] = ["width":256...3840,"height":256...2160,"framerate":1...240,"bitrate":500...800000,"preferredCodec":0...3,"audioConfig":2...8,"framePacingMode":0...3,"frameQueueSize":0...5,"renderingBackend":0...1]
    static let clientRanges: [String:ClosedRange<Int>] = ["compactCovers":0...1,"lockOnDisconnect":0...1,"askReconnectOnReturn":0...1,"leftDeadzone":0...30,"rightDeadzone":0...30,"language":0...3]
    static let optionalClientRanges:[String:ClosedRange<Int>] = ["mouseSpeed":25...300,"scrollSpeed":25...300,"invertScroll":0...1,"statsPosition":0...4,"qualityWarnings":0...1,"monitorMode":(-1)...4,"inputOnly":0...1]
    static let shortcutIDs = ["altTab","windows","esc","enter","text","capabilities"]
    func validate(supportsHEVC: Bool = true) throws {
        guard version == 1, Set(video.keys) == Set(Self.videoRanges.keys), Set(Self.clientRanges.keys).isSubset(of:Set(client.keys)), Set(client.keys).isSubset(of:Set(Self.clientRanges.keys).union(Self.optionalClientRanges.keys)),
              Set(flags.keys) == Set(["enableHdr","fullColorRange","asyncFrameDequeue"]),
              Set(shortcuts.keys) == Set(Self.shortcutIDs), Set(layout.keys) == Set(["stretch","alignment","x","y"]),
              video.allSatisfy({ Self.videoRanges[$0.key]!.contains($0.value) }),
              client.allSatisfy({ (Self.clientRanges[$0.key] ?? Self.optionalClientRanges[$0.key])!.contains($0.value) }),
              video["width"]! % 2 == 0, video["height"]! % 2 == 0, [2,6,8].contains(video["audioConfig"]!),
              supportsHEVC || (video["width"]! <= 1920 && video["height"]! <= 1080),
              layout.values.allSatisfy({ $0.isFinite }), [0.0,1.0].contains(layout["stretch"]!),
              (0...8).contains(layout["alignment"]!), layout["alignment"]!.rounded() == layout["alignment"]!,
              abs(layout["x"]!) <= 50, abs(layout["y"]!) <= 50 else { throw Failure.invalid }
    }
    func code() throws -> String {
        try validate()
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(self)
        guard data.count <= 2048 else { throw Failure.invalid }
        return "SELENE1:" + data.base64EncodedString().replacingOccurrences(of:"+",with:"-").replacingOccurrences(of:"/",with:"_").replacingOccurrences(of:"=",with:"")
    }
    static func decode(_ input: String, supportsHEVC: Bool = true) throws -> TVBackupDocument {
        let code = input.trimmingCharacters(in:.whitespacesAndNewlines)
        guard code.count <= 4096, code.hasPrefix("SELENE1:") else { throw Failure.invalid }
        var payload = String(code.dropFirst(8)).replacingOccurrences(of:"-",with:"+").replacingOccurrences(of:"_",with:"/")
        payload += String(repeating:"=",count:(4-payload.count%4)%4)
        guard let data = Data(base64Encoded:payload), data.count <= 2048 else { throw Failure.invalid }
        let document = try JSONDecoder().decode(Self.self,from:data)
        try document.validate(supportsHEVC:supportsHEVC); return document
    }
}
// End settings-backup schema.

final class TVBackupController: TVDarkTableController {
    private let restored: (TVBackupDocument) -> Void
    init(restored: @escaping (TVBackupDocument) -> Void) { self.restored=restored;super.init(style:.plain) }
    required init?(coder:NSCoder) { fatalError() }
    override func viewDidLoad() {
        super.viewDidLoad(); title="Settings backup".localized;tableView.backgroundColor=UIColor(white:0.04,alpha:1);tableView.rowHeight=100
        navigationItem.rightBarButtonItem=UIBarButtonItem(title:"Done".localized,style:.done,target:self,action:#selector(close))
    }
    override func tableView(_ tableView:UITableView,numberOfRowsInSection section:Int)->Int { 2 }
    override func tableView(_ tableView:UITableView,titleForHeaderInSection section:Int)->String? { "Stream and UI settings only. Pairing, PC addresses and accounts are excluded.".localized }
    override func tableView(_ tableView:UITableView,cellForRowAt path:IndexPath)->UITableViewCell {
        let cell=TVCapabilityCell(style:.default,reuseIdentifier:nil);cell.textLabel?.text=["Export settings","Restore backup code"][path.row].localized
        cell.backgroundColor=UIColor(white:0.09,alpha:1);cell.textLabel?.textColor = .white;return cell
    }
    private func capture() throws -> TVBackupDocument {
        guard let settings=DataManager().getSettings() else { throw TVBackupDocument.Failure.invalid }
        let video = ["width":settings.width.intValue,"height":settings.height.intValue,"framerate":settings.framerate.intValue,"bitrate":settings.bitrate.intValue,"preferredCodec":Int(settings.preferredCodec),"audioConfig":settings.audioConfig.intValue == 3 ? 2 : settings.audioConfig.intValue,"framePacingMode":settings.framePacingMode.intValue,"frameQueueSize":settings.frameQueueSize.intValue,"renderingBackend":settings.renderingBackend.intValue]
        var client = ["compactCovers":TVClientPreferences.compactCovers ? 1:0,"lockOnDisconnect":TVClientPreferences.lockOnDisconnect ? 1:0,"askReconnectOnReturn":TVClientPreferences.askReconnectOnReturn ? 1:0,"leftDeadzone":TVClientPreferences.deadzone("left"),"rightDeadzone":TVClientPreferences.deadzone("right"),"language":Int(LocalizationHelper.languagePreference())]
        client.merge(["mouseSpeed":TVClientPreferences.mouseSpeed(false),"scrollSpeed":TVClientPreferences.mouseSpeed(true),"invertScroll":TVClientPreferences.invertScroll ? 1:0,"statsPosition":TVClientPreferences.statsPosition,"qualityWarnings":TVClientPreferences.qualityWarnings ? 1:0,"monitorMode":TVClientPreferences.monitorMode,"inputOnly":TVClientPreferences.inputOnly ? 1:0]) { _,new in new }
        let layout=TVStreamLayout.shared
        return TVBackupDocument(version:1,video:video,flags:["enableHdr":settings.enableHdr,"fullColorRange":settings.fullColorRange,"asyncFrameDequeue":settings.asyncFrameDequeue],client:client,shortcuts:Dictionary(uniqueKeysWithValues:TVBackupDocument.shortcutIDs.map { ($0,TVClientPreferences.shortcutVisible($0)) }),layout:["stretch":layout.stretch ? 1:0,"alignment":Double(layout.alignment),"x":layout.x,"y":layout.y])
    }
    override func tableView(_ tableView:UITableView,didSelectRowAt path:IndexPath) {
        if path.row == 0 {
            do { let code=try capture().code();present(TVBackupCodeController(code:code),animated:true) }
            catch { message("Unable to export these settings.") };return
        }
        guard SeleneTVSession.shared.stream == nil else { message("Disconnect the stream before restoring settings.");return }
        let input=UIAlertController(title:"Restore backup code".localized,message:"Paste the backup code using the iPhone Apple TV Remote keyboard.".localized,preferredStyle:.alert)
        input.addTextField { $0.placeholder="Backup code".localized;$0.autocorrectionType = .no;$0.autocapitalizationType = .none }
        input.addAction(UIAlertAction(title:"Cancel".localized,style:.cancel))
        input.addAction(UIAlertAction(title:"Preview".localized,style:.default) { [weak self,weak input] _ in
            guard let self else { return }
            let code=input?.textFields?.first?.text ?? ""
            DispatchQueue.main.asyncAfter(deadline:.now()+0.35) {
                do {
                    let document=try TVBackupDocument.decode(code,supportsHEVC:VTIsHardwareDecodeSupported(kCMVideoCodecType_HEVC))
                    self.confirm(document)
                } catch { self.message("Invalid or unsupported backup. Existing settings were kept.") }
            }
        });present(input,animated:true)
    }
    private func confirm(_ original: TVBackupDocument) {
        var document=original;var adjusted=false
        if document.video["preferredCodec"] == 3 && !VTIsHardwareDecodeSupported(kCMVideoCodecType_AV1) {document.video["preferredCodec"]=VTIsHardwareDecodeSupported(kCMVideoCodecType_HEVC) ? 2:1;adjusted=true}
        if document.video["preferredCodec"] == 2 && !VTIsHardwareDecodeSupported(kCMVideoCodecType_HEVC) {document.video["preferredCodec"]=1;adjusted=true}
        if document.flags["enableHdr"] == true && !Utils.hdrSupported() {document.flags["enableHdr"]=false;adjusted=true}
        if document.video["framePacingMode"] == 3 && !FrameInterpolator.deviceSupportsInterpolation {document.video["framePacingMode"]=2;adjusted=true}
        if document.video["preferredCodec"] == 3 && document.flags["fullColorRange"] == true {document.flags["fullColorRange"]=false;adjusted=true}
        let summary="\(document.video["width"]!) × \(document.video["height"]!) · \(document.video["framerate"]!) FPS · \(Double(document.video["bitrate"]!)/1000) Mbps"
        let alert=UIAlertController(title:"Restore these settings?".localized,message:summary+"\n"+(adjusted ? "Unsupported codec, HDR or interpolation settings were adjusted for this device.".localized : "Pairing and saved PCs will not change.".localized),preferredStyle:.alert)
        alert.addAction(UIAlertAction(title:"Cancel".localized,style:.cancel))
        alert.addAction(UIAlertAction(title:"Restore".localized,style:.default) { [weak self] _ in
            guard let self, SeleneTVSession.shared.stream == nil else {return}
            let data=DataManager();guard let settings=data.retrieveSettings() else {return}
            for (key,value) in document.video {settings.setValue(NSNumber(value:value),forKey:key)}
            settings.setValue(NSNumber(value:5),forKey:"resolutionSelected")
            for (key,value) in document.flags {settings.setValue(NSNumber(value:value),forKey:key)}
            data.saveData()
            TVClientPreferences.compactCovers=document.client["compactCovers"]==1
            TVClientPreferences.lockOnDisconnect=document.client["lockOnDisconnect"]==1
            TVClientPreferences.askReconnectOnReturn=document.client["askReconnectOnReturn"]==1
            TVClientPreferences.setDeadzone("left",value:document.client["leftDeadzone"]!);TVClientPreferences.setDeadzone("right",value:document.client["rightDeadzone"]!)
            if let value=document.client["mouseSpeed"] {TVClientPreferences.setMouseSpeed(false,value:value)}
            if let value=document.client["scrollSpeed"] {TVClientPreferences.setMouseSpeed(true,value:value)}
            if let value=document.client["invertScroll"] {TVClientPreferences.invertScroll=value == 1}
            if let value=document.client["statsPosition"] {TVClientPreferences.statsPosition=value}
            if let value=document.client["qualityWarnings"] {TVClientPreferences.qualityWarnings=value == 1}
            if let value=document.client["monitorMode"] {TVClientPreferences.monitorMode=value}
            if let value=document.client["inputOnly"] {TVClientPreferences.inputOnly=value == 1}
            for (id,value) in document.shortcuts {TVClientPreferences.setShortcutVisible(id,visible:value)}
            TVStreamLayout.shared.stretch=document.layout["stretch"]==1;TVStreamLayout.shared.alignment=Int(document.layout["alignment"]!)
            TVStreamLayout.shared.x=document.layout["x"]!;TVStreamLayout.shared.y=document.layout["y"]!
            LocalizationHelper.setLanguagePreference(document.client["language"]!)
            self.restored(document)
            DispatchQueue.main.asyncAfter(deadline:.now()+0.35) {self.message("Settings restored. Pairing and saved PCs were kept.")}
        });present(alert,animated:true)
    }
    private func message(_ text:String) {
        let alert=UIAlertController(title:"Settings backup".localized,message:text.localized,preferredStyle:.alert)
        alert.addAction(UIAlertAction(title:"OK".localized,style:.cancel));present(alert,animated:true)
    }
    @objc private func close() {dismiss(animated:true)}
    override func pressesBegan(_ presses:Set<UIPress>,with event:UIPressesEvent?) {if presses.contains(where:{$0.type == .menu}) {return};super.pressesBegan(presses,with:event)}
    override func pressesEnded(_ presses:Set<UIPress>,with event:UIPressesEvent?) {if presses.contains(where:{$0.type == .menu}) {close();return};super.pressesEnded(presses,with:event)}
}

final class TVBackupCodeController: UIViewController {
    private let code:String, heading:String, explanation:String
    init(code:String, heading:String="Export settings".localized, explanation:String="Scan and copy this backup code on your phone. Keep it for Restore backup code. It contains no pairing secrets or PC addresses.".localized) {self.code=code;self.heading=heading;self.explanation=explanation;super.init(nibName:nil,bundle:nil)}
    required init?(coder:NSCoder) {fatalError()}
    override func viewDidLoad() {
        super.viewDidLoad();view.backgroundColor=UIColor(white:0.04,alpha:1)
        let image=UIImageView();image.contentMode = .scaleAspectFit;image.backgroundColor = .white
        image.heightAnchor.constraint(equalToConstant:420).isActive=true
        if let filter=CIFilter(name:"CIQRCodeGenerator") {
            filter.setValue(Data(code.utf8),forKey:"inputMessage");filter.setValue("M",forKey:"inputCorrectionLevel")
            if let output=filter.outputImage?.transformed(by:CGAffineTransform(scaleX:5,y:5)),let pixels=CIContext().createCGImage(output,from:output.extent) {image.image=UIImage(cgImage:pixels)}
        }
        image.layer.magnificationFilter = .nearest
        let stack=UIStackView(arrangedSubviews:[tvStreamLabel(heading,size:36),image,tvStreamLabel(explanation,size:23),TVStreamButton("Done".localized) { [weak self] in self?.dismiss(animated:true) }]);stack.axis = .vertical;stack.spacing=25;stack.translatesAutoresizingMaskIntoConstraints=false
        view.addSubview(stack);NSLayoutConstraint.activate([stack.centerXAnchor.constraint(equalTo:view.centerXAnchor),stack.centerYAnchor.constraint(equalTo:view.centerYAnchor),stack.widthAnchor.constraint(equalTo:view.widthAnchor,multiplier:0.65)])
    }
    override func pressesBegan(_ presses:Set<UIPress>,with event:UIPressesEvent?) {if presses.contains(where:{$0.type == .menu}) {return};super.pressesBegan(presses,with:event)}
    override func pressesEnded(_ presses:Set<UIPress>,with event:UIPressesEvent?) {if presses.contains(where:{$0.type == .menu}) {dismiss(animated:true);return};super.pressesEnded(presses,with:event)}
}

// Pure geometry shared by rendering and absolute pointer conversion.
struct TVStreamGeometry {
    static func frame(container: CGSize, video: CGSize, stretch: Bool, alignment: Int, x: Double, y: Double) -> CGRect {
        guard container.width > 0, container.height > 0, video.width > 0, video.height > 0 else { return .zero }
        let scale = min(container.width/video.width, container.height/video.height)
        let size = stretch ? container : CGSize(width:video.width*scale, height:video.height*scale)
        let anchor = min(8,max(0,alignment))
        return CGRect(x:(container.width-size.width)*CGFloat(anchor%3)/2 + container.width*CGFloat(min(50,max(-50,x)))/100,
                      y:(container.height-size.height)*CGFloat(anchor/3)/2 + container.height*CGFloat(min(50,max(-50,y)))/100,
                      width:size.width,height:size.height)
    }
    static func inverse(point: CGPoint, frame: CGRect, video: CGSize, container: CGSize) -> CGPoint? {
        guard frame.width > 0, frame.height > 0, video.width > 0, video.height > 0,
              CGRect(origin:.zero,size:container).contains(point), frame.contains(point) else { return nil }
        return CGPoint(x:(point.x-frame.minX)*video.width/frame.width,y:(point.y-frame.minY)*video.height/frame.height)
    }
}
// End pure geometry.
@objcMembers final class TVStreamLayout: NSObject {
    static let shared = TVStreamLayout()
    private let defaults = UserDefaults.standard
    var stretch: Bool { get { defaults.bool(forKey:"Selene.layout.stretch") } set { defaults.set(newValue,forKey:"Selene.layout.stretch"); apply() } }
    var alignment: Int { get { defaults.object(forKey:"Selene.layout.anchor") == nil ? 4 : min(8,max(0,defaults.integer(forKey:"Selene.layout.anchor"))) } set { defaults.set(min(8,max(0,newValue)),forKey:"Selene.layout.anchor"); apply() } }
    var x: Double { get { min(50,max(-50,defaults.double(forKey:"Selene.layout.x"))) } set { defaults.set(min(50,max(-50,newValue)),forKey:"Selene.layout.x"); apply() } }
    var y: Double { get { min(50,max(-50,defaults.double(forKey:"Selene.layout.y"))) } set { defaults.set(min(50,max(-50,newValue)),forKey:"Selene.layout.y"); apply() } }
    func frame(_ container: CGSize, video: CGSize) -> CGRect { TVStreamGeometry.frame(container:container,video:video,stretch:stretch,alignment:alignment,x:x,y:y) }
    func reset() { for key in ["stretch","anchor","x","y"] { defaults.removeObject(forKey:"Selene.layout."+key) }; apply() }
    private func apply() { SeleneTVSession.shared.stream?.tvApplyVideoLayout() }
}
final class TVStreamLayoutController: UIViewController {
    private let layout = TVStreamLayout.shared
    private let values = tvStreamLabel("",size:25)
    override func viewDidLoad() {
        super.viewDidLoad(); view.backgroundColor = UIColor(white:0.035,alpha:1)
        let stack = UIStackView(); stack.axis = .vertical; stack.spacing = 16
        stack.addArrangedSubview(tvStreamLabel("Picture layout".localized,size:38)); stack.addArrangedSubview(values)
        let modes = UIStackView(arrangedSubviews:[TVStreamButton("Keep aspect ratio".localized){ [weak self] in self?.layout.stretch=false; self?.refresh() },TVStreamButton("Stretch to fill".localized){ [weak self] in self?.layout.stretch=true; self?.refresh() }]); modes.distribution = .fillEqually; modes.spacing=16; stack.addArrangedSubview(modes)
        for row in 0..<3 {
            let names = [["Top left","Top center","Top right"],["Center left","Center","Center right"],["Bottom left","Bottom center","Bottom right"]]
            let line = UIStackView(); line.distribution = .fillEqually; line.spacing=16
            for column in 0..<3 { line.addArrangedSubview(TVStreamButton(names[row][column].localized){ [weak self] in self?.layout.alignment=row*3+column; self?.refresh() }) }; stack.addArrangedSubview(line)
        }
        for horizontal in [true,false] {
            let line = UIStackView(); line.distribution = .fillEqually; line.spacing=16
            for direction in [-1,1] { line.addArrangedSubview(TVStreamButton((horizontal ? "Horizontal offset" : "Vertical offset").localized + (direction<0 ? " −1%" : " +1%")){ [weak self] in guard let self else { return }; if horizontal { self.layout.x += Double(direction) } else { self.layout.y += Double(direction) }; self.refresh() }) }; stack.addArrangedSubview(line)
        }
        stack.addArrangedSubview(TVStreamButton("Reset".localized){ [weak self] in self?.layout.reset(); self?.refresh() })
        stack.addArrangedSubview(TVStreamButton("Done".localized){ [weak self] in self?.dismiss(animated:true) })
        stack.translatesAutoresizingMaskIntoConstraints=false; view.addSubview(stack)
        NSLayoutConstraint.activate([stack.widthAnchor.constraint(equalTo:view.widthAnchor,multiplier:0.72),stack.centerXAnchor.constraint(equalTo:view.centerXAnchor),stack.centerYAnchor.constraint(equalTo:view.centerYAnchor)])
        refresh()
    }
    private func refresh() { values.text = (layout.stretch ? "Stretch to fill" : "Keep aspect ratio").localized + String(format:" · X %.0f%% · Y %.0f%%",layout.x,layout.y) }
    override func pressesBegan(_ presses:Set<UIPress>,with event:UIPressesEvent?) { if presses.contains(where:{$0.type == .menu}) { return }; super.pressesBegan(presses,with:event) }
    override func pressesEnded(_ presses:Set<UIPress>,with event:UIPressesEvent?) { if presses.contains(where:{$0.type == .menu}) { dismiss(animated:true); return }; super.pressesEnded(presses,with:event) }
}


// Pure adaptive policy: only network frame loss and RTT drive adjustments.
struct TVAdaptiveSample {
    let window: Double, time: Double, frames: Double, received: Double, dropped: Double, rtt: Double
    var valid: Bool { [window,time,frames,received,dropped,rtt].allSatisfy { $0.isFinite && $0 >= 0 } && frames > 0 && received > 0 && dropped <= frames && received <= frames }
}
struct TVAdaptivePolicy {
    var baseline: Double?; var lastWindow: Double?; var lastTime: Double?
    var lossStreak = 0, delayStreak = 0, healthySince: Double?
    var cooldownUntil = 0.0
    mutating func invalidate() { lossStreak=0; delayStreak=0; healthySince=nil }
    mutating func evaluate(_ sample: TVAdaptiveSample?, target: Int, lower: Int, upper: Int) -> (Int,String)? {
        guard let s = sample, s.valid else { invalidate(); return nil }
        if let lastWindow, s.window <= lastWindow {
            if s.window < lastWindow { self.lastWindow=s.window; baseline=nil; invalidate() }
            return nil
        }
        if let lastTime, s.time-lastTime > 2.5 || s.time <= lastTime { invalidate() }
        lastWindow=s.window; lastTime=s.time
        guard s.time >= cooldownUntil else { invalidate(); return nil }
        let loss=s.dropped/s.frames
        if baseline == nil { baseline=s.rtt }
        let base=baseline ?? s.rtt
        let highRTT=s.rtt > base+20 && s.rtt > base*1.5
        lossStreak=loss > 0.01 ? lossStreak+1 : 0
        delayStreak=highRTT ? delayStreak+1 : 0
        if lossStreak >= 2 || delayStreak >= 3 {
            let reason = lossStreak >= 2 ? "Network frame loss" : "Network latency increased"
            let next=max(lower,min(upper,Int(Double(target)*0.8)))
            invalidate(); if next == target { return nil }; cooldownUntil=s.time+5
            return (next,reason)
        }
        let healthy=loss < 0.001 && s.rtt <= base*1.2+5
        if healthy {
            baseline=base*0.95+s.rtt*0.05
            if healthySince == nil { healthySince=s.time }
            if s.time-(healthySince ?? s.time) >= 15 {
                let next=max(lower,min(upper,Int(Double(target)*1.05)))
                invalidate(); if next == target { return nil }; cooldownUntil=s.time+5
                return (next,"Network stable")
            }
        } else { healthySince=nil }
        return nil
    }
}
// End pure adaptive policy.
final class TVAdaptiveController {
    unowned let session: SeleneTVSession
    private var timer: Timer?
    private var policy = TVAdaptivePolicy()
    private var failures=0
    private(set) var active=false, paused=false, unsupported=false
    private(set) var reason=""
    private let defaults=UserDefaults.standard
    init(session:SeleneTVSession) { self.session=session }
    var enabled: Bool { get { defaults.bool(forKey:"Selene.abr.enabled") } set { defaults.set(newValue,forKey:"Selene.abr.enabled"); newValue ? start() : stop(); session.menuChanged?() } }
    var upper: Int { get {
        let manual=DataManager().getSettings()?.bitrate.intValue ?? 150000
        return min(800000,max(500,defaults.object(forKey:"Selene.abr.upper") == nil ? manual : defaults.integer(forKey:"Selene.abr.upper")))
    } set { defaults.set(min(800000,max(500,newValue)),forKey:"Selene.abr.upper"); if lower > upper { lower=upper }; restartBounds() } }
    var lower: Int { get { min(upper,max(500,defaults.object(forKey:"Selene.abr.lower") == nil ? upper/4 : defaults.integer(forKey:"Selene.abr.lower"))) } set { defaults.set(min(upper,max(500,newValue)),forKey:"Selene.abr.lower"); restartBounds() } }
    var statusText: String {
        let state = unsupported ? "Host does not support bitrate adjustment" : paused ? "Automatic control paused" : active ? "Automatic control active" : enabled ? "Enabled for next stream" : "Automatic control off"
        return state.localized + (reason.isEmpty ? "" : " · " + reason.localized)
    }
    func stop() { timer?.invalidate(); timer=nil; active=false; policy=TVAdaptivePolicy() }
    func manualOverride() { defaults.set(false,forKey:"Selene.abr.enabled"); stop(); reason="Manual override"; session.menuChanged?() }
    private func restartBounds() { policy=TVAdaptivePolicy(); if active { sample() } }
    func start() {
        stop(); paused=false; unsupported=false; reason=""; failures=0
        guard enabled, let stream=session.stream, !stream.streamConfig.controlOnly else { return }
        active=true
        timer=Timer.scheduledTimer(withTimeInterval:1,repeats:true) { [weak self] _ in self?.sample() }
    }
    func sample() {
        guard active, !session.pending, let stream=session.stream else { return }
        let values=stream.tvStreamMeasurements() as? [String:Any] ?? [:]
        func number(_ key:String)->Double? { (values[key] as? NSNumber)?.doubleValue }
        let sample:TVAdaptiveSample?
        if let window=number("windowEnd"),let frames=number("frames"),let received=number("receivedFrames"),let dropped=number("networkDroppedFrames"),let rtt=number("rttMS") {
            sample=TVAdaptiveSample(window:window,time:CACurrentMediaTime(),frames:frames,received:received,dropped:dropped,rtt:rtt)
        } else { sample=nil }
        let fresh = sample.map { policy.lastWindow == nil || $0.window > policy.lastWindow! } ?? false
        var decision=policy.evaluate(sample,target:session.targetKbps,lower:lower,upper:upper)
        // Apply explicit bounds only with a valid fresh measurement; no video means no mutation.
        if decision == nil, fresh, let sample, sample.valid, (session.targetKbps < lower || session.targetKbps > upper), sample.time >= policy.cooldownUntil {
            decision=(min(upper,max(lower,session.targetKbps)),"Configured bounds"); policy.cooldownUntil=sample.time+5
        }
        guard let (target,cause)=decision else { return }
        let token=session.generation
        session.request(target,saveManual:false) { [weak self] success,_,status in
            guard let self, self.session.generation == token, self.active else { return }
            if success { self.failures=0; self.reason=cause }
            else if [403,404,405,501].contains(status) { self.stop(); self.unsupported=true; self.reason="" }
            else { self.failures += 1; if self.failures >= 3 { self.stop(); self.paused=true; self.reason="Repeated adjustment failures" } }
            self.session.menuChanged?()
        }
    }
}
final class TVAdaptiveSettingsController: UIViewController {
    private let adaptive=SeleneTVSession.shared.adaptive
    private let values=tvStreamLabel("",size:25)
    override func viewDidLoad() {
        super.viewDidLoad(); view.backgroundColor=UIColor(white:0.035,alpha:1)
        let stack=UIStackView(); stack.axis = .vertical; stack.spacing=24
        stack.addArrangedSubview(tvStreamLabel("Adaptive bitrate".localized,size:38)); stack.addArrangedSubview(values)
        stack.addArrangedSubview(tvStreamLabel("Automatic targets affect this session only. Manual adjustment turns automatic control off.".localized))
        stack.addArrangedSubview(TVStreamButton("Enable / Resume".localized){ [weak self] in self?.adaptive.enabled=true; self?.refresh() })
        stack.addArrangedSubview(TVStreamButton("Off".localized){ [weak self] in self?.adaptive.enabled=false; self?.refresh() })
        for upper in [false,true] { stack.addArrangedSubview(TVStreamButton((upper ? "Maximum bitrate" : "Minimum bitrate").localized){ [weak self] in
            guard let self else { return }; TVStreamEditors.presentBitrate(on:self,kbps:upper ? self.adaptive.upper : self.adaptive.lower) { [weak self] value in guard let self else { return }; if upper { self.adaptive.upper=value } else { self.adaptive.lower=value }; self.refresh() }
        }) }
        stack.addArrangedSubview(TVStreamButton("Done".localized){ [weak self] in self?.dismiss(animated:true) })
        stack.translatesAutoresizingMaskIntoConstraints=false; view.addSubview(stack)
        NSLayoutConstraint.activate([stack.widthAnchor.constraint(equalTo:view.widthAnchor,multiplier:0.7),stack.centerXAnchor.constraint(equalTo:view.centerXAnchor),stack.centerYAnchor.constraint(equalTo:view.centerYAnchor)])
        refresh()
    }
    override func viewDidAppear(_ animated:Bool) { super.viewDidAppear(animated); refresh() }
    private func refresh() { values.text=adaptive.statusText + String(format:"\n%.1f – %.1f Mbps",Double(adaptive.lower)/1000,Double(adaptive.upper)/1000) }
    override func pressesBegan(_ presses:Set<UIPress>,with event:UIPressesEvent?) { if presses.contains(where:{$0.type == .menu}) { return }; super.pressesBegan(presses,with:event) }
    override func pressesEnded(_ presses:Set<UIPress>,with event:UIPressesEvent?) { if presses.contains(where:{$0.type == .menu}) { dismiss(animated:true); return }; super.pressesEnded(presses,with:event) }
}

#endif
