import Foundation
import GameController

final class ControllerManager {
    static let shared = ControllerManager()
    
    private var logStore: LogStore?
    
    func configure(logStore: LogStore) {
        self.logStore = logStore
        startMonitoring()
    }
    
    private func startMonitoring() {
        NotificationCenter.default.addObserver(
            forName: .GCControllerDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let controller = notification.object as? GCController {
                self?.logStore?.append("[INPUT] Controller connected: \(controller.vendorName ?? "Unknown")")
                self?.setup(controller: controller)
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .GCControllerDidDisconnect,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let controller = notification.object as? GCController {
                self?.logStore?.append("[INPUT] Controller disconnected: \(controller.vendorName ?? "Unknown")")
            }
        }
        
        GCController.startWirelessControllerDiscovery {
            // done
        }
        
        GCController.controllers().forEach { setup(controller: $0) }
    }
    
    private func setup(controller: GCController) {
        guard let logStore = logStore else { return }
        
        if let gamepad = controller.extendedGamepad {
            gamepad.valueChangedHandler = { [weak self] gamepad, element in
                guard let self = self else { return }
                
                if let button = element as? GCControllerButtonInput {
                    let pressed = button.isPressed
                    let name = self.name(for: button, in: gamepad)
                    logStore.append("[INPUT] \(name) \(pressed ? "press" : "release")")
                    InputMapper.shared.handleButton(name: name, pressed: pressed)
                }
            }
            
            logStore.append("[INPUT] Configured extended gamepad \(controller.vendorName ?? "")")
        } else if let micro = controller.microGamepad {
            micro.valueChangedHandler = { [weak self] gamepad, element in
                self?.logStore?.append("[INPUT] Micro gamepad input")
            }
            logStore.append("[INPUT] Configured micro gamepad \(controller.vendorName ?? "")")
        }
    }
    
    private func name(for button: GCControllerButtonInput, in gamepad: GCExtendedGamepad) -> String {
        switch button {
        case gamepad.buttonA: return "A"
        case gamepad.buttonB: return "B"
        case gamepad.buttonX: return "X"
        case gamepad.buttonY: return "Y"
        case gamepad.leftShoulder: return "L1"
        case gamepad.rightShoulder: return "R1"
        case gamepad.leftTrigger: return "L2"
        case gamepad.rightTrigger: return "R2"
        default: return "Button"
        }
    }
}
