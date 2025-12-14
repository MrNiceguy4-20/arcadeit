//
//  InputMappingEditorView.swift
//  arcadeit
//
//  Created by kevin on 2025-12-11.
//


import SwiftUI

struct InputMappingEditorView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State var mapping: InputMapping
    
    var onCommit: ((InputMapping) -> Void)?
    
    init(mapping: Binding<InputMapping>, onCommit: ((InputMapping) -> Void)? = nil) {
        _mapping = State(initialValue: mapping.wrappedValue)
        self.onCommit = onCommit
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Input Mapping (macOS keycodes, US layout)")
                .font(.headline)
            
            Form {
                HStack {
                    Text("Button A (shoot)")
                    TextField("Keycode", value: $mapping.buttonAKeyCode, formatter: NumberFormatter())
                        .frame(width: 60)
                }
                HStack {
                    Text("Button B (jump)")
                    TextField("Keycode", value: $mapping.buttonBKeyCode, formatter: NumberFormatter())
                        .frame(width: 60)
                }
                HStack {
                    Text("Button X")
                    TextField("Keycode", value: $mapping.buttonXKeyCode, formatter: NumberFormatter())
                        .frame(width: 60)
                }
                HStack {
                    Text("Button Y")
                    TextField("Keycode", value: $mapping.buttonYKeyCode, formatter: NumberFormatter())
                        .frame(width: 60)
                }
                HStack {
                    Text("Start")
                    TextField("Keycode", value: $mapping.startKeyCode, formatter: NumberFormatter())
                        .frame(width: 60)
                }
                HStack {
                    Text("Coin")
                    TextField("Keycode", value: $mapping.coinKeyCode, formatter: NumberFormatter())
                        .frame(width: 60)
                }
            }
            
            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                Button("Save") {
                    onCommit?(mapping)
                    dismiss()
                }
            }
        }
        .padding()
        .frame(width: 400, height: 320)
    }
}
