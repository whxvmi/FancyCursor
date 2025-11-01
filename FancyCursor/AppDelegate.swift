import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var overlayWindow: OverlayWindow?
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    private var statusItem: NSStatusItem!
    private var settingsWindow: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("[FancyCursor] app launched")
        
        overlayWindow = OverlayWindow()
        overlayWindow?.orderFrontRegardless()

        startCGEventTap()
        
        setupStatusBarMenu()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        stopCGEventTap()
    }

    // MARK: - Status Bar
    private func setupStatusBarMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "✨"
        }

        let menu = NSMenu()
        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Leave", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            settingsWindow = SettingsWindowController(overlay: overlayWindow)
        }
        settingsWindow?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    // MARK: - CGEventTap
    private func startCGEventTap() {
        guard eventTap == nil else { return }

        let mask = (1 << CGEventType.mouseMoved.rawValue)
        if let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                if type == .mouseMoved {
                    let loc = event.location
                    let appDelegatePtr = UnsafeRawPointer(refcon)
                    if let appDelegate = Unmanaged<AppDelegate>.fromOpaque(appDelegatePtr!).takeUnretainedValue() as? AppDelegate {
                        appDelegate.handleMouseMove(CGPoint(x: loc.x, y: loc.y))
                    }
                }
                return Unmanaged.passUnretained(event)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) {
            eventTap = tap
            runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
            print("[FancyCursor] CGEventTap started")
        } else {
            print("[FancyCursor] Failed to create CGEventTap (needs Accessibility permission?)")
        }
    }

    private func stopCGEventTap() {
        if let tap = eventTap {
            if let src = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), src, .commonModes)
            }
            CFMachPortInvalidate(tap)
            eventTap = nil
            runLoopSource = nil
            print("[FancyCursor] CGEventTap stopped")
        }
    }

    @objc private func screensChanged() {
        overlayWindow?.updateFrameToScreens()
    }

    // MARK: - Cursor Movement
    func handleMouseMove(_ location: CGPoint) {
        guard let screen = NSScreen.main else { return }

        // CoreGraphics → Cocoa
        let flippedY = screen.frame.height - location.y
        let correctedLocation = CGPoint(x: location.x, y: flippedY)

        overlayWindow?.makeSparkle(at: location)
    }
}
