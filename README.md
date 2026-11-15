# ai-changes-workflow

A small, plain workflow for building software with AI agents: think first, build small. Each change gets a few short documents, written in order, and agents plan and build from them.

A change is planned first:

```
changes/feat-short-name/
├── proposal.md   the user story, why, and what we would like to have
├── spec.md       requirements and acceptance criteria, in plain language
└── plan.md       what must exist to meet each requirement, and the decisions
```

Then each repository where it is built gets its own folder with the same name, on the change's branch, committed with the code:

```
changes/feat-short-name/
├── qa.md         how the acceptance criteria built here are verified
└── tasks.md      the tasks built here, one at a time
```

A new change starts with only `proposal.md`. Each next document is added when you start on it, so the files show how far it is. In a single repository, all five documents end up in the same folder.

## Contents

- `AGENTS.md`: engineering rules for agents (Codex, Claude Code and other compatible agents). The workflow rules sit in a marked block.
- `CLAUDE.md`: only imports `AGENTS.md` for Claude Code.
- `.agents/skills/changes-workflow/`: one skill, with `planning.md` and `implementing.md`.
- `changes/_templates/`: the document templates: `proposal.md`, `spec.md` and `plan.md` for planning, `qa.md` and `tasks.md` for building.
- `install.sh`: installs the above into another repository. `install.sh` and this README are not copied.

## Installing

Clone this repository anywhere, then run the script, passing the target repository:

```bash
./install.sh /path/to/repo               # install, ask on conflicts
./install.sh --dry-run /path/to/repo     # preview, change nothing
./install.sh --force /path/to/repo       # overwrite conflicts without asking
./install.sh --no-exclude /path/to/repo  # also commit AGENTS.md, CLAUDE.md and the skill
```

Run it again at any time to update a repository.

### Planning documents in a separate repository

Keep `proposal.md`, `spec.md` and `plan.md` in their own repository (for example `my-changes-store`), and `qa.md` and `tasks.md` with the code:

```bash
./install.sh --store /path/to/my-changes-store                         # planning templates
./install.sh --changes ../my-changes-store/changes /path/to/code-repo  # qa.md and tasks.md templates
```

With `--store`, the store gets only the planning templates. With `--changes`, the code repository gets only the `qa.md` and `tasks.md` templates, the rules and the skill point to the store's folder, and Claude Code gets access to it through `.claude/settings.local.json` (local, never committed). Agents plan and build from the code repository, where they can read the code: they write the planning documents into the store, and `qa.md` and `tasks.md` into `changes/<name>/` on the change's branch. A change built in several repositories gets a `qa.md` and `tasks.md` in each, for the part built there. The change name connects everything: the store folder, the branches and the folders in each repository all have the same name, so `qa.md` and `tasks.md` name the planning folder as plain text, such as `my-changes-store/changes/feat-short-name`, instead of linking to it.

The rules and the skill write `changes/` for the planning documents and `./changes/` for the repository's own folder; `--changes` only rewrites the first.

## What the script does

- **`AGENTS.md`:** creates it with the default rules if missing. In an existing `AGENTS.md`, it only adds or replaces the block between `<!-- changes-workflow:start -->` and `<!-- changes-workflow:end -->`, and keeps the rest. An `AGENTS.md` from an earlier version without markers is replaced as a whole, after asking.
- **`CLAUDE.md`:** creates it if missing; if one exists, it prepends `@AGENTS.md` and keeps the existing content.
- **The skill:** copies `.agents/skills/changes-workflow/` and links it from `.claude/skills/changes-workflow`. Old `plan-change` and `implement-change` skills are reported, not removed.
- **Templates:** copies `changes/_templates/`: all five by default, only `qa.md` and `tasks.md` with `--changes`, only `proposal.md`, `spec.md` and `plan.md` with `--store`. Commit them with the repository.
- **Conflicts:** asks for each existing file that differs: `[y]es / [n]o / [d]iff / [a]ll / [q]uit` (default: no). Without a terminal (e.g. CI), conflicts are skipped. Replaced originals go to `.changes-workflow-backup/<timestamp>/`.
- **Git:** privately ignores the agent files in `.git/info/exclude`, which is never committed; `.gitignore` is not touched. Files git already tracks, such as a committed `AGENTS.md`, are not excluded. The templates are never excluded.

## Starting a change

A change can be a new feature, a bug fix, a refactoring or other work. Create `changes/feat-short-name/` (or `fix-`, `refactor-`, and so on) and copy the proposal template into it, or ask your agent to use the `changes-workflow` skill. Once the plan is approved, the agent creates the branch `feat-short-name` in each repository where it is built, with `qa.md` and `tasks.md`. Keep `changes/_templates/` unchanged.

## Notes

- `.claude/skills/` contains a symbolic link; preserve symlinks if you copy files manually.
- Skills follow the Agent Skills format (`SKILL.md` with `name` and `description`). Check skill discovery in your versions of Claude Code and Codex.
