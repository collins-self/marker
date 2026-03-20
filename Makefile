.PHONY: build release install clean run

SCHEME = Marker
BUILD_DIR = .build
APP_NAME = Marker.app
INSTALL_DIR = /Applications
CLI_LINK = /usr/local/bin/marker

build:
	swift build

release:
	swift build -c release

# Assemble .app bundle from SPM build output
bundle: release
	@mkdir -p $(BUILD_DIR)/$(APP_NAME)/Contents/MacOS
	@cp $(BUILD_DIR)/release/Marker $(BUILD_DIR)/$(APP_NAME)/Contents/MacOS/
	@cp -R $(BUILD_DIR)/release/Marker_Marker.bundle $(BUILD_DIR)/$(APP_NAME)/
	@cp Info.plist $(BUILD_DIR)/$(APP_NAME)/Contents/
	@echo "Built $(BUILD_DIR)/$(APP_NAME)"

install: bundle
	@cp -R $(BUILD_DIR)/$(APP_NAME) $(INSTALL_DIR)/
	@mkdir -p $(shell dirname $(CLI_LINK))
	@cp scripts/marker $(CLI_LINK)
	@chmod +x $(CLI_LINK)
	@echo "Installed to $(INSTALL_DIR)/$(APP_NAME)"
	@echo "CLI available at $(CLI_LINK)"

run: build
	swift run Marker

clean:
	swift package clean
	rm -rf $(BUILD_DIR)/$(APP_NAME)
