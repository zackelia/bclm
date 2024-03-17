import ArgumentParser
import Foundation
import IOKit.ps
import IOKit.pwr_mgt

#if arch(x86_64)
    let BCLM_KEY = "BCLM"
#else
    let BCLM_KEY = "CHWA"
#endif

struct BCLM: ParsableCommand {
    static let configuration = CommandConfiguration(
            abstract: "Battery Charge Level Max (BCLM) Utility.",
            version: "0.1.0",
            subcommands: [Read.self, Write.self, Loop.self, Persist.self, PersistLoop.self, Unpersist.self, UnpersistLoop.self])

    struct Read: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Reads the BCLM value.")

        func run() {
            do {
                try SMCKit.open()
            } catch {
                print(error)
            }

            let key = SMCKit.getKey(BCLM_KEY, type: DataTypes.UInt8)
            do {
                let status = try SMCKit.readData(key).0
#if arch(x86_64)
                print(status)
#else
                print(status == 1 ? 80 : 100)
#endif
            } catch {
                print(error)
            }
        }
    }

    struct Write: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Writes a BCLM value.")

#if arch(x86_64)
        @Argument(help: "The value to set (50-100)")
        var value: Int
#else
        @Argument(help: "The value to set (80 or 100)")
        var value: Int
#endif

        func validate() throws {
            guard getuid() == 0 else {
                throw ValidationError("Must run as root.")
            }

#if arch(x86_64)
            guard value >= 50 && value <= 100 else {
                throw ValidationError("Value must be between 50 and 100.")
            }
#else
            guard value == 80 || value == 100 else {
                throw ValidationError("Value must be either 80 or 100.")
            }
#endif
        }

        func run() {
            do {
                try SMCKit.open()
            } catch {
                print(error)
            }

            let bclm_key = SMCKit.getKey(BCLM_KEY, type: DataTypes.UInt8)

#if arch(x86_64)
            let bfcl_key = SMCKit.getKey("BFCL", type: DataTypes.UInt8)

            let bclm_bytes: SMCBytes = (
                UInt8(value), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0)
            )

            let bfcl_bytes: SMCBytes = (
                UInt8(value - 5), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0)
            )

            do {
                try SMCKit.writeData(bclm_key, data: bclm_bytes)
            } catch {
                print(error)
            }

            // USB-C Macs do not have the BFCL key since they don't have the
            // charging indicator
            do {
                try SMCKit.writeData(bfcl_key, data: bfcl_bytes)
            } catch SMCKit.SMCError.keyNotFound {
                // Do nothing
            } catch {
                print(error)
            }
#else
            let bclm_bytes: SMCBytes = (
                UInt8(value == 80 ? 1 : 0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0)
            )

            do {
                try SMCKit.writeData(bclm_key, data: bclm_bytes)
            } catch {
                print(error)
            }
#endif
            if (isPersistent(false)) {
                updatePlist(value, false)
            }
        }
    }

    struct Loop: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Loop bclm on battery level 80%.")
        
        func validate() throws {
            guard getuid() == 0 else {
                throw ValidationError("Must run as root.")
            }

#if arch(x86_64)
            throw ValidationError("Only support Apple Silicon.")
#endif
        }
        
        func run() {
            let bclm_key = SMCKit.getKey("CHWA", type: DataTypes.UInt8)
            let aclc_key = SMCKit.getKey("ACLC", type: DataTypes.UInt8)
            let bclm_bytes_unlimit: SMCBytes = (
                UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0)
            )
            let bclm_bytes_limit: SMCBytes = (
                UInt8(1), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0)
            )
            let aclc_bytes_full: SMCBytes = (
                UInt8(3), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0)
            )
            let aclc_bytes_charging: SMCBytes = (
                UInt8(4), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0)
            )
            let aclc_bytes_unknown: SMCBytes = (
                UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0)
            )
            var pmStatus : IOReturn? = nil;
            var assertionID : IOPMAssertionID = IOPMAssertionID(0)
            let reasonForActivity = "bclm_loop - Prevent sleep before charging limit is reached."

            while true {
                let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
                let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
                let chargeState = sources[0]["Power Source State"] as? String
                let isACPower = (chargeState == "AC Power") ? true : false
                var isCharging = sources[0]["Is Charging"] as? Bool
                let currentBattLevelInt = Int((sources[0]["Current Capacity"] as? Int) ?? -1)
                
                do {
                    try SMCKit.open()
                    
                    // Change charging status (If current charging status is known).
                    if (chargeState != nil && currentBattLevelInt >= 0) {
                        if (isACPower)  {
                            if (currentBattLevelInt >= 80) {
                                try SMCKit.writeData(bclm_key, data: bclm_bytes_limit)
                                isCharging = false

                                // The battery is "full", so sleep will no longer be prevented (If currently prevented).
                                if (pmStatus != nil && IOPMAssertionRelease(assertionID) == kIOReturnSuccess) {
                                    pmStatus = nil
                                    assertionID = IOPMAssertionID(0)
                                }
                            } else if (currentBattLevelInt < 78) {
                                try SMCKit.writeData(bclm_key, data: bclm_bytes_unlimit)
                                isCharging = true

                                // The battery is not "full", so sleep will be prevented (If not currently prevented).
                                if (pmStatus == nil) {
                                    pmStatus = IOPMAssertionCreateWithName(kIOPMAssertionTypePreventSystemSleep as CFString, UInt32(kIOPMAssertionLevelOn), reasonForActivity as CFString, &assertionID)
                                    if (pmStatus != kIOReturnSuccess) {
                                        pmStatus = nil
                                        assertionID = IOPMAssertionID(0)
                                        print("Failed to prevent sleep.")
                                    }
                                }
                            }
                        } else {
                            try SMCKit.writeData(bclm_key, data: bclm_bytes_unlimit)

                            // No charger connected, so sleep will no longer be prevented (If currently prevented).
                            if (pmStatus != nil && IOPMAssertionRelease(assertionID) == kIOReturnSuccess) {
                                pmStatus = nil
                                assertionID = IOPMAssertionID(0)
                            }
                        }
                    }
                    
                    // Change MagSafe LED status.
                    if (isCharging == false) {
                        try SMCKit.writeData(aclc_key, data: aclc_bytes_full)
                    } else if (isCharging == true) {
                        try SMCKit.writeData(aclc_key, data: aclc_bytes_charging)
                    } else {
                        try SMCKit.writeData(aclc_key, data: aclc_bytes_unknown)
                    }
                } catch {
                    print(error)
                }

                // Try close SMC as failure to open is very rare.
                SMCKit.close()

                sleep(2)
            }
        }
    }

    struct Persist: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Persists bclm on reboot.")

        func validate() throws {
            guard getuid() == 0 else {
                throw ValidationError("Must run as root.")
            }
        }

        func run() {
            do {
                try SMCKit.open()
            } catch {
                print(error)
            }

            let key = SMCKit.getKey(BCLM_KEY, type: DataTypes.UInt8)
            do {
                let status = try SMCKit.readData(key).0
#if arch(x86_64)
                updatePlist(Int(status), false)
#else
                updatePlist(Int(status) == 1 ? 80 : 100, false)
#endif
            } catch {
                print(error)
            }

            persist(true, false)
        }
    }
    
    struct PersistLoop: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Persists bclm loop service on reboot.")

        func validate() throws {
            guard getuid() == 0 else {
                throw ValidationError("Must run as root.")
            }

#if arch(x86_64)
            throw ValidationError("Only support Apple Silicon.")
#endif
        }

        func run() {
            updatePlist(0, true)
            persist(true, true)
        }
    }

    struct Unpersist: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Unpersists bclm on reboot.")

        func validate() throws {
            guard getuid() == 0 else {
                throw ValidationError("Must run as root.")
            }
        }

        func run() {
            persist(false, false)
        }
    }
    struct UnpersistLoop: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Unpersists bclm on reboot.")

        func validate() throws {
            guard getuid() == 0 else {
                throw ValidationError("Must run as root.")
            }

#if arch(x86_64)
            throw ValidationError("Only support Apple Silicon.")
#endif
        }

        func run() {
            persist(false, true)
        }
    }
}

BCLM.main()
