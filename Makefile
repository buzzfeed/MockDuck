test-ios:
	set -o pipefail && \
	xcodebuild test \
		-scheme MockDuck \
		-destination platform="iOS Simulator,name=iPhone 8,OS=12.0" \
		| xcpretty

test-tvos:
	set -o pipefail && \
	xcodebuild test \
		-scheme MockDuck \
		-destination platform="tvOS Simulator,name=Apple TV,OS=12.0" \
		| xcpretty

test-macos:
	swift test -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.12"

test: test-ios test-tvos test-macos
