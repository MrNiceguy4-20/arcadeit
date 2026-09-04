
import SwiftUI

struct WinetricksPickerView: View {

    @Binding var selected: Set<WinetricksVerb>

    var body: some View {
        List(WinetricksVerb.allCases) { verb in
            Toggle(
                verb.displayName,
                isOn: Binding(
                    get: { selected.contains(verb) },
                    set: {
                        if $0 { selected.insert(verb) }
                        else { selected.remove(verb) }
                    }
                )
            )
        }
        .frame(width: 300, height: 400)
    }
}
