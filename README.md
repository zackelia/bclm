# BCLM

BCLM is a wrapper to read and write battery charge level max (BCLM) values to the System Management Controller (SMC) on Mac computers. This project was inspired by several battery management solutions, including Apple's own battery health management.

## Installation

BCLM is written in Swift and is trivial to compile and run.

```
$ swift build
$ cp .build/debug/bclm /usr/local/bin
$ bclm
OVERVIEW: Battery Charge Level Max (BCLM) Utility.

USAGE: bclm <subcommand>

OPTIONS:
  -h, --help              Show help information.

SUBCOMMANDS:
  read                    Reads the BCLM value.
  write                   Writes a BCLM value.

  See 'bclm help <subcommand>' for detailed help.
```

When writing values, macOS charges slightly beyond the set value (~3%). In order to display 80% when fully charged, it is recommended to set the BCLM value to 77%.

```
$ sudo bclm write 77
$ bclm read
77
```

Note that in order to write values, the program must be run as root. This is not required for reading values.

## Persistence

The SMC can be reset by a startup shortcut or various other technical reasons. To ensure that the BCLM is always at its intended value, it should be run at startup via `launchd` as root.

```
$ sudo cp com.zackelia.bclm.plist /Library/LaunchDaemons
$ sudo launchctl load /Library/LaunchDaemons/com.zackelia.bclm.plist
```

Note that the provided plist sets the BCLM to 80%. This can be changed in the `ProgramArguments` key.
