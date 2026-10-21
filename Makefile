SCHEME := ClipboardManager
PROJECT := ClipboardManager.xcodeproj
CONFIG := Debug
DERIVED := build
APP_NAME := ClipboardManager.app
RELEASE_DIR := dist
VERSION ?= $(shell git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo 0.0.0)
BUILD ?= 1

.PHONY: setup generate build run test clean lint format release archive zip sha icons

setup: generate
	@command -v xcodegen >/dev/null 2>&1 || { echo "Install xcodegen: brew install xcodegen"; exit 1; }

generate:
	xcodegen generate

build:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration $(CONFIG) -derivedDataPath $(DERIVED) build

run: build
	open $(DERIVED)/Build/Products/$(CONFIG)/$(APP_NAME)

test:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -destination 'platform=macOS' -derivedDataPath $(DERIVED) test

clean:
	rm -rf $(DERIVED) $(RELEASE_DIR)
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) clean || true

icons:
	./scripts/export-icons.sh

lint:
	@command -v swiftlint >/dev/null 2>&1 || { echo "Install swiftlint: brew install swiftlint"; exit 1; }
	@command -v swiftformat >/dev/null 2>&1 || { echo "Install swiftformat: brew install swiftformat"; exit 1; }
	swiftlint lint --strict
	swiftformat --lint .

format:
	@command -v swiftformat >/dev/null 2>&1 || { echo "Install swiftformat: brew install swiftformat"; exit 1; }
	swiftformat .

release: clean generate archive zip sha
	@echo ""
	@echo "Release artifacts ready in $(RELEASE_DIR)/"
	@ls -lh $(RELEASE_DIR)/

archive:
	@mkdir -p $(RELEASE_DIR)
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Release -derivedDataPath $(DERIVED) \
		MARKETING_VERSION=$(VERSION) CURRENT_PROJECT_VERSION=$(BUILD) build
	cp -R $(DERIVED)/Build/Products/Release/$(APP_NAME) $(RELEASE_DIR)/

zip:
	cd $(RELEASE_DIR) && ditto -c -k --sequesterRsrc --keepParent $(APP_NAME) CopyIT-$(VERSION).zip
	@echo "Zipped → $(RELEASE_DIR)/CopyIT-$(VERSION).zip"

sha:
	@shasum -a 256 $(RELEASE_DIR)/CopyIT-$(VERSION).zip | awk '{print $$1}' > $(RELEASE_DIR)/CopyIT-$(VERSION).zip.sha256
	@echo "SHA256: $$(cat $(RELEASE_DIR)/CopyIT-$(VERSION).zip.sha256)"
