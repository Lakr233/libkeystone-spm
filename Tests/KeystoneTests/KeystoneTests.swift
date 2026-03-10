import Keystone
import XCTest

// MARK: - CoreKeystone (Raw C API)

final class CoreKeystoneTests: XCTestCase {
    func testARM64Assembly() {
        var handle: OpaquePointer?
        let error = ks_open(KS_ARCH_ARM64, Int32(KS_MODE_LITTLE_ENDIAN.rawValue), &handle)

        XCTAssertEqual(error, KS_ERR_OK)
        guard error == KS_ERR_OK, let handle else { return }
        defer { ks_close(handle) }

        var encoding: UnsafeMutablePointer<UInt8>?
        var size = 0
        var statementCount = 0
        let result = ks_asm(handle, "mov x0, #0", 0, &encoding, &size, &statementCount)

        XCTAssertEqual(result, 0)
        XCTAssertEqual(size, 4)
        XCTAssertEqual(statementCount, 1)
        guard result == 0, let encoding else { return }

        ks_free(encoding)
    }

    func testX86Assembly() {
        var handle: OpaquePointer?
        let error = ks_open(KS_ARCH_X86, Int32(KS_MODE_64.rawValue), &handle)

        XCTAssertEqual(error, KS_ERR_OK)
        guard error == KS_ERR_OK, let handle else { return }
        defer { ks_close(handle) }

        var encoding: UnsafeMutablePointer<UInt8>?
        var size = 0
        var statementCount = 0
        let result = ks_asm(handle, "nop", 0, &encoding, &size, &statementCount)

        XCTAssertEqual(result, 0)
        XCTAssertEqual(size, 1)
        XCTAssertEqual(statementCount, 1)
        guard result == 0, let encoding else { return }

        XCTAssertEqual(encoding[0], 0x90)
        ks_free(encoding)
    }
}

// MARK: - Keystone (Swift API)

final class KeystoneSwiftTests: XCTestCase {
    func testVersion() {
        let version = KeystoneVersion.current
        XCTAssertGreaterThan(version.major + version.minor, 0)
    }

    func testArchitectureSupported() {
        XCTAssertTrue(Architecture.arm64.isSupported)
        XCTAssertTrue(Architecture.arm.isSupported)
        XCTAssertTrue(Architecture.x86.isSupported)
    }

    func testARM64Assembly() throws {
        let asm = try KeystoneAssembler.arm64()
        let result = try asm.assemble("mov x0, #0")
        XCTAssertEqual(result.data.count, 4)
        XCTAssertEqual(result.statementCount, 1)
    }

    func testARM64CommonInstructions() throws {
        let asm = try KeystoneAssembler.arm64()

        let nop = try asm.assembleBytes("nop")
        XCTAssertEqual(nop.count, 4)

        let ret = try asm.assembleBytes("ret")
        XCTAssertEqual(ret.count, 4)

        let movX0_0 = try asm.assembleBytes("mov x0, #0")
        XCTAssertEqual(movX0_0.count, 4)

        let movX0_1 = try asm.assembleBytes("mov x0, #1")
        XCTAssertEqual(movX0_1.count, 4)

        let movW0_0 = try asm.assembleBytes("mov w0, #0")
        XCTAssertEqual(movW0_0.count, 4)

        let movW0_1 = try asm.assembleBytes("mov w0, #1")
        XCTAssertEqual(movW0_1.count, 4)
    }

    func testARM64MultipleStatements() throws {
        let asm = try KeystoneAssembler.arm64()
        let result = try asm.assemble("mov x0, #0; ret")
        XCTAssertEqual(result.data.count, 8)
        XCTAssertEqual(result.statementCount, 2)
    }

    func testARM64AssemblyAtAddress() throws {
        let asm = try KeystoneAssembler.arm64()
        let result = try asm.assemble("b #0x1000", address: 0x1000)
        XCTAssertEqual(result.data.count, 4)
    }

    func testX86_64Assembly() throws {
        let asm = try KeystoneAssembler.x86_64()
        let nop = try asm.assembleBytes("nop")
        XCTAssertEqual(nop.count, 1)
        XCTAssertEqual(nop[0], 0x90)
    }

    func testX86ATTSyntax() throws {
        let asm = try KeystoneAssembler.x86_64(syntax: .att)
        let result = try asm.assembleBytes("movq %rax, %rbx")
        XCTAssertGreaterThan(result.count, 0)
    }

    func testInvalidAssembly() throws {
        let asm = try KeystoneAssembler.arm64()
        XCTAssertThrowsError(try asm.assembleBytes("invalid_instruction_xyz"))
    }

    func testErrorDescription() {
        let err = KeystoneError(code: KS_ERR_ASM_MNEMONICFAIL)
        XCTAssertFalse(err.description.isEmpty)
    }
}
