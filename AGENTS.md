# Agent Instructions

Complete the requested change, run checks that cover it, and inspect the final
diff. Keep unrelated work intact.

## Development environment

- The project shell is already active. Use the tools on `PATH`.
- Do not run `nix`, `nix-build`, `nix-store`, `nix develop`, or any other Nix
  command unless the user asks for that exact check in the current task.
- Do not create new Nix caches or dependency folders.
  If the environment lacks a tool or build variable, report that problem.

## Checks

- Start with the smallest check that covers the changed behavior. Do not run
  every command listed in the README.
- For TypeScript, use the affected package's `npm` check or the exact relevant
  `node --test` files.
- Always run `git diff --check`. Report any check you skipped and why.
