// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SidewalkSafariSupport",
    platforms: [.iOS(.v17)],
    products: [.library(name: "SidewalkSafariSupport", targets: ["SidewalkSafariSupport"])],
    targets: [.target(name: "SidewalkSafariSupport", path: "SidewalkSafariSupport")]
)
