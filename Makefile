.PHONY: generate build test run logs

APP_NAME := BisectWindow

generate:
	mise exec -- xcodegen generate

build:
	xcodebuild build \
		-project BisectWindow.xcodeproj \
		-scheme BisectWindow \
		-destination 'platform=macOS' \
		-allowProvisioningUpdates

# Tests build unsigned so fresh checkouts and CI need no Apple ID session.
# project.yml selects Automatic signing, so the style and team are cleared
# too; otherwise xcodebuild still tries to resolve a provisioning profile.
test:
	xcodebuild test \
		-project BisectWindow.xcodeproj \
		-scheme BisectWindow \
		-destination 'platform=macOS' \
		CODE_SIGN_STYLE=Manual \
		DEVELOPMENT_TEAM= \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGNING_ALLOWED=NO

run: build
	@APP_PATH=$$(xcodebuild -project BisectWindow.xcodeproj -scheme BisectWindow -configuration Debug -showBuildSettings 2>/dev/null | awk '/ BUILT_PRODUCTS_DIR / {print $$3; exit}'); \
	echo "Launching $$APP_PATH/$(APP_NAME).app"; \
	open "$$APP_PATH/$(APP_NAME).app"

logs:
	log stream --level debug --style compact \
		--predicate 'subsystem == "com.garaemon.BisectWindow"'
