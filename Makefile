.PHONY: all

all: update generate test

update:
	nix flake update

generate:
	nix run '.#genCargoNix'

test:
	nix flake check
