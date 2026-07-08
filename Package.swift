// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TankTheaterCareScenesSupport",
    platforms: [.iOS(.v17)],
    products: [.library(name: "TankTheaterCareScenesSupport", targets: ["TankTheaterCareScenesSupport"])],
    targets: [.target(name: "TankTheaterCareScenesSupport", path: "TankTheaterCareScenesSupport")]
)
