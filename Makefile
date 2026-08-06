TOOL_NAME = XcodeGen
export EXECUTABLE_NAME = xcodegen
VERSION = 2.46.0

PREFIX = /usr/local
INSTALL_PATH = $(PREFIX)/bin/$(EXECUTABLE_NAME)
SHARE_PATH = $(PREFIX)/share/$(EXECUTABLE_NAME)
CURRENT_PATH = $(PWD)
REPO = https://github.com/yonaskolb/$(TOOL_NAME)
SWIFT_BUILD_FLAGS = --disable-sandbox -c release --arch arm64 --arch x86_64
BUILD_PATH = $(shell swift build $(SWIFT_BUILD_FLAGS) --show-bin-path)
EXECUTABLE_PATH = $(BUILD_PATH)/$(EXECUTABLE_NAME)

.PHONY: install build build-linux uninstall format_code release

install: build
	mkdir -p $(PREFIX)/bin
	cp -f $(EXECUTABLE_PATH) $(INSTALL_PATH)
	mkdir -p $(SHARE_PATH)
	cp -R $(CURRENT_PATH)/SettingPresets $(SHARE_PATH)/SettingPresets

build:
	swift build $(SWIFT_BUILD_FLAGS)

# Linux CI build: single-arch, static Swift stdlib, hardened
# (lld for proper R E / RW segments, BIND_NOW, noexecstack).
# --product scopes the build so --static-swift-stdlib doesn't hit test targets.
SWIFT_BUILD_FLAGS_LINUX = --product xcodegen -c release --static-swift-stdlib -Xswiftc -use-ld=lld -Xlinker -z -Xlinker now -Xlinker -z -Xlinker noexecstack

build-linux:
	swift build $(SWIFT_BUILD_FLAGS_LINUX)

uninstall:
	rm -f $(INSTALL_PATH)
	rm -rf $(SHARE_PATH)

format_code:
	swiftformat .

release:
	sed -i '' 's|\(let version = Version("\)\(.*\)\(")\)|\1$(VERSION)\3|' Sources/XcodeGen/main.swift
	sed -i '' 's|\(.package(url: "https://github.com/yonaskolb/XcodeGen.git", from: "\)\(.*\)\(")\)|\1$(VERSION)\3|' README.md

	git add .
	git commit -m "Update to $(VERSION)"
	#git tag $(VERSION)

publish: archive
	echo "published $(VERSION)"

archive: build
	./scripts/archive.sh "$(EXECUTABLE_PATH)"
	swift package plugin --allow-writing-to-package-directory generate-artifact-bundle \
		--package-version $(VERSION) \
		--executable-name $(EXECUTABLE_NAME) \
		--build-config release \
		--include-resource-path LICENSE
