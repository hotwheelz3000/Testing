// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HotelLibre",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "HotelLibre", targets: ["HotelLibre"])
    ],
    targets: [
        .target(
            name: "HotelLibre",
            path: "Sources/HotelLibre"
        )
    ]
)
