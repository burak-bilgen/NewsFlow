.PHONY: test lint build clean setup help

# Default destination
DESTINATION ?= platform=iOS Simulator,name=iPhone 15

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

setup: ## Install development dependencies (SwiftLint)
	@which swiftlint >/dev/null || brew install swiftlint
	@echo "✅ Setup complete"

lint: ## Run SwiftLint
	@swiftlint lint --reporter xcode

lint-fix: ## Run SwiftLint and auto-fix violations
	@swiftlint --fix

test: ## Run unit tests
	@xcodebuild test \
		-project NewsFlow.xcodeproj \
		-scheme NewsFlow \
		-destination '$(DESTINATION)' \
		-derivedDataPath DerivedData \
		-quiet

test-with-coverage: ## Run unit tests with code coverage
	@xcodebuild test \
		-project NewsFlow.xcodeproj \
		-scheme NewsFlow \
		-destination '$(DESTINATION)' \
		-derivedDataPath DerivedData \
		-enableCodeCoverage YES \
		-quiet

build: ## Build the project
	@xcodebuild build \
		-project NewsFlow.xcodeproj \
		-scheme NewsFlow \
		-destination '$(DESTINATION)' \
		-quiet

clean: ## Clean build artifacts
	@rm -rf DerivedData
	@xcodebuild clean -project NewsFlow.xcodeproj -scheme NewsFlow -quiet

pre-commit: lint test ## Run lint and tests before committing
	@echo "✅ Pre-commit checks passed"
