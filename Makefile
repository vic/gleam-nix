.PHONY: help
help:
	@cat $(MAKEFILE_LIST) | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: update
update: ## Update flake sources.
	nix flake update

.PHONY: generate
generate: ## Generate Cargo.nix from upstream sources.
	nix run '.#genCargoNix'

.PHONY: test
test: ## Test the package is installable.
	nix flake check

.PHONY: fmt
fmt: ## Format all nix files.
	nix run '.#fmt'

.PHONY: fmt-check
fmt-check: ## Check all nix files are formatted.
	nix run '.#fmt' -- --check
