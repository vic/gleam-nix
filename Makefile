.PHONY: all

all: fmt-check update generate test

update:
	nix flake update

generate:
	nix run '.#genCargoNix'

test:
	nix flake check

fmt:
	nix run '.#fmt'

fmt-check:
	nix run '.#fmt' -- --check
