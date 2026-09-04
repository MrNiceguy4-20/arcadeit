
import SwiftUI

struct PatchManagerView: View {
    @Binding var patches: [PrelaunchPatch]
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPatchID: PrelaunchPatch.ID?

    var body: some View {
        HStack {
            List(selection: $selectedPatchID) {
                ForEach(patches) { patch in
                    Text(patch.description)
                        .tag(patch.id as PrelaunchPatch.ID?)
                }
                .onDelete { indexSet in
                    patches.remove(atOffsets: indexSet)
                }
            }
            .frame(minWidth: 180)

            if let id = selectedPatchID,
               let idx = patches.firstIndex(where: { $0.id == id }) {
                PatchDetailEditorView(patch: $patches[idx])
                    .frame(minWidth: 380)
            } else {
                Text("Select a patch or add one.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    let newPatch = PrelaunchPatch(
                        description: "New text replace patch",
                        type: .replaceTextInFile,
                        targetPath: "/path/to/file.txt",
                        searchText: "old",
                        replacementText: "new"
                    )
                    patches.append(newPatch)
                    selectedPatchID = newPatch.id
                } label: {
                    Label("Add Patch", systemImage: "plus")
                }

                Button("Done") {
                    dismiss()
                }
            }
        }
        .frame(width: 600, height: 400)
    }
}

struct PatchDetailEditorView: View {
    @Binding var patch: PrelaunchPatch

    var body: some View {
        Form {
            Section(header: Text("Description")) {
                TextField("Description", text: $patch.description)
            }

            Section(header: Text("Target File")) {
                TextField("Target path", text: $patch.targetPath)
            }

            if patch.type == .replaceTextInFile {
                Section(header: Text("Text Replace")) {
                    TextField("Search text", text: Binding(
                        get: { patch.searchText ?? "" },
                        set: { patch.searchText = $0 }
                    ))
                    TextField("Replacement text", text: Binding(
                        get: { patch.replacementText ?? "" },
                        set: { patch.replacementText = $0 }
                    ))
                }
            }
        }
        .padding()
    }
}
