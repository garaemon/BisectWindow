.PHONY: generate build test

generate:
	mise exec -- xcodegen generate

build:
	xcodebuild build \
		-project BisectWindow.xcodeproj \
		-scheme BisectWindow \
		-destination 'platform=macOS' \
		CODE_SIGNING_ALLOWED=NO

test:
	xcodebuild test \
		-project BisectWindow.xcodeproj \
		-scheme BisectWindow \
		-destination 'platform=macOS' \
		CODE_SIGNING_ALLOWED=NO
