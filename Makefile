prefix ?= /usr/local
bindir = $(prefix)/bin

build:
	swift build -c release --disable-sandbox

install: build
	install ".build/release/bclm" "$(bindir)"

uninstall:
	rm -rf "$(bindir)/bclm"

test:
	swift test

clean:
	rm -rf .build

.PHONY: build install uninstall clean

