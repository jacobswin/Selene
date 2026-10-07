#if os(tvOS)
import UIKit
import Foundation
import AVFoundation
import VideoToolbox

/// One owner for a stream's acknowledged bitrate and serialized host mutations.
@objcMembers final class SeleneTVSession: NSObject {
    static let shared = SeleneTVSession()
    private(set) weak var stream: StreamFrameViewController?
    private(set) var targetKbps = 0
    private(set) var pending = false
    fileprivate var generation = UUID()
    private let requests = DispatchQueue(label: "Selene.stream.bitrate")
    var returningFromSettings = false
    var nextFocus = "continue"
    var lastMessage = ""
    var menuChanged: (() -> Void)?

    func begin(_ controller: StreamFrameViewController) {
        generation = UUID(); stream = controller
        targetKbps = Int(controller.streamConfig.bitRate)
        pending = false; lastMessage = ""; returningFromSettings = false
    }
    func end() {
        generation = UUID(); pending = false; stream = nil
        returningFromSettings = false; menuChanged = nil
        KeyboardSupport.releaseAllKeys()
    }
    func requestManual(_ kbps: Int, completion: @escaping (Bool, Int, Int) -> Void) {
        request(kbps, saveManual: true, completion: completion)
    }
    func request(_ kbps: Int, saveManual: Bool, completion: @escaping (Bool, Int, Int) -> Void) {
        dispatchPrecondition(condition: .onQueue(.main))
        guard !pending, let controller = stream, let host = controller.mainFrameViewcontroller else {
            completion(false, targetKbps, -1); return
        }
        let requested = min(800_000, max(500, kbps))
        let previous = targetKbps
        if requested == previous { completion(true, previous, 200); return }
        pending = true; menuChanged?()
        let token = generation
        requests.async { [weak self, weak host] in
            let status = Int(host?.request(forBitrate: requested) ?? -1)
            DispatchQueue.main.async {
                guard let self, self.generation == token, self.stream != nil else { return }
                self.pending = false
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
        guard controller.presentedViewController == nil, controller.view.window != nil else { return }
        if stream !== controller { begin(controller) }
        controller.tvSetInputPaused(true)
        let menu = TVStreamMenuController(session: self)
        controller.present(menu, animated: true)
    }
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
    private let left = UIStackView()
    private let right = UIStackView()
    init(session: SeleneTVSession) {
        self.session = session; super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }
    required init?(coder: NSCoder) { fatalError() }
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        buttons[session.nextFocus].map { [$0] } ?? super.preferredFocusEnvironments
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        let panel = UIView(); panel.backgroundColor = UIColor(white: 0.055, alpha: 0.98)
        panel.layer.cornerRadius = 32; panel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(panel)
        let heading = tvStreamLabel("Stream menu".localized, size: 40)
        let columns = UIStackView(arrangedSubviews: [left, right]); columns.axis = .horizontal
        columns.spacing = 65; columns.distribution = .fillEqually
        for stack in [left, right] { stack.axis = .vertical; stack.spacing = 18 }
        let content = UIStackView(arrangedSubviews: [heading, columns]); content.axis = .vertical
        content.spacing = 32; content.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(content)
        NSLayoutConstraint.activate([
            panel.centerXAnchor.constraint(equalTo: view.centerXAnchor), panel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            panel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.83),
            panel.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.9),
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
        add("capabilities", "Capability report") { [weak self] in
            guard let self else { return }; self.session.nextFocus = "capabilities"
            self.present(UINavigationController(rootViewController: TVStreamCapabilityController()), animated: true)
        }
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
    private func add(_ id: String, _ key: String, action: @escaping () -> Void) {
        let button = TVStreamButton(key.localized, action: action); buttons[id] = button; left.addArrangedSubview(button)
    }
    func refresh() {
        bitrate.text = String(format: "%.1f Mbps", Double(session.targetKbps) / 1000)
        received.text = LocalizationHelper.localizedString(forKey: "Received bitrate: %.1f Mbps", session.stream?.tvReceivedMbps() ?? 0)
        status.text = session.pending ? "Applying bitrate…".localized : session.lastMessage
        bitrateButtons.forEach { $0.isEnabled = !session.pending; $0.alpha = session.pending ? 0.4 : 1 }
    }
    func apply(_ kbps: Int) { session.requestManual(kbps) { [weak self] _, _, _ in self?.refresh() } }
    private func step(_ direction: Int) { apply(session.targetKbps + direction * (session.targetKbps <= 200_000 ? 10_000 : 25_000)) }
    private func closeMenu(_ completion: @escaping () -> Void) {
        if let child = presentedViewController {
            child.dismiss(animated: false) { self.closeMenu(completion) }
        } else { dismiss(animated: true, completion: completion) }
    }
    func resume() {
        session.nextFocus = "continue"
        closeMenu { self.session.stream?.tvSetInputPaused(false) }
    }
    private func disconnect(closeApp: Bool) {
        closeMenu { self.session.stream?.tvDisconnectCloseApp(closeApp) }
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
    private func chooseKeys() {
        session.nextFocus = "keys"
        let alert = UIAlertController(title: "Keyboard shortcuts".localized, message: nil, preferredStyle: .alert)
        for (title, keys) in [("Alt+Tab", [0xA4,0x09]), ("Windows", [0x5B]), ("Esc", [0x1B]), ("Enter", [0x0D])] {
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in self?.sendShortcut(keys) })
        }
        alert.addAction(UIAlertAction(title: "Text input".localized, style: .default) { [weak self] _ in
            guard let self else { return }
            self.dismiss(animated: false) {
                let input = TVStreamTextInputController { [weak self] text in
                    guard let self, self.session.stream != nil else { return }
                    text.withCString { _ = LiSendUtf8TextEvent($0, UInt32(text.utf8.count)) }
                    self.resume()
                }
                self.present(input, animated: true)
            }
        })
        alert.addAction(UIAlertAction(title: "Special keys".localized, style: .default) { [weak self] _ in
            guard let self else { return }; self.dismiss(animated: false) { self.chooseSpecialKeys() }
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
        if presses.contains(where: { $0.type == .menu }) { resume(); return }
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
        guard let value, value.isFinite, value >= 0 else { return active ? unknown : notStarted }
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
        if let w = values["width"] as? NSNumber, let h = values["height"] as? NSNumber { size = "\(w.intValue) × \(h.intValue)" }
        else { size = session.stream == nil ? notStarted : unknown }
        let requestedWidth = session.stream.map { Int($0.streamConfig.width) } ?? settings?.width.intValue ?? 0
        let requestedHeight = session.stream.map { Int($0.streamConfig.height) } ?? settings?.height.intValue ?? 0
        let codec = [0:"Automatic",1:"H.264",2:"HEVC",3:"AV1"][Int(settings?.preferredCodec ?? 0)] ?? unknown
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
                ("HDR".localized, (settings?.enableHdr ?? false) ? "On".localized : "Off".localized),
                ("Manual bitrate".localized, String(format: "%.1f Mbps", Double(settings?.bitrate.intValue ?? 0)/1000))]),
            ("Negotiated stream".localized, [
                ("Resolution".localized, size),
                ("Negotiated codec".localized, values["codec"] as? String ?? (session.stream == nil ? notStarted : unknown)),
                ("Decoder".localized, session.stream == nil ? notStarted : values["decoder"] as? String ?? unknown),
                ("Hardware acceleration in use".localized, acceleration),
                ("HDR".localized, hdr),
                ("Received frame rate".localized, observed("receivedFPS", format:"%.2f FPS")),
                ("Decode time".localized, observed("decodeMS", format:"%.2f ms")),
                ("Negotiated audio channels".localized, observed("audioChannels", format:"%.0f")),
                ("Received bitrate".localized, observed("receivedMbps", format:"%.1f Mbps"))])])
    }
}

final class TVStreamCapabilityController: UITableViewController {
    private var snapshot = TVStreamCapabilitySnapshot.capture()
    override func viewDidLoad() {
        super.viewDidLoad(); title = "Capability report".localized
        tableView.backgroundColor = UIColor(white: 0.04, alpha: 1)
        tableView.rowHeight = 95
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done".localized, style: .done, target:self, action:#selector(close))
    }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); snapshot = .capture(); tableView.reloadData() }
    override func numberOfSections(in tableView: UITableView) -> Int { snapshot.sections.count }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { snapshot.sections[section].1.count }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { snapshot.sections[section].0 }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style:.subtitle, reuseIdentifier:nil)
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

#endif
