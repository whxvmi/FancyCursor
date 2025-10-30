import Cocoa

class SettingsWindowController: NSWindowController {
    private var overlay: OverlayWindow
    private var colorWell: NSColorWell!
    private var birthSlider: NSSlider!
    private var velocitySlider: NSSlider!

    init(overlay: OverlayWindow?) {
        self.overlay = overlay ?? OverlayWindow()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        super.init(window: window)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        let settings = FancyCursorSettings.load()

        // MARK: - Colors
        let colorLabel = NSTextField(labelWithString: "Color")
        colorLabel.frame = NSRect(x: 20, y: 150, width: 100, height: 20)
        contentView.addSubview(colorLabel)

        colorWell = NSColorWell(frame: NSRect(x: 120, y: 140, width: 60, height: 30))
        colorWell.color = settings.color
        colorWell.target = self
        colorWell.action = #selector(colorChanged(_:))
        contentView.addSubview(colorWell)

        // MARK: - Rate
        let birthLabel = NSTextField(labelWithString: "Rate")
        birthLabel.frame = NSRect(x: 20, y: 100, width: 100, height: 20)
        contentView.addSubview(birthLabel)

        birthSlider = NSSlider(
            value: Double(settings.birthRate),
            minValue: 1,
            maxValue: 300,
            target: self,
            action: #selector(updateSettings)
        )
        birthSlider.frame = NSRect(x: 120, y: 100, width: 150, height: 20)
        contentView.addSubview(birthSlider)

        // MARK: - Thickness
        let velocityLabel = NSTextField(labelWithString: "Thickness")
        velocityLabel.frame = NSRect(x: 20, y: 60, width: 100, height: 20)
        contentView.addSubview(velocityLabel)

        velocitySlider = NSSlider(
            value: Double(settings.velocity),
            minValue: 0,
            maxValue: 500,
            target: self,
            action: #selector(updateSettings)
        )
        velocitySlider.frame = NSRect(x: 120, y: 60, width: 150, height: 20)
        contentView.addSubview(velocitySlider)

        // MARK: - Kaydet butonu
        let saveButton = NSButton(title: "Save", target: self, action: #selector(saveSettings))
        saveButton.frame = NSRect(x: 180, y: 20, width: 80, height: 30)
        contentView.addSubview(saveButton)
    }

    // MARK: - Color Changer
    @objc private func colorChanged(_ sender: NSColorWell) {
        var settings = FancyCursorSettings.load()
        settings.color = sender.color
        settings.save()
        overlay.updateSparkleColor(to: sender.color)
    }

    // MARK: - Apply
    @objc private func updateSettings() {
        applySettings()
    }

    // MARK: - Save
    @objc private func saveSettings() {
        applySettings()
        window?.close()
    }

    private func applySettings() {
        var settings = FancyCursorSettings.load()
        settings.color = colorWell.color
        settings.birthRate = CGFloat(birthSlider.doubleValue)
        settings.velocity = CGFloat(velocitySlider.doubleValue)
        settings.save()
        overlay.applySettings(settings)
    }
}
