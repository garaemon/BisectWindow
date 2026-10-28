.PHONY: generate build test run logs

APP_NAME := BisectWindow

# The Xcode project is generated and lists source files explicitly, so a
# stale project misses files added since it was generated. --use-cache skips
# generation unless the spec or the file list changed, or the project is
# missing, so every build can depend on this target.
generate:
	mise exec -- xcodegen generate --use-cache

build: generate
	xcodebuild build \
		-project BisectWindow.xcodeproj \
		-scheme BisectWindow \
		-destination 'platform=macOS' \
		-allowProvisioningUpdates

# Tests build unsigned so fresh checkouts and CI need no Apple ID session.
# project.yml selects Automatic signing, so the style and team are cleared
# too; otherwise xcodebuild still tries to resolve a provisioning profile.
test: generate
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
