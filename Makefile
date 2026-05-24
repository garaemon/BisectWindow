.PHONY: generate build test

generate:
	mise exec -- xcodegen generate

build:
	xcodebuild build \
		-project BisectWindow.xcodeproj \
		-scheme BisectWindow \
		-destination 'platform=macOS'

test:
	xcodebuild test \
		-project BisectWindow.xcodeproj \
		-scheme BisectWindow \
		-destination 'platform=macOS'
