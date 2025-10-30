import Cocoa
import QuartzCore

class OverlayWindow: NSWindow {
    private var mainView: NSView!
    private var emitter: CAEmitterLayer?
    private var settings = FancyCursorSettings.load()

    init() {
        let screenFrame = NSScreen.main?.frame ?? .zero
        super.init(contentRect: screenFrame, styleMask: .borderless, backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        ignoresMouseEvents = true
        hasShadow = false
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        mainView = NSView(frame: screenFrame)
        mainView.wantsLayer = true
        contentView = mainView

        setupEmitter()
    }

    func updateFrameToScreens() {
        let frame = NSScreen.main?.frame ?? .zero
        setFrame(frame, display: true)
        mainView.frame = frame
    }

    // MARK: - setup
    private func setupEmitter() {
        guard let layer = mainView.layer else { return }

        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: 0, y: 0)
        emitter.emitterShape = .point
        emitter.renderMode = .additive

        let cell = CAEmitterCell()
        applySettings(toCell: cell)

        emitter.emitterCells = [cell]
        layer.addSublayer(emitter)
        self.emitter = emitter
    }

    // MARK: - Apply Settings
    func applySettings(_ newSettings: FancyCursorSettings? = nil) {
        if let new = newSettings {
            settings = new
            settings.save()
        }

        guard let cell = emitter?.emitterCells?.first else { return }
        applySettings(toCell: cell)
    }

    private func applySettings(toCell cell: CAEmitterCell) {
        let s = settings

        // Display & Basics
        cell.contents = circleImage(radius: 8, color: s.color)
        cell.birthRate = Float(s.birthRate)
        cell.lifetime = Float(s.lifetime)
        cell.velocity = CGFloat(s.velocity)
        cell.velocityRange = CGFloat(s.velocity) * 0.4

        let speedFactor = min(1.0, s.velocity / 500.0)
        let minRange = CGFloat(Double.pi / 12)
        let maxExtra = CGFloat(Double.pi / 2)
        cell.emissionRange = CGFloat(minRange + CGFloat(speedFactor) * maxExtra)


        #if arch(x86_64) || arch(arm64)
        cell.scale = CGFloat(s.scale)
        #else
        cell.scale = Float(s.scale)
        #endif

        cell.alphaSpeed = Float(s.alphaSpeed)

        if let emitter = emitter {
            emitter.emitterCells = [cell]
        }
    }

    func updateSparkleColor(to color: NSColor) {
        settings.color = color
        settings.save()

        guard let emitter = emitter,
              let cells = emitter.emitterCells else { return }

        for cell in cells {
            cell.contents = circleImage(radius: 8, color: color)
        }

        emitter.emitterCells = cells
    }

    func makeSparkle(at globalPoint: CGPoint) {
        guard let emitter = emitter else { return }

        let frame = self.frame
        let screenHeight = frame.height
        let local = CGPoint(
            x: globalPoint.x - frame.origin.x,
            y: screenHeight - (globalPoint.y - frame.origin.y)
        )

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        emitter.emitterPosition = local
        CATransaction.commit()
    }

    private func circleImage(radius: CGFloat, color: NSColor) -> CGImage {
        let size = NSSize(width: radius * 2, height: radius * 2)
        let image = NSImage(size: size, flipped: false) { rect in
            color.setFill()
            NSBezierPath(ovalIn: rect).fill()
            return true
        }
        return image.cgImage(forProposedRect: nil, context: nil, hints: nil)!
    }
}
