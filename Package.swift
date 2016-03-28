import PackageDescription

let package = Package(
  name:         "SwiftSockets",
  targets:      [
    Target(name: "SwiftSockets"),
    Target(name: "SwiftyEchoDaemon",
           dependencies: [ .Target(name: "SwiftSockets") ])
  ],
  dependencies: []
)
