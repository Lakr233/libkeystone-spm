# libkeystone-spm

Swift Package Manager support for the vendored
[Keystone](https://github.com/keystone-engine/keystone) assembler engine.

## Features

- Builds Keystone from source inside SwiftPM — no external CMake step
- Swift-friendly API wrapper with typed enums, `Data` output, and error handling
- Raw C API also available via `CoreKeystone` module
- Apple platform coverage: macOS, Mac Catalyst, iOS, iOS Simulator, tvOS,
  tvOS Simulator, watchOS, watchOS Simulator, visionOS, visionOS Simulator
- Architectures: `ARM`, `AArch64`, `X86`, plus Keystone's built-in `EVM`

## Install

```swift
.package(url: "https://github.com/Lakr233/libkeystone-spm.git", from: "0.1.0")
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

### Swift API

```swift
import Keystone

// ARM64
let asm = try KeystoneAssembler.arm64()
let nop = try asm.assembleBytes("nop")            // 4 bytes
let patch = try asm.assembleBytes("mov x0, #0")   // 4 bytes

// Multiple statements
let result = try asm.assemble("mov x0, #0; ret")
print(result.data)            // 8 bytes
print(result.statementCount)  // 2

// Assembly at a specific address (for PC-relative instructions)
let branch = try asm.assembleBytes("b #0x1000", address: 0x1000)

// X86-64
let x86 = try KeystoneAssembler.x86_64()
let nopX86 = try x86.assembleBytes("nop")  // [0x90]

// X86 with AT&T syntax
let att = try KeystoneAssembler.x86_64(syntax: .att)
let mov = try att.assembleBytes("movq %rax, %rbx")

// Custom architecture and mode
let thumb = try KeystoneAssembler(architecture: .arm, mode: .thumb)
```

### Raw C API

The `CoreKeystone` module is re-exported through `Keystone`, so the C API is always accessible:

```swift
import Keystone

var handle: OpaquePointer?
let error = ks_open(KS_ARCH_ARM64, Int32(KS_MODE_LITTLE_ENDIAN.rawValue), &handle)
guard error == KS_ERR_OK, let handle else { fatalError() }
defer { ks_close(handle) }

var encoding: UnsafeMutablePointer<UInt8>?
var size = 0, count = 0
ks_asm(handle, "mov x0, #0", 0, &encoding, &size, &count)
// ...
ks_free(encoding)
```

## Products

| Product | Description |
|---------|-------------|
| `Keystone` | Swift wrapper + re-exported C API |
| `CoreKeystone` | Raw C API only |

## Local Validation

```bash
./Script/test.sh
```

## License

This wrapper package vendors Keystone and follows the upstream Keystone license.
