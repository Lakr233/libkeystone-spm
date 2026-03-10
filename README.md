# libkeystone-spm

Swift Package Manager support for the vendored
[Keystone](https://github.com/keystone-engine/keystone) static library.

## Features

- Builds Keystone from source inside SwiftPM
- No external CMake build step in consumers
- Apple platform coverage: macOS, Mac Catalyst, iOS, iOS Simulator, tvOS,
  tvOS Simulator, watchOS, watchOS Simulator, visionOS, visionOS Simulator
- Bundles the LLVM-based assembler core needed for `ARM`, `AArch64`, `X86`,
  plus Keystone's built-in `EVM` support

## Install

```swift
.package(url: "https://github.com/Lakr233/libkeystone-spm.git", from: "1.0.0")
```

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "Keystone", package: "libkeystone-spm"),
    ]
)
```

## Usage

```swift
import Keystone

var handle: OpaquePointer?
let error = ks_open(KS_ARCH_ARM64, Int32(KS_MODE_LITTLE_ENDIAN), &handle)
guard error == KS_ERR_OK else {
    fatalError("ks_open failed: \(error)")
}

defer {
    ks_close(handle)
}
```

## Local Validation

```bash
./Script/test.sh
```

## License

This wrapper package vendors Keystone and follows the upstream Keystone license.
