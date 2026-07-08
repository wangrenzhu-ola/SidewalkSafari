import SwiftUI
import StoreKit

struct PremiumPreviewView: View {
    @EnvironmentObject private var store: SafariStore

    var body: some View {
        ZStack {
            SidewalkBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Premium Theme Preview")
                        .font(.largeTitle.bold())
                        .foregroundStyle(ChalkPalette.ink)
                    ChalkCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Chalk Festival Pack", systemImage: "paintpalette.fill")
                                .font(.title3.bold())
                            Text("Preview brighter clue cards, festival bead colors, and extra badge strip styles. Purchase is never assumed before StoreKit confirms it.")
                            Text(store.storeKitUnavailableCopy)
                                .foregroundStyle(ChalkPalette.berry)
                                .font(.callout.weight(.semibold))
                                .accessibilityIdentifier("storeKitUnavailableRecovery")
                        }
                    }
                    ForEach(["Rainbow chalk clues", "Star stamp badges", "Leaf hunt category icons"], id: \.self) { title in
                        Label(title, systemImage: "checkmark.seal")
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.white.opacity(0.45), in: RoundedRectangle(cornerRadius: 18))
                    }
                }
                .padding(18)
            }
        }
        .navigationTitle("Themes")
    }
}
