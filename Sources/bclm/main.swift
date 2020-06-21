import ArgumentParser
import Foundation

struct BCLM: ParsableCommand {
    static let configuration = CommandConfiguration(
            abstract: "Battery Charge Level Max (BCLM) Utility.",
            subcommands: [Read.self, Write.self])

    struct Read: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Reads the BCLM value.")

        func run() {
            do {
                try SMCKit.open()
            } catch {
                print(error)
            }

            let key = SMCKit.getKey("BCLM", type: DataTypes.UInt8)
            do {
                let status = try SMCKit.readData(key).0
                print(status)
            } catch {
                print(error)
            }
        }
    }

    struct Write: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Writes a BCLM value.")

        @Argument(help: "The value to set (50-100)")
        var value: Int

        func validate() throws {
            guard getuid() == 0 else {
                throw ValidationError("Must run as root.")
            }

            guard value >= 50 && value <= 100 else {
                throw ValidationError("Value must be between 50 and 100.")
            }
        }

        func run() {
            do {
                try SMCKit.open()
            } catch {
                print(error)
            }

            let key = SMCKit.getKey("BCLM", type: DataTypes.UInt8)

            let bytes: SMCBytes = (
                UInt8(value), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0)
            )

            do {
                try SMCKit.writeData(key, data: bytes)
            } catch {
                print(error)
            }
        }
    }
}

BCLM.main()
