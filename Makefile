bootstrap:
	bundle check || bundle install

test-ios: bootstrap
	set -o pipefail && \
	xcodebuild test \
		-scheme MockDuck \
		-destination platform="iOS Simulator,name=iPhone X" \
		| bundle exec xcpretty

test-tvos: bootstrap
	set -o pipefail && \
	xcodebuild test \
		-scheme MockDuck \
		-destination platform="tvOS Simulator,name=Apple TV" \
		| bundle exec xcpretty

test-macos: bootstrap
	swift test -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.12"

lint-cocoapods: bootstrap
	bundle exec pod lib lint

test: test-ios test-tvos test-macos
