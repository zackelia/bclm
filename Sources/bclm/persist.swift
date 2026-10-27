import Foundation

let launchctl = "/bin/launchctl"
let plist = "com.zackelia.bclm.plist"
let plist_path = "/Library/LaunchDaemons/\(plist)"

struct Preferences: Codable {
    var Label: String
    var RunAtLoad: Bool
    var ProgramArguments: [String]
}

@discardableResult
func runCommand(_ launchPath: String, _ arguments: [String]) -> (status: Int32, output: String) {
    let process = Process()
    let pipe = Pipe()
    process.launchPath = launchPath
    process.arguments = arguments
    process.standardOutput = pipe
    process.standardError = pipe
    process.launch()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return (process.terminationStatus, output)
}

func persist(_ enable: Bool) {
    // Unload/bootout any existing instance cleanly first
    _ = runCommand(launchctl, ["bootout", "system/\(plist)"])
    _ = runCommand(launchctl, ["unload", plist_path])

    if enable {
        // Modern macOS launchctl bootstrap first
        let bootRes = runCommand(launchctl, ["bootstrap", "system", plist_path])
        if bootRes.status != 0 {
            // Fallback to legacy load
            let loadRes = runCommand(launchctl, ["load", "-w", plist_path])
            if loadRes.status != 0 && !loadRes.output.isEmpty {
                print(loadRes.output)
            }
        }
    } else {
        if FileManager.default.fileExists(atPath: plist_path) {
            do {
                try FileManager.default.removeItem(at: URL(fileURLWithPath: plist_path))
            } catch {
                print(error)
            }
        }
    }
}

func isPersistent() -> Bool {
    return FileManager.default.fileExists(atPath: plist_path)
}

func updatePlist(_ value: Int) {
    let preferences = Preferences(
        Label: plist,
        RunAtLoad: true,
        ProgramArguments: [
            Bundle.main.executablePath! as String,
            "write",
            String(value)
        ]
    )

    let path = URL(fileURLWithPath: plist_path)

    let encoder = PropertyListEncoder()
    encoder.outputFormat = .xml

    do {
        let data = try encoder.encode(preferences)
        try data.write(to: path)
        try FileManager.default.setAttributes([
            .posixPermissions: 0o644,
            .ownerAccountName: "root",
            .groupOwnerAccountName: "wheel"
        ], ofItemAtPath: plist_path)
    } catch {
        print(error)
    }
}
