import Foundation

let launchctl = "/bin/launchctl"
let plist = "com.zackelia.bclm.plist"
let plist_path = "/Library/LaunchDaemons/\(plist)"
let plist_loop = "com.zackelia.bclm_loop.plist"
let plist_path_loop = "/Library/LaunchDaemons/\(plist_loop)"

struct Preferences: Codable {
    var Label: String
    var RunAtLoad: Bool
    var KeepAlive: Bool
    var ProgramArguments: [String]
}

func persist(_ enable: Bool, _ isLoop: Bool) {
    if isPersistent(isLoop) && enable {
        fputs("Already persisting! (isLoop: " + (isLoop ? "True" : "False") + ")\n", stderr)
        return
    }
    if !isPersistent(isLoop) && !enable {
        fputs("Already not persisting! (isLoop: " + (isLoop ? "True" : "False") + ")\n", stderr)
        return
    }

    let process = Process()
    let pipe = Pipe()

    var load: String
    if (enable) {
        load = "load"
    } else {
        load = "unload"
    }

    process.launchPath = launchctl
    process.arguments = [load, isLoop ? plist_path_loop : plist_path]
    process.standardOutput = pipe
    process.standardError = pipe

    process.launch()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)

    if (output != nil && !output!.isEmpty) {
        print(output!)
    }

    if !enable {
        do {
            try FileManager.default.removeItem(at: URL(fileURLWithPath: isLoop ? plist_path_loop : plist_path))
        } catch {
            print(error)
        }
    }
}

func isPersistent(_ isLoop: Bool) -> Bool {
    let process = Process()
    let pipe = Pipe()

    process.launchPath = launchctl
    process.arguments = ["list"]
    process.standardOutput = pipe
    process.standardError = pipe

    process.launch()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)

    if (output != nil && output!.contains(isLoop ? plist_loop : plist)) {
        return true
    } else {
        return false
    }
}

func updatePlist(_ value: Int, _ isLoop: Bool) {
    let preferences =
            isLoop
            ? Preferences(
                Label: plist_loop,
                RunAtLoad: true,
                KeepAlive: true,
                ProgramArguments: [
                    Bundle.main.executablePath! as String,
                    "loop"
                ]
            )
            : Preferences(
                Label: plist,
                RunAtLoad: true,
                KeepAlive: false,
                ProgramArguments: [
                    Bundle.main.executablePath! as String,
                    "write",
                    String(value)
                ]
            )

    let path = URL(fileURLWithPath: isLoop ? plist_path_loop : plist_path)

    let encoder = PropertyListEncoder()
    encoder.outputFormat = .xml

    do {
        let data = try encoder.encode(preferences)
        try data.write(to: path)
    } catch {
        print(error)
    }
}
