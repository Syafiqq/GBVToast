// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "GBVToast",
  platforms: [
    .iOS(.v15),
  ],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "GBVToast",
      targets: ["GBVToast"]
    )
  ],
  dependencies: [
    .package(
      url: "https://github.com/pointfreeco/swift-snapshot-testing.git",
      from: "1.17.0"
    )
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "GBVToast"
    ),
        .testTarget(
            name: "GBVToastTests",
            dependencies: [
                "GBVToast",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            exclude: [
                "Snapshots/__Snapshots__",
                "Fixtures/toast_snapshot_matrix.json",
            ],
            resources: [.process("Resources")]
        ),
  ],
  swiftLanguageModes: [.v6]
)
