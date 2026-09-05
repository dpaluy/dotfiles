# Dotfiles for Mac and Linux

Shared configuration for macOS and Linux. Private values belong in `~/.local/dotfiles/` and must not be committed.

## Scope

"Add X" means update the declarative configuration or install list so `install.sh` can reproduce it. Run installation only when requested.

## Configuration contracts

- Preserve machine-owned wrappers in `~/.zshrc`, `~/.zshenv`, `~/.zprofile`, and `~/.config/git/config`. They source or include shared files.
- Preserve local SSH hosts through an `Include`, and merge OpenCode defaults into its local JSON file.
- Codex TOML profiles and Pi `settings.json` are copied. Do not replace them with symlinks or overwrite runtime state as part of a repository edit.
- Agent instruction files and individual skill directories are symlinked by their installers. Editing these sources can affect linked installations.
- Use mise for runtime versions and the helpers in `zsh/path` for PATH changes. Do not hardcode version-specific paths.
- Keep OS-specific behavior in the matching macOS or Linux module.

## Task-specific references

- For installer changes, use [install/AGENTS.md](install/AGENTS.md).
- For configuration destinations, wrapper behavior, or shell loading order, use [docs/configuration-map.md](docs/configuration-map.md).
- Shared agent defaults live in `codex/AGENTS.md`, `pi/AGENTS.md`, `opencode/AGENTS.md`, and `claude/CLAUDE.md`. Preserve tool-specific differences.
- Repository-owned skills live in `agents/skills/` and `codex/skills/`. Keep skill descriptions narrow and read supporting references only when relevant.

## Validation

Use syntax checks and the relevant tests in `test/` for shell or installer changes. Documentation-only changes need link and structure checks; do not run `install.sh` or `brew bundle` as validation.
