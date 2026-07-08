import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: SafariStore
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            SidewalkBackground()
            VStack(alignment: .leading, spacing: 22) {
                Text("Sidewalk Safari")
                    .font(.largeTitle.bold())
                    .foregroundStyle(ChalkPalette.ink)
                Text("Turn a short family walk into a playful sidewalk quest with clue tiles, find moments, and a local Safari Log.")
                    .font(.title3)
                    .foregroundStyle(ChalkPalette.ink.opacity(0.82))
                ChalkCard {
                    Label(store.privacyBoundaryCopy, systemImage: "lock.shield")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(ChalkPalette.moss)
                        .accessibilityIdentifier("privacyBoundaryCopy")
                }
                VStack(alignment: .leading, spacing: 10) {
                    Label("Pick a starter quest before the walk.", systemImage: "1.circle")
                    Label("Tap clue beads as your explorer finds each thing.", systemImage: "2.circle")
                    Label("Save a find moment and replay it in Safari Log.", systemImage: "3.circle")
                }
                .font(.headline)
                Spacer()
                Button("Start a Sidewalk Safari") { isPresented = false }
                    .buttonStyle(.borderedProminent)
                    .tint(ChalkPalette.moss)
                    .accessibilityIdentifier("startSafariButton")
            }
            .padding(24)
        }
        .presentationDetents([.large])
    }
}
