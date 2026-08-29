.PHONY: check-flake update-pi-nono

check-flake:
	nix flake check

update-pi-nono:
	nix flake update piNono
	$(MAKE) check-flake
