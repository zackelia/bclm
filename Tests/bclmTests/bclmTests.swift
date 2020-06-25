import XCTest
import class Foundation.Bundle

final class bclmTests: XCTestCase {

    /// Helper method to run bclm
    func bclm(args: String...) -> String! {
        // Some of the APIs that we use below are available in macOS 10.13 and above.
        guard #available(macOS 10.13, *) else {
            XCTFail("macOS version >= 10.13 required to run tests.")
            return ""
        }

        let binary = self.productsDirectory.appendingPathComponent("bclm")
        let process = Process()
        let pipe = Pipe()

        process.executableURL = binary
        process.arguments = args
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
        }
        catch {
            XCTFail("Could not start bclm process.")
        }

        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)

        return output
    }

    /// Helper method to run bclm read
    func readBCLM() -> String!  {
        return bclm(args: "read")
    }

    /// Helper method to run bclm write
    func writeBCLM(value: Int) -> String!  {
        return bclm(args: "write", String(value))
    }

    /// Verify that reading the bclm returns a value
    func testRead() {
        var bclm: Int!

        bclm = Int(readBCLM()!)!
        XCTAssertNotNil(bclm)
    }

    /// Verify that writing a valid bclm value works
    func testWriteValid() {
        var bclm: Int!
        var output: String!

        // Get the current value to not mess up the runner's configuration
        bclm = Int(readBCLM()!)!

        output = writeBCLM(value: bclm)!
        XCTAssertEqual(output, "")
    }

    // Verify that writing an invalid bclm value did not work
    func testWriteInvalid() throws {
        var output: String!

        output = writeBCLM(value: 101)!
        XCTAssertNotEqual(output, "")

        output = writeBCLM(value: 0)!
        XCTAssertNotEqual(output, "")
    }

    /// Returns path to the built products directory.
    var productsDirectory: URL {
      #if os(macOS)
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        fatalError("couldn't find the products directory")
      #else
        return Bundle.main.bundleURL
      #endif
    }

    static var allTests = [
        ("testRead", testRead),
        ("testWriteValid", testWriteValid),
        ("testWriteInvalid", testWriteInvalid),
    ]
}
