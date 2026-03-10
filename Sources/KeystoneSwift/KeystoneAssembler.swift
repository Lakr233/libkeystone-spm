@_exported import CoreKeystone
import Foundation

// MARK: - Error

public struct KeystoneError: Error, CustomStringConvertible, Sendable {
    public let code: ks_err

    public init(code: ks_err) {
        self.code = code
    }

    public var description: String {
        String(cString: ks_strerror(code))
    }
}

// MARK: - Architecture

public enum Architecture: Sendable {
    case arm
    case arm64
    case mips
    case x86
    case ppc
    case sparc
    case systemZ
    case hexagon
    case evm
    case riscV

    var ksArch: ks_arch {
        switch self {
        case .arm: KS_ARCH_ARM
        case .arm64: KS_ARCH_ARM64
        case .mips: KS_ARCH_MIPS
        case .x86: KS_ARCH_X86
        case .ppc: KS_ARCH_PPC
        case .sparc: KS_ARCH_SPARC
        case .systemZ: KS_ARCH_SYSTEMZ
        case .hexagon: KS_ARCH_HEXAGON
        case .evm: KS_ARCH_EVM
        case .riscV: KS_ARCH_RISCV
        }
    }

    public var isSupported: Bool {
        ks_arch_supported(ksArch)
    }
}

// MARK: - Mode

public struct Mode: OptionSet, Sendable {
    public let rawValue: Int32
    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    public static let littleEndian = Mode([])
    public static let bigEndian = Mode(rawValue: 1 << 30)

    // ARM / ARM64
    public static let arm = Mode(rawValue: 1 << 0)
    public static let thumb = Mode(rawValue: 1 << 4)
    public static let v8 = Mode(rawValue: 1 << 6)

    // MIPS
    public static let micro = Mode(rawValue: 1 << 4)
    public static let mips3 = Mode(rawValue: 1 << 5)
    public static let mips32r6 = Mode(rawValue: 1 << 6)
    public static let mips32 = Mode(rawValue: 1 << 2)
    public static let mips64 = Mode(rawValue: 1 << 3)

    // X86
    public static let x86_16 = Mode(rawValue: 1 << 1)
    public static let x86_32 = Mode(rawValue: 1 << 2)
    public static let x86_64 = Mode(rawValue: 1 << 3)

    // RISC-V
    public static let riscV32 = Mode(rawValue: 1 << 2)
    public static let riscV64 = Mode(rawValue: 1 << 3)

    // SPARC
    public static let sparc32 = Mode(rawValue: 1 << 2)
    public static let sparc64 = Mode(rawValue: 1 << 3)
    public static let v9 = Mode(rawValue: 1 << 4)
}

// MARK: - X86 Syntax

public enum X86Syntax: Sendable {
    case intel
    case att
    case nasm
    case gas
    case radix16

    var ksValue: Int {
        switch self {
        case .intel: 1 << 0
        case .att: 1 << 1
        case .nasm: 1 << 2
        case .gas: 1 << 4
        case .radix16: 1 << 5
        }
    }
}

// MARK: - Assembly Result

public struct AssemblyResult: Sendable {
    public let data: Data
    public let statementCount: Int
}

// MARK: - Assembler

public final class KeystoneAssembler: @unchecked Sendable {
    private let handle: OpaquePointer

    public init(architecture: Architecture, mode: Mode = .littleEndian) throws {
        var h: OpaquePointer?
        let err = ks_open(architecture.ksArch, mode.rawValue, &h)
        guard err == KS_ERR_OK, let h else { throw KeystoneError(code: err) }
        handle = h
    }

    deinit { ks_close(handle) }

    // MARK: Options

    public func setSyntax(_ syntax: X86Syntax) throws {
        let err = ks_option(handle, KS_OPT_SYNTAX, syntax.ksValue)
        guard err == KS_ERR_OK else { throw KeystoneError(code: err) }
    }

    // MARK: Assembly

    public func assemble(_ code: String, address: UInt64 = 0) throws -> AssemblyResult {
        var encoding: UnsafeMutablePointer<UInt8>?
        var size = 0
        var statementCount = 0

        let result = ks_asm(handle, code, address, &encoding, &size, &statementCount)
        guard result == 0, let encoding else {
            throw KeystoneError(code: ks_errno(handle))
        }
        defer { ks_free(encoding) }

        let data = Data(bytes: encoding, count: size)
        return AssemblyResult(data: data, statementCount: statementCount)
    }

    public func assembleBytes(_ code: String, address: UInt64 = 0) throws -> Data {
        try assemble(code, address: address).data
    }
}

// MARK: - Convenience Initializers

public extension KeystoneAssembler {
    static func arm64() throws -> KeystoneAssembler {
        try KeystoneAssembler(architecture: .arm64)
    }

    static func arm(thumb: Bool = false) throws -> KeystoneAssembler {
        try KeystoneAssembler(architecture: .arm, mode: thumb ? .thumb : .arm)
    }

    static func x86_64(syntax: X86Syntax = .intel) throws -> KeystoneAssembler {
        let asm = try KeystoneAssembler(architecture: .x86, mode: .x86_64)
        try asm.setSyntax(syntax)
        return asm
    }

    static func x86_32(syntax: X86Syntax = .intel) throws -> KeystoneAssembler {
        let asm = try KeystoneAssembler(architecture: .x86, mode: .x86_32)
        try asm.setSyntax(syntax)
        return asm
    }
}

// MARK: - Version

public enum KeystoneVersion {
    public static var current: (major: UInt32, minor: UInt32) {
        var major: UInt32 = 0
        var minor: UInt32 = 0
        _ = ks_version(&major, &minor)
        return (major, minor)
    }
}
