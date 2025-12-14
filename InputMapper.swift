import Foundation
import CoreGraphics

final class InputMapper {
    static let shared = InputMapper()
    
    // Button name -> keycode
    private var mapping: [String: CGKeyCode] = [:]
    
    func configure(for inputMapping: InputMapping?) {
        guard let m = inputMapping else {
            mapping = [:]
            return
        }
        
        mapping["A"] = CGKeyCode(m.buttonAKeyCode)
        mapping["B"] = CGKeyCode(m.buttonBKeyCode)
        mapping["X"] = CGKeyCode(m.buttonXKeyCode)
        mapping["Y"] = CGKeyCode(m.buttonYKeyCode)
        mapping["START"] = CGKeyCode(m.startKeyCode)
        mapping["COIN"] = CGKeyCode(m.coinKeyCode)
    }
    
    func sendKey(_ key: CGKeyCode) {
        let src = CGEventSource(stateID: .combinedSessionState)
        let down = CGEvent(keyboardEventSource: src, virtualKey: key, keyDown: true)
        let up   = CGEvent(keyboardEventSource: src, virtualKey: key, keyDown: false)
        
        down?.post(tap: .cgAnnotatedSessionEventTap)
        up?.post(tap: .cgAnnotatedSessionEventTap)
    }
    
    /// Called by ControllerManager when a gamepad button changes.
    func handleButton(name: String, pressed: Bool) {
        guard pressed else { return }
        guard let key = mapping[name] else { return }
        sendKey(key)
    }
}
