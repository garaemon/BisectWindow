.PHONY: generate build test run logs

APP_NAME := BisectWindow
LOG_FILE := /tmp/BisectWindow.log

generate:
	mise exec -- xcodegen generate

build:
	xcodebuild build \
		-project BisectWindow.xcodeproj \
		-scheme BisectWindow \
		-destination 'platform=macOS' \
		-allowProvisioningUpdates

test:
	xcodebuild test \
		-project BisectWindow.xcodeproj \
		-scheme BisectWindow \
		-destination 'platform=macOS' \
		CODE_SIGN_IDENTITY=- \
		CODE_SIGN_STYLE=Manual \
		DEVELOPMENT_TEAM= \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGNING_ALLOWED=NO

run: build
	@APP_PATH=$$(xcodebuild -project BisectWindow.xcodeproj -scheme BisectWindow -configuration Debug -showBuildSettings 2>/dev/null | awk '/ BUILT_PRODUCTS_DIR / {print $$3; exit}'); \
	echo "Launching $$APP_PATH/$(APP_NAME).app"; \
	open "$$APP_PATH/$(APP_NAME).app"

logs:
	@touch $(LOG_FILE)
	tail -f $(LOG_FILE)
