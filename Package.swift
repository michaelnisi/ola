// swift-tools-version:5.3
import PackageDescription

let package = Package(
  name: "Ola",
  platforms: [
    .iOS(.v13)
  ],
  products: [
    .library(
      name: "Ola",
      targets: ["Ola"]),
    ],
  dependencies: [
  ],
  targets: [
    .target(
      name: "Ola",
      dependencies: []),
    .testTarget(
      name: "OlaTests",
      dependencies: ["Ola"]),
  ]
)
