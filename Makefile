.PHONY: all

all: generate test

update:
	nix flake update

generate:
	pushd "$${GLEAM_SRC:-../gleam}" && nix shell github:cargo2nix/cargo2nix/master -c cargo2nix -f && popd && mv "$${GLEAM_SRC:-../gleam}/Cargo.nix" .

test:
	nix flake check
