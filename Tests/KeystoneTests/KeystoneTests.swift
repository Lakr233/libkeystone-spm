import XCTest
import Keystone

final class KeystoneTests: XCTestCase {
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
