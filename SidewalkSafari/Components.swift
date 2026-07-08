import SwiftUI

struct ChalkPalette {
    static let sidewalk = Color(red: 0.89, green: 0.86, blue: 0.78)
    static let chalk = Color(red: 0.98, green: 0.95, blue: 0.84)
    static let moss = Color(red: 0.23, green: 0.41, blue: 0.29)
    static let berry = Color(red: 0.76, green: 0.26, blue: 0.21)
    static let amber = Color(red: 0.96, green: 0.62, blue: 0.18)
    static let ink = Color(red: 0.15, green: 0.14, blue: 0.12)
}

struct SidewalkBackground: View {
    var body: some View {
        LinearGradient(colors: [ChalkPalette.sidewalk, Color(red: 0.77, green: 0.81, blue: 0.68)], startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay {
                Canvas { context, size in
                    for index in 0..<8 {
                        var path = Path()
                        let y = CGFloat(index) * size.height / 7
                        path.move(to: CGPoint(x: -20, y: y))
                        path.addCurve(to: CGPoint(x: size.width + 20, y: y + 18), control1: CGPoint(x: size.width * 0.25, y: y - 18), control2: CGPoint(x: size.width * 0.75, y: y + 28))
                        context.stroke(path, with: .color(.white.opacity(0.18)), lineWidth: 1)
                    }
                }
            }
            .ignoresSafeArea()
    }
}

struct ChalkCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(ChalkPalette.chalk.opacity(0.95), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
                    .foregroundStyle(.white.opacity(0.8))
            )
            .shadow(color: .black.opacity(0.12), radius: 14, y: 8)
    }
}

struct ProgressBeads: View {
    let completed: Int
    let total: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<max(total, 1), id: \.self) { index in
                Circle()
                    .fill(index < completed ? ChalkPalette.berry : .white.opacity(0.78))
                    .frame(width: 13, height: 13)
                    .overlay(Circle().stroke(ChalkPalette.ink.opacity(0.28), lineWidth: 1))
                    .accessibilityLabel(index < completed ? "Completed clue bead" : "Waiting clue bead")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(completed) of \(total) sidewalk clues found")
    }
}

struct EmptySidewalkIllustration: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(.white.opacity(0.45))
                .frame(height: 150)
            VStack(spacing: 12) {
                Image(systemName: "figure.walk.motion")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(ChalkPalette.moss)
                HStack(spacing: 10) {
                    ForEach(["leaf", "circle.hexagongrid", "sparkle.magnifyingglass"], id: \.self) { symbol in
                        Image(systemName: symbol)
                            .font(.title3)
                            .padding(10)
                            .background(.white.opacity(0.62), in: Circle())
                    }
                }
            }
        }
        .accessibilityLabel("Chalk sidewalk illustration")
    }
}
