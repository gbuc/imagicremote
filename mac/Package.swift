// swift-tools-version: 5.10
import PackageDescription

let package = Package(
  name: "iMagicRemote",
  platforms: [.macOS(.v13)],
  products: [
    .library(name: "iMagicRemoteCore", targets: ["iMagicRemoteCore"]),
    .executable(name: "iMagicRemote", targets: ["iMagicRemote"]),
  ],
  dependencies: [
    .package(url: "https://github.com/swhitty/FlyingFox.git", .upToNextMajor(from: "0.27.1")),
  ],
  targets: [
    .target(name: "iMagicRemoteCore"),
    .target(
      name: "iMagicRemoteServer",
      dependencies: [
        "iMagicRemoteCore",
        .product(name: "FlyingFox", package: "FlyingFox"),
      ]
    ),
    .executableTarget(
      name: "iMagicRemote",
      dependencies: ["iMagicRemoteCore", "iMagicRemoteServer"]
    ),
    .testTarget(name: "iMagicRemoteCoreTests", dependencies: ["iMagicRemoteCore"]),
    .testTarget(name: "iMagicRemoteServerTests", dependencies: ["iMagicRemoteServer"]),
  ]
)
